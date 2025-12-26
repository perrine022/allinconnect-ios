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
    let currentPassword: String
    let newPassword: String
    let confirmationPassword: String
    
    enum CodingKeys: String, CodingKey {
        case currentPassword = "currentPassword"
        case newPassword = "newPassword"
        case confirmationPassword = "confirmationPassword"
    }
}

// MARK: - Card Member Model
struct CardMember: Codable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
}

// MARK: - Card Response Model
struct CardResponse: Codable {
    let id: Int?
    let cardNumber: String
    let type: String
    let members: [CardMember]?
    let invitedEmails: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardNumber = "cardNumber"
        case type
        case members
        case invitedEmails
    }
}

// MARK: - User Me Response Model (Full User)
struct UserMeResponse: Codable {
    let id: Int?
    let email: String?
    let firstName: String
    let lastName: String
    let address: String?
    let city: String?
    let postalCode: String?
    let latitude: Double?
    let longitude: Double?
    let card: CardResponse?
    let isCardActive: Bool?
    
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
        case isCardActive = "cardActive" // Backend retourne "cardActive" au lieu de "isCardActive"
        case establishmentName = "establishmentName"
        case establishmentDescription = "establishmentDescription"
        case phoneNumber = "phoneNumber"
        case website
        case instagram
        case openingHours = "openingHours"
        case profession
        case category
    }
    
    // Initializer personnalisé pour gérer les valeurs optionnelles avec valeurs par défaut
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        // Rendre firstName et lastName optionnels avec valeurs par défaut
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        card = try container.decodeIfPresent(CardResponse.self, forKey: .card)
        isCardActive = try container.decodeIfPresent(Bool.self, forKey: .isCardActive)
        establishmentName = try container.decodeIfPresent(String.self, forKey: .establishmentName)
        establishmentDescription = try container.decodeIfPresent(String.self, forKey: .establishmentDescription)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        openingHours = try container.decodeIfPresent(String.self, forKey: .openingHours)
        profession = try container.decodeIfPresent(String.self, forKey: .profession)
        category = try container.decodeIfPresent(OfferCategory.self, forKey: .category)
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
        case isMember = "member" // Backend retourne "member" au lieu de "isMember"
        case card
        case isCardActive = "cardActive" // Backend retourne "cardActive" au lieu de "isCardActive"
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
        // Rendre firstName et lastName optionnels avec valeurs par défaut
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
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

// MARK: - Payment Status Enum
enum PaymentStatus: String {
    case success = "Payé"
    case pending = "En attente"
    case failed = "Échoué"
}

// MARK: - Payment Response Model
struct PaymentResponse: Codable {
    let id: Int
    let amount: Double
    let paymentDate: String // Backend retourne "paymentDate"
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case paymentDate = "paymentDate"
        case status
    }
    
    // Helper pour obtenir la date formatée
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = dateFormatter.date(from: paymentDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy"
            return displayFormatter.string(from: date)
        }
        
        // Essayer avec les millisecondes
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        if let date = dateFormatter.date(from: paymentDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy"
            return displayFormatter.string(from: date)
        }
        
        // Essayer avec Z
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let date = dateFormatter.date(from: paymentDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy"
            return displayFormatter.string(from: date)
        }
        
        // Si aucun format ne fonctionne, retourner la date telle quelle
        return paymentDate
    }
    
    // Helper pour obtenir le statut local
    var paymentStatus: PaymentStatus {
        guard let status = status else { return .pending }
        switch status.uppercased() {
        case "SUCCESS", "COMPLETED", "PAID":
            return .success
        case "FAILED", "CANCELLED", "REFUNDED":
            return .failed
        default:
            return .pending
        }
    }
    
    // Helper pour formater le montant
    var formattedAmount: String {
        String(format: "%.2f€", amount)
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
        guard let id = userMe.id else {
            throw APIError.invalidResponse
        }
        return String(id)
    }
}

