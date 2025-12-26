//
//  APIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - API Configuration
struct APIConfig {
    static let baseURL = "http://127.0.0.1:8000/api/v1"
    
    static var defaultHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if let token = AuthTokenManager.shared.getToken() {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}

// MARK: - Auth Token Manager
class AuthTokenManager {
    static let shared = AuthTokenManager()
    private let tokenKey = "auth_token"
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    func hasToken() -> Bool {
        return getToken() != nil
    }
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .httpError(let statusCode, let message):
            return message ?? "Erreur HTTP \(statusCode)"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .unauthorized:
            return "Non autorisé. Veuillez vous reconnecter."
        case .notFound:
            return "Ressource non trouvée"
        }
    }
}

// MARK: - API Service Protocol
protocol APIServiceProtocol {
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]?,
        headers: [String: String]?
    ) async throws -> T
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Service Implementation
@MainActor
class APIService: APIServiceProtocol, ObservableObject {
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        
        self.decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Ajouter les headers par défaut (incluant Authorization: Bearer TOKEN)
        APIConfig.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Ajouter les headers personnalisés (peuvent override les headers par défaut)
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Log pour debug : vérifier que le token est bien envoyé
        if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
            print("[APIService] Authorization header: \(authHeader.prefix(20))...")
        } else {
            print("[APIService] Aucun token d'authentification trouvé")
        }
        
        if method != .get, let parameters = parameters {
            do {
                let cleanedParameters = parameters.compactMapValues { value -> Any? in
                    if value is NSNull {
                        return nil
                    }
                    return value
                }
                
                request.httpBody = try JSONSerialization.data(withJSONObject: cleanedParameters, options: [])
            } catch {
                throw APIError.networkError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            // Gérer les réponses vides (204 No Content ou 200 OK avec corps vide)
            if httpResponse.statusCode == 204 || data.isEmpty {
                // Pour les réponses vides, essayer de décoder un JSON vide {}
                if let emptyJSON = "{}".data(using: .utf8) {
                    do {
                        let decoded = try decoder.decode(T.self, from: emptyJSON)
                        return decoded
                    } catch {
                        // Si le décodage échoue même avec {}, c'est peut-être normal
                        // On laisse l'erreur remonter pour que l'appelant puisse la gérer
                        throw APIError.decodingError(error)
                    }
                }
                // Si on ne peut pas créer de JSON vide, retourner une erreur
                throw APIError.invalidResponse
            }
            
            // Si les données ne sont pas vides, décoder normalement
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

