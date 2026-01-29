//
//  PartnersAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Professional Response Model (for Partners API)
struct PartnerProfessionalResponse: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let address: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let birthDate: String?
    let userType: String
    let subscriptionType: String?
    let profession: String?
    let category: OfferCategory?
    let subCategory: String? // Sous-catégorie (ex: "Coiffure")
    let hasConnectedBefore: Bool?
    let referralCode: String?
    let subscriptionPlan: SubscriptionPlanResponse?
    let establishmentName: String? // Ajouté pour les favoris
    let establishmentDescription: String?
    let establishmentImageUrl: String? // URL absolue de l'image de l'établissement
    let phoneNumber: String?
    let website: String?
    let instagram: String?
    let openingHours: String?
    let distanceMeters: Double? // Distance en mètres depuis la position de l'utilisateur (si recherche géolocalisée)
    let isClub10: Bool? // Indique si l'établissement fait partie du Club 10
    let averageRating: Double? // Note moyenne depuis le backend
    let reviewCount: Int? // Nombre d'avis depuis le backend
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "firstName"
        case lastName = "lastName"
        case address
        case city
        case latitude
        case longitude
        case birthDate = "birthDate"
        case userType = "userType"
        case subscriptionType = "subscriptionType"
        case profession
        case category
        case subCategory = "subCategory"
        case hasConnectedBefore = "hasConnectedBefore"
        case referralCode = "referralCode"
        case subscriptionPlan = "subscriptionPlan"
        case establishmentName = "establishmentName"
        case establishmentDescription = "establishmentDescription"
        case establishmentImageUrl = "establishmentImageUrl"
        case phoneNumber = "phoneNumber"
        case website
        case instagram
        case openingHours = "openingHours"
        case distanceMeters = "distanceMeters"
        case isClub10 = "isClub10" // Le backend envoie "isClub10" dans les réponses
        case averageRating = "averageRating"
        case reviewCount = "reviewCount"
    }
    
    // Initializer personnalisé pour gérer isClub10 qui peut être envoyé comme Int (1/0) au lieu de Bool
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        userType = try container.decode(String.self, forKey: .userType)
        subscriptionType = try container.decodeIfPresent(String.self, forKey: .subscriptionType)
        profession = try container.decodeIfPresent(String.self, forKey: .profession)
        category = try container.decodeIfPresent(OfferCategory.self, forKey: .category)
        subCategory = try container.decodeIfPresent(String.self, forKey: .subCategory)
        hasConnectedBefore = try container.decodeIfPresent(Bool.self, forKey: .hasConnectedBefore)
        referralCode = try container.decodeIfPresent(String.self, forKey: .referralCode)
        subscriptionPlan = try container.decodeIfPresent(SubscriptionPlanResponse.self, forKey: .subscriptionPlan)
        establishmentName = try container.decodeIfPresent(String.self, forKey: .establishmentName)
        establishmentDescription = try container.decodeIfPresent(String.self, forKey: .establishmentDescription)
        establishmentImageUrl = try container.decodeIfPresent(String.self, forKey: .establishmentImageUrl)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        openingHours = try container.decodeIfPresent(String.self, forKey: .openingHours)
        distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters)
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        
        // Décoder isClub10 - le backend peut envoyer 1/0 (Int) au lieu de true/false (Bool)
        // Gérer les deux cas pour compatibilité
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .isClub10) {
            isClub10 = boolValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .isClub10) {
            // Convertir 1 -> true, 0 -> false
            isClub10 = (intValue != 0)
            print("🏢 [PartnerProfessionalResponse] ⚠️ isClub10 reçu comme Int (\(intValue)), converti en Bool: \(isClub10 ?? false)")
        } else {
            // Essayer de décoder comme n'importe quel nombre (Double, etc.)
            if let numberValue = try? container.decodeIfPresent(Double.self, forKey: .isClub10) {
                isClub10 = (numberValue != 0.0)
                print("🏢 [PartnerProfessionalResponse] ⚠️ isClub10 reçu comme Double (\(numberValue)), converti en Bool: \(isClub10 ?? false)")
            } else {
                isClub10 = nil
            }
        }
    }
}

// MARK: - Partners API Service
@MainActor
class PartnersAPIService: ObservableObject {
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
    
    // MARK: - Get All Professionals
    func getAllProfessionals() async throws -> [PartnerProfessionalResponse] {
        // L'API retourne directement un tableau de professionnels
        do {
            let professionals: [PartnerProfessionalResponse] = try await apiService.request(
                endpoint: "/users/professionals",
                method: .get,
                parameters: nil,
                headers: nil
            )
            return professionals
        } catch let error as APIError {
            // Gérer spécifiquement l'erreur de décodage pour les réponses corrompues
            if case .decodingError(let underlyingError) = error,
               let nsError = underlyingError as NSError?,
               nsError.domain == NSCocoaErrorDomain,
               nsError.code == 3840 {
                // Erreur de décodage JSON (réponse corrompue ou malformée)
                // Retourner un tableau vide plutôt que de faire planter l'app
                print("[PartnersAPIService] Erreur de décodage JSON, retour d'un tableau vide")
                return []
            }
            throw error
        }
    }
    
    // MARK: - Get Professionals By City
    func getProfessionalsByCity(city: String) async throws -> [PartnerProfessionalResponse] {
        let parameters: [String: Any] = [
            "city": city
        ]
        
        do {
            let professionals: [PartnerProfessionalResponse] = try await apiService.request(
                endpoint: "/users/professionals/by-city",
                method: .get,
                parameters: parameters,
                headers: nil
            )
            return professionals
        } catch let error as APIError {
            // Gérer spécifiquement l'erreur de décodage pour les réponses corrompues
            if case .decodingError(let underlyingError) = error,
               let nsError = underlyingError as NSError?,
               nsError.domain == NSCocoaErrorDomain,
               nsError.code == 3840 {
                print("[PartnersAPIService] Erreur de décodage JSON, retour d'un tableau vide")
                return []
            }
            throw error
        }
    }
    
    // MARK: - Search Professionals
    func searchProfessionals(
        city: String? = nil,
        category: OfferCategory? = nil,
        name: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Double? = nil,
        isClub10: Bool? = nil // Filtrer par Club 10 (true = uniquement Club 10, false = exclure Club 10, nil = tous)
    ) async throws -> [PartnerProfessionalResponse] {
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [PartnersAPIService] searchProfessionals() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        var parameters: [String: Any] = [:]
        
        if let city = city {
            parameters["city"] = city
            print("🔍 [PartnersAPIService] Paramètre city: \(city)")
        }
        
        if let category = category {
            parameters["category"] = category.rawValue
            print("🔍 [PartnersAPIService] Paramètre category: \(category.rawValue)")
        }
        
        if let name = name {
            parameters["name"] = name
            print("🔍 [PartnersAPIService] Paramètre name: \(name)")
        }
        
        // Paramètres pour la recherche par rayon (obligatoires ensemble)
        // Le backend attend le radius en MÈTRES, donc on convertit de km en mètres
        if let latitude = latitude, let longitude = longitude, let radius = radius {
            parameters["lat"] = latitude
            parameters["lon"] = longitude
            parameters["radius"] = radius * 1000.0 // Conversion km → mètres
            print("🔍 [PartnersAPIService] Paramètres géolocalisation: lat=\(latitude), lon=\(longitude), radius=\(radius * 1000.0)m")
        }
        
        // Paramètre pour filtrer par Club 10
        if let isClub10 = isClub10 {
            parameters["isClub10"] = isClub10
            print("🔍 [PartnersAPIService] ⭐ Paramètre isClub10: \(isClub10)")
        } else {
            print("🔍 [PartnersAPIService] Paramètre isClub10: nil (pas de filtre Club 10)")
        }
        
        print("🔍 [PartnersAPIService] Tous les paramètres: \(parameters)")
        
        do {
            let professionals: [PartnerProfessionalResponse] = try await apiService.request(
                endpoint: "/users/professionals/search",
                method: .get,
                parameters: parameters.isEmpty ? nil : parameters,
                headers: nil
            )
            
            print("🔍 [PartnersAPIService] ✅ Réponse reçue: \(professionals.count) partenaires")
            
            // Log détaillé pour chaque partenaire avec focus sur le rating
            for (index, professional) in professionals.enumerated() {
                print("═══════════════════════════════════════════════════════════")
                print("🔍 [PartnersAPIService] Partenaire \(index + 1):")
                print("   - ID: \(professional.id)")
                print("   - Nom: \(professional.firstName) \(professional.lastName)")
                print("   - Établissement: \(professional.establishmentName ?? "N/A")")
                print("   - isClub10 (décodé): \(professional.isClub10?.description ?? "nil")")
                print("   ⭐ RATING INFO:")
                print("      - averageRating (raw): \(professional.averageRating?.description ?? "nil")")
                print("      - averageRating (value): \(professional.averageRating ?? 0.0)")
                print("      - reviewCount (raw): \(professional.reviewCount?.description ?? "nil")")
                print("      - reviewCount (value): \(professional.reviewCount ?? 0)")
                if let rating = professional.averageRating {
                    print("      - ✅ Rating disponible: \(rating)")
                } else {
                    print("      - ❌ Rating non disponible (nil)")
                }
                if let count = professional.reviewCount {
                    print("      - ✅ ReviewCount disponible: \(count)")
                } else {
                    print("      - ❌ ReviewCount non disponible (nil)")
                }
                print("   - establishmentImageUrl (raw): \(professional.establishmentImageUrl ?? "nil")")
                print("═══════════════════════════════════════════════════════════")
            }
            
            print("═══════════════════════════════════════════════════════════")
            
            return professionals
        } catch let error as APIError {
            // Gérer spécifiquement l'erreur de décodage pour les réponses corrompues
            if case .decodingError(let underlyingError) = error,
               let nsError = underlyingError as NSError?,
               nsError.domain == NSCocoaErrorDomain,
               nsError.code == 3840 {
                print("[PartnersAPIService] Erreur de décodage JSON, retour d'un tableau vide")
                return []
            }
            throw error
        }
    }
    
    // MARK: - Get Professional By ID
    func getProfessionalById(id: Int) async throws -> PartnerProfessionalResponse {
        let professional: PartnerProfessionalResponse = try await apiService.request(
            endpoint: "/users/\(id)",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return professional
    }
}

// MARK: - Mapping Extension
extension PartnerProfessionalResponse {
    func toPartner() -> Partner {
        // Convertir l'ID Int en UUID
        let partnerUUID = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", id, id)) ?? UUID()
        
        // Construire le nom complet - utiliser establishmentName si disponible, sinon firstName + lastName
        let name: String
        if let establishmentName = establishmentName, !establishmentName.isEmpty {
            name = establishmentName
        } else {
            name = "\(firstName) \(lastName)"
        }
        
        // Déterminer la catégorie depuis le champ category
        let categoryName: String
        if let category = category {
            categoryName = category.displayName
        } else {
            categoryName = "Professionnel"
        }
        
        // Adresse complète
        let fullAddress = address ?? ""
        let partnerCity = city ?? ""
        let postalCode = "" // Pas disponible dans l'API, on peut extraire depuis l'adresse si nécessaire
        
        // Déterminer si c'est CLUB10 (utiliser le champ isClub10 depuis l'API)
        let isClub10Value = isClub10 ?? false
        
        // Déterminer l'image par défaut selon la catégorie
        let defaultImage: String
        if let category = category {
            defaultImage = DefaultImageHelper.defaultImageForOfferCategory(category)
        } else {
            defaultImage = DefaultImageHelper.defaultImageForPartnerCategory(categoryName)
        }
        
        // Construire l'URL complète de l'image d'établissement
        // Gère les URLs absolues (http/https) et les URLs relatives (/uploads/)
        let imageUrl: String? = ImageURLHelper.buildImageURL(from: establishmentImageUrl)
        
        // Debug: Log pour vérifier l'URL de l'image
        print("🖼️ [PartnersAPIService] Mapping Partner Image:")
        print("   - establishmentImageUrl (raw): \(establishmentImageUrl ?? "nil")")
        print("   - imageUrl (built): \(imageUrl ?? "nil")")
        print("   - Partner name: \(name)")
        
        // Log du mapping du rating avant création du Partner
        print("🔄 [PartnersAPIService] Mapping Partner - Rating:")
        print("   - averageRating (from API): \(averageRating?.description ?? "nil")")
        print("   - reviewCount (from API): \(reviewCount?.description ?? "nil")")
        print("   - rating (mapped): \(averageRating ?? 0.0)")
        print("   - reviewCount (mapped): \(reviewCount ?? 0)")
        print("   - Partner name: \(name)")
        
        // Créer un Partner avec les données disponibles
        return Partner(
            id: partnerUUID,
            name: name,
            category: categoryName,
            subCategory: subCategory, // Sous-catégorie depuis l'API (ex: "Coiffure", "Restaurant")
            address: fullAddress,
            city: partnerCity,
            postalCode: postalCode,
            phone: phoneNumber, // Utiliser phoneNumber depuis l'API
            email: email,
            website: website, // Utiliser website depuis l'API
            instagram: instagram, // Utiliser instagram depuis l'API
            description: establishmentDescription, // Utiliser establishmentDescription
            rating: averageRating ?? 0.0, // Note moyenne depuis le backend, 0.0 par défaut si non disponible
            reviewCount: reviewCount ?? 0, // Nombre d'avis depuis le backend, 0 par défaut si non disponible
            discount: isClub10Value ? 10 : nil, // Réduction UNIQUEMENT si isClub10 == true
            imageName: defaultImage,
            headerImageName: defaultImage,
            establishmentImageUrl: imageUrl, // URL absolue de l'image depuis le backend
            isFavorite: false, // Sera géré via l'API
            apiId: id, // Stocker l'ID original de l'API
            distanceMeters: distanceMeters // Distance en mètres depuis la position de l'utilisateur
        )
    }
}

