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
        type: String? = nil, // "OFFRE" ou "EVENEMENT" pour filtrer
        startDate: String? = nil, // Format ISO 8601: YYYY-MM-DDTHH:mm:ss
        endDate: String? = nil // Format ISO 8601: YYYY-MM-DDTHH:mm:ss
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
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        
        if let endDate = endDate {
            parameters["endDate"] = endDate
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
    /// Récupère la liste des offres disponibles
    /// Endpoint public : Ne nécessite pas de token valide (même avec un token expiré, l'endpoint fonctionne)
    func getAllOffers(
        city: String? = nil,
        category: OfferCategory? = nil,
        professionalId: Int? = nil,
        type: String? = nil, // "OFFRE" ou "EVENEMENT" pour filtrer
        startDate: String? = nil, // Format ISO 8601: YYYY-MM-DDTHH:mm:ss
        endDate: String? = nil // Format ISO 8601: YYYY-MM-DDTHH:mm:ss
    ) async throws -> [OfferResponse] {
        print("📡 [API] 📞 Appel GET /api/v1/offers (endpoint public)")
        print("📡 [API] Paramètres: city=\(city ?? "nil"), type=\(type ?? "nil"), category=\(category?.rawValue ?? "nil")")
        
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
        
        if let startDate = startDate {
            parameters["startDate"] = startDate
        }
        
        if let endDate = endDate {
            parameters["endDate"] = endDate
        }
        
        do {
            // L'API retourne directement un tableau d'offres, pas un objet avec une clé "offres"
            // Endpoint public : fonctionne même sans token ou avec token expiré
            let offers: [OfferResponse] = try await apiService.request(
                endpoint: "/offers",
                method: .get,
                parameters: parameters.isEmpty ? nil : parameters,
                headers: nil
            )
            print("📡 [API] ✅ Offres récupérées: \(offers.count) offres")
            return offers
        } catch let apiError as APIError {
            if case .unauthorized = apiError {
                // Si on reçoit une 401 sur cet endpoint public, c'est anormal mais on log quand même
                // Le backend ne devrait plus retourner 401 pour cet endpoint, mais on gère toutes les erreurs
                print("📡 [API] ⚠️ Erreur 401 sur endpoint public /offers (anormal mais géré)")
                print("📡 [API] ⚠️ Retour d'un tableau vide au lieu d'une erreur bloquante")
                // Retourner un tableau vide plutôt que de bloquer l'application
                return []
            }
            throw apiError
        } catch {
            print("📡 [API] ❌ Erreur lors de la récupération des offres: \(error)")
            throw error
        }
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
        imageUrl: String? = nil,
        imageData: Data? = nil
    ) async throws -> OfferResponse {
        var jsonData: [String: Any] = [
            "title": title,
            "description": description,
            "type": type
        ]
        
        if let price = price {
            jsonData["price"] = price
        }
        
        if let startDate = startDate {
            jsonData["startDate"] = startDate
        }
        
        if let endDate = endDate {
            jsonData["endDate"] = endDate
        }
        
        if let featured = featured {
            jsonData["featured"] = featured
        }
        
        // Si imageUrl est fourni (sans imageData), on l'inclut dans le JSON
        if let imageUrl = imageUrl, imageData == nil {
            jsonData["imageUrl"] = imageUrl
        }
        
        // Log du payload et de l'endpoint
        let endpoint = "/offers"
        let baseURL = "https://allinconnect-back-1.onrender.com/api/v1" // Production
        // let baseURL = "http://127.0.0.1:8080/api/v1" // Local
        let fullURL = "\(baseURL)\(endpoint)"
        
        print("[OffersAPIService] Création d'offre:")
        print("   Endpoint: POST \(fullURL)")
        print("   Payload JSON:")
        
        // Convertir les paramètres en JSON pour l'affichage
        if let jsonDataPretty = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
           let jsonString = String(data: jsonDataPretty, encoding: .utf8) {
            print(jsonString)
        } else {
            print("   \(jsonData)")
        }
        
        // Utiliser multipart si une image est fournie, sinon utiliser JSON classique
        if let imageData = imageData {
            // Utiliser multipart/form-data
            guard let apiServiceInstance = apiService as? APIService else {
                throw APIError.invalidResponse
            }
            
            let offer: OfferResponse = try await apiServiceInstance.multipartRequest(
                endpoint: endpoint,
                method: .post,
                jsonData: jsonData,
                imageData: imageData,
                imageFieldName: "image",
                jsonFieldName: "offer",
                headers: nil
            )
            
            print("[OffersAPIService] Réponse reçue (multipart): ID=\(offer.id), Title=\(offer.title)")
            return offer
        } else {
            // Utiliser JSON classique (pour compatibilité avec l'ancien code)
            let offer: OfferResponse = try await apiService.request(
                endpoint: endpoint,
                method: .post,
                parameters: jsonData,
                headers: nil
            )
            
            print("[OffersAPIService] Réponse reçue: ID=\(offer.id), Title=\(offer.title)")
            return offer
        }
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
        imageUrl: String? = nil,
        imageData: Data? = nil
    ) async throws -> OfferResponse {
        var jsonData: [String: Any] = [:]
        
        if let title = title {
            jsonData["title"] = title
        }
        
        if let description = description {
            jsonData["description"] = description
        }
        
        if let price = price {
            jsonData["price"] = price
        }
        
        if let startDate = startDate {
            jsonData["startDate"] = startDate
        }
        
        if let endDate = endDate {
            jsonData["endDate"] = endDate
        }
        
        if let featured = featured {
            jsonData["featured"] = featured
        }
        
        if let type = type {
            jsonData["type"] = type
        }
        
        // Si imageUrl est fourni (sans imageData), on l'inclut dans le JSON
        if let imageUrl = imageUrl, imageData == nil {
            jsonData["imageUrl"] = imageUrl
        }
        
        // Utiliser multipart si une image est fournie, sinon utiliser JSON classique
        if let imageData = imageData {
            // Utiliser multipart/form-data
            guard let apiServiceInstance = apiService as? APIService else {
                throw APIError.invalidResponse
            }
            
            let offer: OfferResponse = try await apiServiceInstance.multipartRequest(
                endpoint: "/offers/\(id)",
                method: .put,
                jsonData: jsonData.isEmpty ? [:] : jsonData,
                imageData: imageData,
                imageFieldName: "image",
                jsonFieldName: "offer",
                headers: nil
            )
            
            return offer
        } else {
            // Utiliser JSON classique
            let offer: OfferResponse = try await apiService.request(
                endpoint: "/offers/\(id)",
                method: .put,
                parameters: jsonData.isEmpty ? nil : jsonData,
                headers: nil
            )
            return offer
        }
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
        
        // Fonction helper pour formater une date ISO en format français
        func formatDateToFrench(_ dateString: String?) -> String? {
            guard let dateString = dateString else { return nil }
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            
            // Format ISO 8601 avec heures (ex: 2026-01-24T00:00:00 ou 2026-01-24T00:00:00.000Z)
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            var date = dateFormatter.date(from: dateString)
            
            // Si ça n'a pas fonctionné, essayer avec les millisecondes
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                date = dateFormatter.date(from: dateString)
            }
            
            // Si ça n'a pas fonctionné, essayer avec le Z à la fin
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                date = dateFormatter.date(from: dateString)
            }
            
            // Si ça n'a pas fonctionné, essayer le format simple YYYY-MM-DD
            if date == nil {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.date(from: dateString)
            }
            
            // Si on a réussi à parser la date, formater en DD/MM/YYYY
            if let date = date {
                dateFormatter.dateFormat = "dd/MM/yyyy"
                return dateFormatter.string(from: date)
            } else {
                // Si le parsing a échoué, retourner nil
                return nil
            }
        }
        
        // Convertir endDate en format français pour validUntil (DD/MM/YYYY)
        let validUntil: String
        if let endDate = endDate, let formatted = formatDateToFrench(endDate) {
            validUntil = formatted
        } else if let endDate = endDate {
            validUntil = endDate
        } else {
            validUntil = "N/A"
        }
        
        // Convertir startDate en format français
        let startDateFormatted: String? = formatDateToFrench(startDate)
        
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
        
        // Déterminer l'image par défaut selon l'activité/catégorie du professionnel
        // Si aucune imageUrl n'est fournie, utiliser l'image par défaut basée sur la catégorie/profession
        let defaultImage: String
        if let imageUrl = imageUrl, !imageUrl.isEmpty {
            // Si une URL d'image est fournie, on utilise quand même une image par défaut pour l'instant
            // (car on utilise des SF Symbols, pas des URLs d'images)
            // Mais on devrait idéalement charger l'image depuis l'URL
            defaultImage = DefaultImageHelper.defaultImageForOfferCategory(professional?.category)
        } else {
            // Pas d'image fournie, utiliser l'image par défaut selon l'activité du professionnel
            // D'abord essayer la catégorie (OfferCategory)
            if let category = professional?.category {
                defaultImage = DefaultImageHelper.defaultImageForOfferCategory(category)
            } else if let profession = professional?.profession, !profession.isEmpty {
                // Si pas de catégorie, utiliser la profession (String)
                defaultImage = DefaultImageHelper.defaultImageForPartnerCategory(profession)
            } else {
                // Par défaut si aucune info n'est disponible
                defaultImage = "tag.fill"
            }
        }
        
        return Offer(
            id: offerUUID,
            title: title,
            description: description,
            businessName: fullBusinessName,
            validUntil: validUntil,
            startDate: startDateFormatted,
            discount: discount,
            imageName: defaultImage,
            imageUrl: imageUrl, // Passer l'URL de l'image depuis le backend
            offerType: offerTypeEnum,
            isClub10: isClub10,
            partnerId: partnerId,
            apiId: id // Stocker l'ID original de l'API
        )
    }
}

