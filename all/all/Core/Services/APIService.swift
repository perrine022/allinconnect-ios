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
    // static let baseURL = "http://127.0.0.1:8080/api/v1" // Local
    static let baseURL = "https://allinconnect-back-1.onrender.com/api/v1" // Production (Render)
    
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
        
        // Pour les requêtes GET, éviter le cache HTTP pour toujours récupérer les données fraîches
        if method == .get {
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }
        
        // Ajouter les headers par défaut (incluant Authorization: Bearer TOKEN)
        APIConfig.defaultHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Ajouter les headers personnalisés (peuvent override les headers par défaut)
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Log pour debug : vérifier que le token est bien envoyé (masqué pour la sécurité)
        if request.value(forHTTPHeaderField: "Authorization") != nil {
            // Masquer complètement le token, ne montrer que "Bearer ..."
            print("[APIService] Authorization header: Bearer ...")
        } else {
            print("[APIService] Aucun token d'authentification trouvé")
        }
        
        if method != .get, let parameters = parameters {
            do {
                // Nettoyer les valeurs nil (NSNull)
                var cleanedParameters = parameters.compactMapValues { value -> Any? in
                    if value is NSNull {
                        return nil
                    }
                    // IMPORTANT: S'assurer que les booléens restent des booléens et ne deviennent pas NSNumber
                    // JSONSerialization peut convertir Bool en NSNumber, ce qui cause des problèmes
                    if let boolValue = value as? Bool {
                        return boolValue
                    }
                    // Si c'est un NSNumber qui représente un booléen (0 ou 1), le convertir en Bool
                    if let numberValue = value as? NSNumber, numberValue == 0 || numberValue == 1 {
                        return numberValue.boolValue
                    }
                    return value
                }
                
                // Log pour vérifier isClub10 avant sérialisation (le backend attend "isClub10" dans les requêtes PUT)
                var isClub10Value: Bool? = nil
                if let isClub10 = cleanedParameters["isClub10"] {
                    isClub10Value = isClub10 as? Bool
                    print("📡 [APIService] request() - isClub10 dans cleanedParameters avant sérialisation: \(isClub10) (type: \(type(of: isClub10)))")
                    
                    // Vérifier et corriger si c'est un NSNumber au lieu d'un Bool
                    if let numberValue = isClub10 as? NSNumber {
                        print("📡 [APIService] ⚠️ isClub10 est un NSNumber (\(numberValue)) - conversion en Bool")
                        cleanedParameters["isClub10"] = numberValue.boolValue
                        isClub10Value = numberValue.boolValue
                    } else if isClub10 is Bool {
                        print("📡 [APIService] ✅ isClub10 est bien un Bool")
                    }
                } else {
                    print("📡 [APIService] request() - ⚠️ isClub10 n'est PAS dans cleanedParameters avant sérialisation!")
                }
                
                var httpBodyData = try JSONSerialization.data(withJSONObject: cleanedParameters, options: [])
                
                // Log pour vérifier le JSON final dans httpBody
                if var httpBodyString = String(data: httpBodyData, encoding: .utf8) {
                    print("📡 [APIService] request() - httpBody JSON AVANT correction:")
                    print(httpBodyString)
                    
                    // CORRECTION: JSONSerialization peut sérialiser les booléens comme 0/1 au lieu de true/false
                    // Remplacer "isClub10":1 par "isClub10":true et "isClub10":0 par "isClub10":false
                    if let isClub10Value = isClub10Value {
                        if isClub10Value {
                            // Remplacer "isClub10":1 par "isClub10":true
                            httpBodyString = httpBodyString.replacingOccurrences(of: "\"isClub10\":1", with: "\"isClub10\":true")
                            httpBodyString = httpBodyString.replacingOccurrences(of: "\"isClub10\" : 1", with: "\"isClub10\":true")
                        } else {
                            // Remplacer "isClub10":0 par "isClub10":false
                            httpBodyString = httpBodyString.replacingOccurrences(of: "\"isClub10\":0", with: "\"isClub10\":false")
                            httpBodyString = httpBodyString.replacingOccurrences(of: "\"isClub10\" : 0", with: "\"isClub10\":false")
                        }
                        
                        // Re-convertir en Data
                        if let correctedData = httpBodyString.data(using: .utf8) {
                            httpBodyData = correctedData
                            print("📡 [APIService] ✅ JSON CORRIGÉ après remplacement:")
                            print(httpBodyString)
                        }
                    }
                    
                    // Vérifier spécifiquement isClub10 dans le JSON string final
                    if httpBodyString.contains("\"isClub10\":true") {
                        print("📡 [APIService] ✅ isClub10 est présent avec la valeur 'true' dans le JSON string")
                    } else if httpBodyString.contains("\"isClub10\":false") {
                        print("📡 [APIService] ✅ isClub10 est présent avec la valeur 'false' dans le JSON string")
                    } else if httpBodyString.contains("\"isClub10\":1") {
                        print("📡 [APIService] ⚠️ PROBLÈME: isClub10 est toujours sérialisé comme '1' au lieu de 'true'!")
                    } else if httpBodyString.contains("\"isClub10\":0") {
                        print("📡 [APIService] ⚠️ PROBLÈME: isClub10 est toujours sérialisé comme '0' au lieu de 'false'!")
                    } else {
                        print("📡 [APIService] ⚠️ isClub10 n'est PAS dans le JSON string!")
                    }
                }
                
                request.httpBody = httpBodyData
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
                // Log de la réponse brute pour debug (spécifiquement pour /users/me et /users/professionals/search)
                if endpoint.contains("/users/me") || endpoint.contains("/users/professionals/search") {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        if endpoint.contains("/users/me") {
                            print("═══════════════════════════════════════════════════════════")
                            print("📥 [APIService] Réponse brute du backend pour /users/me:")
                            print(jsonString)
                            print("═══════════════════════════════════════════════════════════")
                        } else if endpoint.contains("/users/professionals/search") {
                            print("═══════════════════════════════════════════════════════════")
                            print("📥 [APIService] Réponse brute du backend pour /users/professionals/search:")
                            // Limiter l'affichage si la réponse est trop longue (tableau de partenaires)
                            if jsonString.count > 2000 {
                                print("📥 [APIService] Réponse trop longue (\(jsonString.count) caractères), affichage tronqué:")
                                let truncated = String(jsonString.prefix(2000))
                                print(truncated)
                                print("... (tronqué)")
                            } else {
                                print(jsonString)
                            }
                            print("═══════════════════════════════════════════════════════════")
                        }
                        
                        // Vérifier spécifiquement isClub10 dans la réponse brute AVANT décodage
                        if endpoint.contains("/users/me") {
                            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                print("📥 [APIService] Tous les clés dans la réponse: \(jsonDict.keys.sorted())")
                                
                                // Le backend envoie "isClub10" dans les réponses
                                if let isClub10Value = jsonDict["isClub10"] {
                                    print("📥 [APIService] isClub10 dans la réponse brute (AVANT décodage): \(isClub10Value)")
                                    print("📥 [APIService] Type de isClub10 (AVANT décodage): \(type(of: isClub10Value))")
                                    
                                    // JSONSerialization convertit true/false en NSNumber (__NSCFBoolean)
                                    // C'est normal, mais on doit vérifier la valeur
                                    if let boolValue = isClub10Value as? Bool {
                                        print("📥 [APIService] ✅ isClub10 est un Bool Swift: \(boolValue)")
                                    } else if let numberValue = isClub10Value as? NSNumber {
                                        // NSNumber peut représenter un booléen (__NSCFBoolean)
                                        let boolFromNumber = numberValue.boolValue
                                        print("📥 [APIService] ⚠️ isClub10 est un NSNumber (\(numberValue)) - valeur booléenne: \(boolFromNumber)")
                                        print("📥 [APIService] ⚠️ Le JSONDecoder devrait convertir cela correctement en Bool")
                                    } else if let intValue = isClub10Value as? Int {
                                        print("📥 [APIService] ⚠️ PROBLÈME: isClub10 est un Int (\(intValue)) au lieu d'un Bool!")
                                    } else {
                                        print("📥 [APIService] ⚠️ Type inattendu pour isClub10: \(type(of: isClub10Value))")
                                    }
                                } else {
                                    print("📥 [APIService] ⚠️ isClub10 n'est PAS présent dans la réponse brute!")
                                }
                                
                                // Vérifier aussi "club10" pour compatibilité (au cas où le backend change)
                                if let club10ValueAlt = jsonDict["club10"] {
                                    print("📥 [APIService] ⚠️ club10 (sans 'is') trouvé aussi: \(club10ValueAlt)")
                                }
                            }
                        } else if endpoint.contains("/users/professionals/search") {
                            // Pour la recherche de partenaires, la réponse est un tableau
                            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                                print("📥 [APIService] Réponse est un tableau de \(jsonArray.count) partenaires")
                                
                                // Vérifier isClub10 pour chaque partenaire
                                for (index, partnerDict) in jsonArray.enumerated() {
                                    if let isClub10Value = partnerDict["isClub10"] {
                                        let partnerName = partnerDict["establishmentName"] as? String ?? 
                                                         "\(partnerDict["firstName"] as? String ?? "") \(partnerDict["lastName"] as? String ?? "")"
                                        print("📥 [APIService] Partenaire \(index + 1) (\(partnerName)): isClub10 = \(isClub10Value) (type: \(type(of: isClub10Value)))")
                                    } else {
                                        let partnerName = partnerDict["establishmentName"] as? String ?? 
                                                         "\(partnerDict["firstName"] as? String ?? "") \(partnerDict["lastName"] as? String ?? "")"
                                        print("📥 [APIService] ⚠️ Partenaire \(index + 1) (\(partnerName)): isClub10 est absent ou null")
                                    }
                                }
                            }
                        }
                    }
                }
                
                let decoded = try decoder.decode(T.self, from: data)
                
                // Log spécifique pour UserMeResponse après décodage
                if endpoint.contains("/users/me") {
                    // Utiliser une approche avec reflection pour accéder à isClub10
                    if decoded is [String: Any] {
                        print("📥 [APIService] APRÈS décodage - Type décodé: \(type(of: decoded))")
                    } else {
                        // Essayer d'accéder à la propriété via Mirror
                        let mirror = Mirror(reflecting: decoded)
                        if let isClub10Property = mirror.children.first(where: { $0.label == "isClub10" }) {
                            print("📥 [APIService] APRÈS décodage - isClub10 via Mirror: \(isClub10Property.value)")
                        }
                    }
                }
                
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
            
            // Log pour déboguer isClub10 dans multipart
            if let jsonString = String(data: jsonDataEncoded, encoding: .utf8) {
                print("📡 [APIService] multipartRequest() - JSON envoyé dans '\(jsonFieldName)':")
                print("   \(jsonString)")
                if let jsonDict = try? JSONSerialization.jsonObject(with: jsonDataEncoded) as? [String: Any] {
                    if let isClub10Value = jsonDict["isClub10"] {
                        print("   - isClub10 dans JSON: \(isClub10Value)")
                    } else {
                        print("   - isClub10 dans JSON: nil")
                    }
                }
            }
            
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

