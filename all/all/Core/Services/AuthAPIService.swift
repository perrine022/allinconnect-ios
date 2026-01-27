//
//  AuthAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - User Type Enum
enum APIUserType: String, Codable {
    case client = "CLIENT"
    case professional = "PROFESSIONAL"
}

// MARK: - Subscription Type Enum
enum APISubscriptionType: String, Codable {
    case free = "FREE"
    case premium = "PREMIUM"
}

// MARK: - Registration Request
struct RegistrationRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let address: String?
    let city: String?
    let postalCode: String?
    let birthDate: String?
    let userType: APIUserType? // Optionnel - le backend mettra UNKNOWN par défaut si non fourni
    let subscriptionType: APISubscriptionType
    let profession: String?
    let category: OfferCategory?
    let subCategory: String? // Sous-catégorie (saisie libre)
    let referralCode: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "firstName"
        case lastName = "lastName"
        case email
        case password
        case address
        case city
        case postalCode = "postalCode"
        case birthDate = "birthDate"
        case userType = "userType"
        case subscriptionType = "subscriptionType"
        case profession
        case category
        case subCategory = "subCategory"
        case referralCode = "referralCode"
    }
}

// MARK: - Login Request
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let token: String
}

// MARK: - Forgot Password Request
struct ForgotPasswordRequest: Codable {
    let email: String
}

// MARK: - Reset Password Request
struct ResetPasswordRequest: Codable {
    let token: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case token
        case newPassword = "newPassword"
    }
}

// MARK: - Forgot Password Log Response
struct ForgotPasswordLogResponse: Codable, Identifiable {
    let id: Int
    let email: String
    let userId: Int?
    let userFirstName: String?
    let userLastName: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case userId
        case userFirstName
        case userLastName
        case createdAt
    }
}

// MARK: - Create Forgot Password Log Request
struct CreateForgotPasswordLogRequest: Codable {
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case email
    }
}

// MARK: - Auth API Service
@MainActor
class AuthAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Register
    func register(_ request: RegistrationRequest) async throws -> AuthResponse {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let cleanedParameters = jsonObject.compactMapValues { value -> Any? in
            if value is NSNull {
                return nil
            }
            return value
        }
        
        return try await apiService.request(
            endpoint: "/auth/register",
            method: .post,
            parameters: cleanedParameters,
            headers: nil
        )
    }
    
    // MARK: - Authenticate
    func authenticate(email: String, password: String) async throws -> AuthResponse {
        let loginRequest = LoginRequest(email: email, password: password)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(loginRequest)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return try await apiService.request(
            endpoint: "/auth/authenticate",
            method: .post,
            parameters: parameters,
            headers: nil
        )
    }
    
    // MARK: - Forgot Password
    /// Envoie une demande de réinitialisation de mot de passe
    /// Endpoint: POST /api/v1/forgot-password-logs
    /// Cet endpoint enregistre la demande dans les logs, identifie l'utilisateur et retourne les informations complètes
    func forgotPassword(email: String) async throws -> ForgotPasswordLogResponse {
        print("═══════════════════════════════════════════════════════════")
        print("🔐 [AuthAPIService] forgotPassword() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("🔐 [AuthAPIService] Endpoint: POST /api/v1/forgot-password-logs")
        print("🔐 [AuthAPIService] Email: \(email)")
        
        let request = CreateForgotPasswordLogRequest(email: email)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let log: ForgotPasswordLogResponse = try await apiService.request(
            endpoint: "/forgot-password-logs",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        print("🔐 [AuthAPIService] ✅ Demande de réinitialisation envoyée")
        print("   - Log ID: \(log.id)")
        print("   - Email: \(log.email)")
        if let userId = log.userId {
            print("   - User ID: \(userId)")
            print("   - User: \(log.userFirstName ?? "") \(log.userLastName ?? "")")
        } else {
            print("   - Utilisateur non trouvé pour cet email")
        }
        print("   - Created At: \(log.createdAt)")
        print("═══════════════════════════════════════════════════════════")
        
        return log
    }
    
    // MARK: - Get Forgot Password Logs
    /// Récupère tous les logs de réinitialisation de mot de passe
    /// Endpoint: GET /api/v1/forgot-password-logs
    func getForgotPasswordLogs() async throws -> [ForgotPasswordLogResponse] {
        print("═══════════════════════════════════════════════════════════")
        print("📋 [AuthAPIService] getForgotPasswordLogs() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("📋 [AuthAPIService] Endpoint: GET /api/v1/forgot-password-logs")
        
        let logs: [ForgotPasswordLogResponse] = try await apiService.request(
            endpoint: "/forgot-password-logs",
            method: .get,
            parameters: nil,
            headers: nil
        )
        
        print("📋 [AuthAPIService] ✅ \(logs.count) log(s) récupéré(s)")
        print("═══════════════════════════════════════════════════════════")
        
        return logs
    }
    
    // MARK: - Create Forgot Password Log
    /// Crée un nouveau log de réinitialisation de mot de passe
    /// Endpoint: POST /api/v1/forgot-password-logs
    /// Body: { "email": "user@example.com" }
    func createForgotPasswordLog(email: String) async throws -> ForgotPasswordLogResponse {
        print("📋 [AuthAPIService] createForgotPasswordLog() - Début")
        print("📋 [AuthAPIService] Endpoint: POST /api/v1/forgot-password-logs")
        print("📋 [AuthAPIService] Email: \(email)")
        
        let request = CreateForgotPasswordLogRequest(email: email)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let log: ForgotPasswordLogResponse = try await apiService.request(
            endpoint: "/forgot-password-logs",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        print("📋 [AuthAPIService] ✅ Log créé avec succès: ID=\(log.id)")
        
        return log
    }
    
    // MARK: - Reset Password
    func resetPassword(token: String, newPassword: String) async throws {
        let resetPasswordRequest = ResetPasswordRequest(token: token, newPassword: newPassword)
        
        // Encoder la requête en JSON (les CodingKeys gèrent déjà le mapping)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(resetPasswordRequest)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // La réponse peut être vide ou un message de succès
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/auth/reset-password",
            method: .post,
            parameters: parameters,
            headers: nil
        )
    }
}


