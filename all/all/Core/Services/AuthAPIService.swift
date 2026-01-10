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
    func forgotPassword(email: String) async throws {
        let forgotPasswordRequest = ForgotPasswordRequest(email: email)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(forgotPasswordRequest)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/auth/forgot-password",
            method: .post,
            parameters: parameters,
            headers: nil
        )
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


