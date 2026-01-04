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
    // static let baseURL = "https://allinconnect-back-1.onrender.com/api/v1" // Production
    static let baseURL = "http://127.0.0.1:8080/api/v1" // Local
    
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
    case unauthorized(reason: String?)
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
        case .unauthorized(let reason):
            if let reason = reason {
                switch reason {
                case "Token expired":
                    return "Votre session a expiré. Veuillez vous reconnecter."
                case "User not found":
                    return "Votre compte n'existe plus. Veuillez vous reconnecter."
                case "Invalid token":
                    return "Token invalide. Veuillez vous reconnecter."
                default:
                    return "Non autorisé: \(reason). Veuillez vous reconnecter."
                }
            }
            return "Non autorisé. Veuillez vous reconnecter."
        case .notFound:
            return "Ressource non trouvée"
        }
    }
    
    var shouldForceLogout: Bool {
        switch self {
        case .unauthorized(let reason):
            return reason == "Token expired" || reason == "User not found" || reason == "Invalid token"
        default:
            return false
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
                // Erreur 401 : Token expiré ou invalide
                // Note: Sur les endpoints publics (comme /api/v1/subscriptions/plans), le backend ne devrait plus retourner 401 même avec un token expiré
                // Si on reçoit une 401, c'est que le token est expiré/invalide ET que l'endpoint est privé
                var errorReason: String? = nil
                if !data.isEmpty {
                    // Essayer de décoder le message d'erreur depuis le body
                    if let errorDict = try? JSONDecoder().decode([String: String].self, from: data) {
                        errorReason = errorDict["message"] ?? errorDict["error"] ?? errorDict["reason"]
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        // Si ce n'est pas du JSON, essayer de lire comme texte brut
                        errorReason = errorString.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                print("[APIService] Erreur 401 - Raison: \(errorReason ?? "non spécifiée")")
                print("[APIService] ⚠️ Token expiré ou invalide - L'utilisateur doit se reconnecter")
                throw APIError.unauthorized(reason: errorReason)
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
    
    // MARK: - Multipart Form Data Request
    func multipartRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .post,
        jsonData: [String: Any],
        imageData: Data? = nil,
        imageFieldName: String = "image",
        jsonFieldName: String = "offer",
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Créer le boundary pour multipart/form-data
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        // Ajouter l'Authorization header si disponible
        if let token = AuthTokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Ajouter les headers personnalisés
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Construire le body multipart
        var body = Data()
        
        // 1. Ajouter les données JSON sous forme de Blob (comme en JavaScript)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(jsonFieldName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        
        // Convertir les données JSON en Data
        do {
            let jsonDataEncoded = try JSONSerialization.data(withJSONObject: jsonData, options: [])
            body.append(jsonDataEncoded)
        } catch {
            throw APIError.networkError(error)
        }
        
        body.append("\r\n".data(using: .utf8)!)
        
        // 2. Ajouter l'image si fournie
        if let imageData = imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(imageFieldName)\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Fermer le multipart
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Log pour debug
        print("[APIService] Multipart request:")
        print("   Endpoint: \(method.rawValue) \(url)")
        print("   JSON field: \(jsonFieldName)")
        if imageData != nil {
            print("   Image field: \(imageFieldName) (size: \(imageData!.count) bytes)")
        } else {
            print("   Image field: none")
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
                // Lire le message d'erreur précis du body de la réponse 401
                var errorReason: String? = nil
                if !data.isEmpty {
                    // Essayer de décoder le message d'erreur depuis le body
                    if let errorDict = try? JSONDecoder().decode([String: String].self, from: data) {
                        errorReason = errorDict["message"] ?? errorDict["error"] ?? errorDict["reason"]
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        // Si ce n'est pas du JSON, essayer de lire comme texte brut
                        errorReason = errorString.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                print("[APIService] Erreur 401 (multipart) - Raison: \(errorReason ?? "non spécifiée")")
                throw APIError.unauthorized(reason: errorReason)
            case 404:
                throw APIError.notFound
            default:
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            // Gérer les réponses vides
            if httpResponse.statusCode == 204 || data.isEmpty {
                if let emptyJSON = "{}".data(using: .utf8) {
                    do {
                        let decoded = try decoder.decode(T.self, from: emptyJSON)
                        return decoded
                    } catch {
                        throw APIError.decodingError(error)
                    }
                }
                throw APIError.invalidResponse
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

