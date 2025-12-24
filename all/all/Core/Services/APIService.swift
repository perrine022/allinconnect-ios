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
    // Pour le simulateur iOS, utiliser 'localhost' au lieu de '127.0.0.1'
    // Pour un appareil physique, utiliser l'adresse IP de votre Mac (ex: http://192.168.1.XXX:8000)
    static let baseURL = "http://localhost:8000/api/v1"
    
    static var defaultHeaders: [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Ajouter le token d'authentification si disponible
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
        
        // Configuration du decoder avec format de date
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
        // Construire l'URL
        guard var urlComponents = URLComponents(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        // Ajouter les paramètres de requête pour GET
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        // Créer la requête
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Ajouter les headers par défaut
        APIConfig.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Ajouter les headers personnalisés
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Ajouter le body pour POST/PUT/PATCH
        if method != .get, let parameters = parameters {
            do {
                // Filtrer les valeurs NSNull (représentation JSON de nil)
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
        
        // Effectuer la requête
        do {
            let (data, response) = try await session.data(for: request)
            
            // Vérifier la réponse HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Gérer les erreurs HTTP
            switch httpResponse.statusCode {
            case 200...299:
                // Succès
                break
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                // Essayer de décoder le message d'erreur
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            // Décoder la réponse
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

