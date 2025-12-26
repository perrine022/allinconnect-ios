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
    let id: Int?
    let firstName: String?
    let lastName: String?
    let email: String?
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
    let type: String? // "OFFRE" ou "EVENEMENT"
    let imageUrl: String?
    
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
        case type
        case imageUrl = "imageUrl"
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
    
    // MARK: - Get Active Offers (offres et événements actifs avec filtre temporel)
    func getActiveOffers(
        city: String? = nil,
        category: OfferCategory? = nil,
        type: String? = nil // "OFFRE" ou "EVENEMENT" pour filtrer
    ) async throws -> [OfferResponse] {
        var parameters: [String: Any] = [:]
        
        if let city = city {
            parameters["city"] = city
        }
        
        if let category = category {
            parameters["category"] = category.rawValue
        }
        
        if let type = type {
            parameters["type"] = type
        }
        
        // L'API retourne directement un tableau d'offres actives (statut ACTIVE et dates valides)
        let offers: [OfferResponse] = try await apiService.request(
            endpoint: "/offers/active",
            method: .get,
            parameters: parameters.isEmpty ? nil : parameters,
            headers: nil
        )
        return offers
    }
    
    // MARK: - Get All Offers (toutes les offres actives sans filtre temporel)
    func getAllOffers(
        city: String? = nil,
        category: OfferCategory? = nil,
        professionalId: Int? = nil,
        type: String? = nil // "OFFRE" ou "EVENEMENT" pour filtrer
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
        
        if let type = type {
            parameters["type"] = type
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
    
    // MARK: - Get Offers by Professional
    func getOffersByProfessional(professionalId: Int) async throws -> [OfferResponse] {
        let offers: [OfferResponse] = try await apiService.request(
            endpoint: "/offers/professional/\(professionalId)",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return offers
    }
    
    // MARK: - Get Active Offers by Professional (offres actives avec filtre temporel)
    func getActiveOffersByProfessional(professionalId: Int) async throws -> [OfferResponse] {
        let offers: [OfferResponse] = try await apiService.request(
            endpoint: "/offers/professional/\(professionalId)/active",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return offers
    }
    
    // MARK: - Create Offer
    func createOffer(
        title: String,
        description: String,
        price: Double?,
        startDate: String?,
        endDate: String?,
        featured: Bool?,
        type: String, // "OFFRE" ou "EVENEMENT"
        imageUrl: String? = nil
    ) async throws -> OfferResponse {
        var parameters: [String: Any] = [
            "title": title,
            "description": description,
            "type": type
        ]
        
        if let price = price {
            parameters["price"] = price
        }
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        if let featured = featured {
            parameters["featured"] = featured
        }
        
        if let imageUrl = imageUrl {
            parameters["imageUrl"] = imageUrl
        }
        
        // Log du payload et de l'endpoint
        let endpoint = "/offers"
        let baseURL = "http://127.0.0.1:8000/api/v1"
        let fullURL = "\(baseURL)\(endpoint)"
        
        print("[OffersAPIService] Création d'offre:")
        print("   Endpoint: POST \(fullURL)")
        print("   Payload JSON:")
        
        // Convertir les paramètres en JSON pour l'affichage
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        } else {
            print("   \(parameters)")
        }
        
        let offer: OfferResponse = try await apiService.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        print("[OffersAPIService] Réponse reçue: ID=\(offer.id), Title=\(offer.title)")
        return offer
    }
    
    // MARK: - Update Offer
    func updateOffer(
        id: Int,
        title: String? = nil,
        description: String? = nil,
        price: Double? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        featured: Bool? = nil,
        type: String? = nil, // "OFFRE" ou "EVENEMENT"
        imageUrl: String? = nil
    ) async throws -> OfferResponse {
        var parameters: [String: Any] = [:]
        
        if let title = title {
            parameters["title"] = title
        }
        
        if let description = description {
            parameters["description"] = description
        }
        
        if let price = price {
            parameters["price"] = price
        }
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        if let featured = featured {
            parameters["featured"] = featured
        }
        
        if let type = type {
            parameters["type"] = type
        }
        
        if let imageUrl = imageUrl {
            parameters["imageUrl"] = imageUrl
        }
        
        let offer: OfferResponse = try await apiService.request(
            endpoint: "/offers/\(id)",
            method: .put,
            parameters: parameters.isEmpty ? nil : parameters,
            headers: nil
        )
        return offer
    }
    
    // MARK: - Archive Offer
    func archiveOffer(id: Int) async throws -> OfferResponse {
        let offer: OfferResponse = try await apiService.request(
            endpoint: "/offers/\(id)/archive",
            method: .post,
            parameters: nil,
            headers: nil
        )
        return offer
    }
    
    // MARK: - Delete Offer
    func deleteOffer(id: Int) async throws {
        // Pour DELETE, l'API peut retourner 204 No Content (pas de body)
        // On utilise un type vide qui peut gérer les réponses vides
        struct EmptyResponse: Codable {
            init() {}
            init(from decoder: Decoder) throws {
                // Accepter un conteneur vide ou un JSON vide
                let container = try decoder.singleValueContainer()
                if !container.decodeNil() {
                    // Si ce n'est pas nil, on ignore la valeur
                }
            }
        }
        
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/offers/\(id)",
            method: .delete,
            parameters: nil,
            headers: nil
        )
    }
}

// MARK: - Mapping Extension
extension OfferResponse {
    func toOffer() -> Offer {
        // Convertir l'ID Int en UUID (on génère un UUID basé sur l'ID)
        let offerUUID = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", id, id)) ?? UUID()
        
        // Déterminer le nom de l'entreprise depuis le professionnel
        let businessName = professional?.firstName ?? "Entreprise"
        let fullBusinessName: String
        if let prof = professional, let firstName = prof.firstName, let lastName = prof.lastName {
            fullBusinessName = "\(firstName) \(lastName)"
        } else {
            fullBusinessName = businessName
        }
        
        // Convertir endDate en format français pour validUntil (DD/MM/YYYY)
        let validUntil: String
        if let endDate = endDate {
            // Essayer différents formats de date
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            
            // Format ISO 8601 avec heures (ex: 2026-01-24T00:00:00 ou 2026-01-24T00:00:00.000Z)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            var date = dateFormatter.date(from: endDate)
            
            // Si ça n'a pas fonctionné, essayer avec les millisecondes
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                date = dateFormatter.date(from: endDate)
            }
            
            // Si ça n'a pas fonctionné, essayer avec le Z à la fin
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                date = dateFormatter.date(from: endDate)
            }
            
            // Si ça n'a pas fonctionné, essayer le format simple YYYY-MM-DD
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.date(from: endDate)
            }
            
            // Si on a réussi à parser la date, formater en DD/MM/YYYY
            if let date = date {
                dateFormatter.dateFormat = "dd/MM/yyyy"
                validUntil = dateFormatter.string(from: date)
            } else {
                // Si le parsing a échoué, utiliser la date telle quelle
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
        
        // Déterminer le type d'offre depuis le champ type de l'API
        let offerTypeEnum: OfferType
        if let typeString = type?.uppercased() {
            if typeString == "EVENEMENT" {
                offerTypeEnum = .event
            } else {
                offerTypeEnum = .offer
            }
        } else {
            // Par défaut, considérer comme une offre
            offerTypeEnum = .offer
        }
        
        // Déterminer si c'est CLUB10 (basé sur featured ou autre logique)
        let isClub10 = featured ?? false
        
        // Convertir l'ID du professionnel en UUID si disponible
        let partnerId: UUID? = professional.flatMap { prof in
            guard let profId = prof.id else { return nil }
            return UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", profId, profId))
        }
        
        // Déterminer l'image par défaut selon la catégorie du professionnel
        // Si imageUrl est fourni et non vide, on pourrait l'utiliser, sinon utiliser l'image par défaut
        let defaultImage: String
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            // Si une URL d'image est fournie, on utilise quand même une image par défaut pour l'instant
            // (car on utilise des SF Symbols, pas des URLs d'images)
            defaultImage = DefaultImageHelper.defaultImageForOfferCategory(professional?.category)
        } else {
            defaultImage = DefaultImageHelper.defaultImageForOfferCategory(professional?.category)
        }
        
        return Offer(
            id: offerUUID,
            title: title,
            description: description,
            businessName: fullBusinessName,
            validUntil: validUntil,
            discount: discount,
            imageName: defaultImage,
            offerType: offerTypeEnum,
            isClub10: isClub10,
            partnerId: partnerId,
            apiId: id // Stocker l'ID original de l'API
        )
    }
}

