//
//  OffersAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Offer Category Enum
enum OfferCategory: String, Codable, CaseIterable {
    case santeBienEtre = "SANTE_BIEN_ETRE"
    case beauteEsthetique = "BEAUTE_ESTHETIQUE"
    case foodPlaisirs = "FOOD_PLAISIRS"
    case loisirsDivertissements = "LOISIRS_DIVERTISSEMENTS"
    case servicePratiques = "SERVICE_PRATIQUES"
    case entrePros = "ENTRE_PROS"
    
    var displayName: String {
        switch self {
        case .santeBienEtre:
            return "Santé & bien être"
        case .beauteEsthetique:
            return "Beauté & Esthétique"
        case .foodPlaisirs:
            return "Food & plaisirs gourmands"
        case .loisirsDivertissements:
            return "Loisirs & Divertissements"
        case .servicePratiques:
            return "Service & pratiques"
        case .entrePros:
            return "Entre pros"
        }
    }
}

// MARK: - Professional Response Model
struct ProfessionalResponse: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let city: String?
    let profession: String?
    let category: OfferCategory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "firstName"
        case lastName = "lastName"
        case email
        case city
        case profession
        case category
    }
}

// MARK: - API Response Models
struct OfferResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Double?
    let startDate: String?
    let endDate: String?
    let featured: Bool?
    let status: String?
    let professional: ProfessionalResponse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case startDate = "startDate"
        case endDate = "endDate"
        case featured
        case status
        case professional
    }
}

// MARK: - Offers API Service
@MainActor
class OffersAPIService: ObservableObject {
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
    
    // MARK: - Get All Offers
    func getAllOffers(
        city: String? = nil,
        category: OfferCategory? = nil,
        professionalId: Int? = nil
    ) async throws -> [OfferResponse] {
        var parameters: [String: Any] = [:]
        
        if let city = city {
            parameters["city"] = city
        }
        
        if let category = category {
            parameters["category"] = category.rawValue
        }
        
        if let professionalId = professionalId {
            parameters["professionalId"] = professionalId
        }
        
        // L'API retourne directement un tableau d'offres, pas un objet avec une clé "offers"
        let offers: [OfferResponse] = try await apiService.request(
            endpoint: "/offers",
            method: .get,
            parameters: parameters.isEmpty ? nil : parameters,
            headers: nil
        )
        return offers
    }
    
    // MARK: - Get Offer Detail
    func getOfferDetail(id: Int) async throws -> OfferResponse {
        return try await apiService.request(
            endpoint: "/offers/\(id)",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Get My Offers (Pro)
    func getMyOffers() async throws -> [OfferResponse] {
        // L'API retourne directement un tableau d'offres
        let offers: [OfferResponse] = try await apiService.request(
            endpoint: "/offers/my-offers",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return offers
    }
}

// MARK: - Mapping Extension
extension OfferResponse {
    func toOffer() -> Offer {
        // Convertir l'ID Int en UUID (on génère un UUID basé sur l'ID)
        let offerUUID = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", id, id)) ?? UUID()
        
        // Déterminer le nom de l'entreprise depuis le professionnel
        let businessName = professional?.firstName ?? "Entreprise"
        let fullBusinessName = professional.map { "\($0.firstName) \($0.lastName)" } ?? businessName
        
        // Convertir endDate en format français pour validUntil
        let validUntil: String
        if let endDate = endDate {
            // Convertir de YYYY-MM-DD à DD/MM/YYYY
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: endDate) {
                dateFormatter.dateFormat = "dd/MM/yyyy"
                validUntil = dateFormatter.string(from: date)
            } else {
                validUntil = endDate
            }
        } else {
            validUntil = "N/A"
        }
        
        // Créer un discount depuis le price
        let discount: String
        if let price = price {
            discount = "\(String(format: "%.2f", price))€"
        } else {
            discount = "Sur devis"
        }
        
        // Déterminer le type d'offre (par défaut "offer")
        let offerTypeEnum: OfferType = .offer
        
        // Déterminer si c'est CLUB10 (basé sur featured ou autre logique)
        let isClub10 = featured ?? false
        
        // Convertir l'ID du professionnel en UUID si disponible
        let partnerId: UUID? = professional.map { prof in
            UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", prof.id, prof.id)) ?? UUID()
        }
        
        return Offer(
            id: offerUUID,
            title: title,
            description: description,
            businessName: fullBusinessName,
            validUntil: validUntil,
            discount: discount,
            imageName: "tag.fill", // Par défaut, peut être amélioré plus tard
            offerType: offerTypeEnum,
            isClub10: isClub10,
            partnerId: partnerId,
            apiId: id // Stocker l'ID original de l'API
        )
    }
}

