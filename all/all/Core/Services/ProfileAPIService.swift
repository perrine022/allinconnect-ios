//
//  ProfileAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Update Profile Request
struct UpdateProfileRequest: Codable {
    // Champs utilisateur généraux
    let firstName: String?
    let lastName: String?
    let email: String?
    let address: String?
    let city: String?
    let birthDate: String? // Format YYYY-MM-DD
    let latitude: Double?
    let longitude: Double?
    
    // Champs professionnel (établissement)
    let establishmentName: String?
    let establishmentDescription: String?
    let phoneNumber: String?
    let website: String?
    let instagram: String?
    let openingHours: String?
    let profession: String?
    let category: OfferCategory?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "firstName"
        case lastName = "lastName"
        case email
        case address
        case city
        case birthDate = "birthDate"
        case latitude
        case longitude
        case establishmentName = "establishmentName"
        case establishmentDescription = "establishmentDescription"
        case phoneNumber = "phoneNumber"
        case website
        case instagram
        case openingHours = "openingHours"
        case profession
        case category
    }
}

// MARK: - Change Password Request
struct ChangePasswordRequest: Codable {
    let oldPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case oldPassword = "oldPassword"
        case newPassword = "newPassword"
    }
}

// MARK: - Card Response Model
struct CardResponse: Codable {
    let id: Int
    let cardNumber: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardNumber = "cardNumber"
        case type
    }
}

// MARK: - User Me Response Model (Full User)
struct UserMeResponse: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let address: String?
    let city: String?
    let postalCode: String?
    let latitude: Double?
    let longitude: Double?
    let card: CardResponse?
    
    // Champs professionnel (établissement)
    let establishmentName: String?
    let establishmentDescription: String?
    let phoneNumber: String?
    let website: String?
    let instagram: String?
    let openingHours: String?
    let profession: String?
    let category: OfferCategory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "firstName"
        case lastName = "lastName"
        case address
        case city
        case postalCode = "postalCode"
        case latitude
        case longitude
        case card
        case establishmentName = "establishmentName"
        case establishmentDescription = "establishmentDescription"
        case phoneNumber = "phoneNumber"
        case website
        case instagram
        case openingHours = "openingHours"
        case profession
        case category
    }
}

// MARK: - User Light Response Model
struct UserLightResponse: Codable {
    let firstName: String
    let lastName: String
    let isMember: Bool?
    let card: CardResponse?
    let isCardActive: Bool?
    let referralCount: Int?
    let favoriteCount: Int?
    let subscriptionDate: String?
    let renewalDate: String?
    let subscriptionAmount: Double?
    let payments: [PaymentResponse]?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "firstName"
        case lastName = "lastName"
        case isMember = "isMember"
        case card
        case isCardActive = "isCardActive"
        case referralCount = "referralCount"
        case favoriteCount = "favoriteCount"
        case subscriptionDate = "subscriptionDate"
        case renewalDate = "renewalDate"
        case subscriptionAmount = "subscriptionAmount"
        case payments
    }
    
    // Initializer personnalisé pour gérer les valeurs optionnelles avec valeurs par défaut
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        isMember = try container.decodeIfPresent(Bool.self, forKey: .isMember) ?? false
        card = try container.decodeIfPresent(CardResponse.self, forKey: .card)
        isCardActive = try container.decodeIfPresent(Bool.self, forKey: .isCardActive) ?? false
        referralCount = try container.decodeIfPresent(Int.self, forKey: .referralCount) ?? 0
        favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        subscriptionDate = try container.decodeIfPresent(String.self, forKey: .subscriptionDate)
        renewalDate = try container.decodeIfPresent(String.self, forKey: .renewalDate)
        subscriptionAmount = try container.decodeIfPresent(Double.self, forKey: .subscriptionAmount)
        payments = try container.decodeIfPresent([PaymentResponse].self, forKey: .payments)
    }
}

// MARK: - Payment Response Model
struct PaymentResponse: Codable {
    let id: Int
    let amount: Double
    let date: String
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case date
        case status
    }
}

// MARK: - Profile API Service
@MainActor
class ProfileAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        // Utiliser le service fourni ou créer une nouvelle instance
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            // Accéder à shared dans un contexte MainActor
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(_ request: UpdateProfileRequest) async throws {
        // Encoder la requête en JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // Nettoyer les valeurs nil (NSNull dans JSON)
        let cleanedParameters = parameters.compactMapValues { value -> Any? in
            if value is NSNull {
                return nil
            }
            return value
        }
        
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/users/profile",
            method: .put,
            parameters: cleanedParameters,
            headers: nil
        )
    }
    
    // MARK: - Change Password
    func changePassword(_ request: ChangePasswordRequest) async throws {
        // Encoder la requête en JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/users/change-password",
            method: .post,
            parameters: parameters,
            headers: nil
        )
    }
    
    // MARK: - Get User Light (Profile Light)
    func getUserLight() async throws -> UserLightResponse {
        return try await apiService.request(
            endpoint: "/users/me/light",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Get Current User (Full)
    func getUserMe() async throws -> UserMeResponse {
        return try await apiService.request(
            endpoint: "/users/me",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Get Current User ID
    func getCurrentUserId() async throws -> String {
        let userMe = try await getUserMe()
        return String(userMe.id)
    }
}

