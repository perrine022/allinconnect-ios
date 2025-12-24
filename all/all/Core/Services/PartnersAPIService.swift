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
    let hasConnectedBefore: Bool?
    let referralCode: String?
    let subscriptionPlan: SubscriptionPlanResponse?
    
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
        case hasConnectedBefore = "hasConnectedBefore"
        case referralCode = "referralCode"
        case subscriptionPlan = "subscriptionPlan"
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
        let professionals: [PartnerProfessionalResponse] = try await apiService.request(
            endpoint: "/users/professionals",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return professionals
    }
    
    // MARK: - Get Professionals By City
    func getProfessionalsByCity(city: String) async throws -> [PartnerProfessionalResponse] {
        let parameters: [String: Any] = [
            "city": city
        ]
        
        let professionals: [PartnerProfessionalResponse] = try await apiService.request(
            endpoint: "/users/professionals/by-city",
            method: .get,
            parameters: parameters,
            headers: nil
        )
        return professionals
    }
    
    // MARK: - Search Professionals
    func searchProfessionals(
        city: String? = nil,
        category: OfferCategory? = nil,
        name: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radius: Double? = nil
    ) async throws -> [PartnerProfessionalResponse] {
        var parameters: [String: Any] = [:]
        
        if let city = city {
            parameters["city"] = city
        }
        
        if let category = category {
            parameters["category"] = category.rawValue
        }
        
        if let name = name {
            parameters["name"] = name
        }
        
        // Paramètres pour la recherche par rayon (obligatoires ensemble)
        if let latitude = latitude, let longitude = longitude, let radius = radius {
            parameters["lat"] = latitude
            parameters["lon"] = longitude
            parameters["radius"] = radius
        }
        
        let professionals: [PartnerProfessionalResponse] = try await apiService.request(
            endpoint: "/users/professionals/search",
            method: .get,
            parameters: parameters.isEmpty ? nil : parameters,
            headers: nil
        )
        return professionals
    }
}

// MARK: - Mapping Extension
extension PartnerProfessionalResponse {
    func toPartner() -> Partner {
        // Convertir l'ID Int en UUID
        let partnerUUID = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", id, id)) ?? UUID()
        
        // Construire le nom complet
        let name = "\(firstName) \(lastName)"
        
        // Déterminer la catégorie depuis le champ category ou profession
        let categoryName: String
        if let category = category {
            categoryName = category.displayName
        } else if let profession = profession {
            categoryName = profession
        } else {
            categoryName = "Professionnel"
        }
        
        // Adresse complète
        let fullAddress = address ?? ""
        let partnerCity = city ?? ""
        let postalCode = "" // Pas disponible dans l'API, on peut extraire depuis l'adresse si nécessaire
        
        // Déterminer si c'est CLUB10 (basé sur subscriptionType PREMIUM)
        let isClub10 = subscriptionType == "PREMIUM"
        
        // Créer un Partner avec les données disponibles
        return Partner(
            id: partnerUUID,
            name: name,
            category: categoryName,
            address: fullAddress,
            city: partnerCity,
            postalCode: postalCode,
            phone: nil, // Pas disponible dans l'API
            email: email,
            website: nil, // Pas disponible dans l'API
            instagram: nil, // Pas disponible dans l'API
            description: profession, // Utiliser la profession comme description
            rating: 4.5, // Par défaut, peut être récupéré depuis un autre endpoint
            reviewCount: 0, // Par défaut, peut être récupéré depuis un autre endpoint
            discount: isClub10 ? 10 : nil, // Réduction si CLUB10
            imageName: "person.circle.fill", // Par défaut
            headerImageName: "person.circle.fill", // Par défaut
            isFavorite: false, // Sera géré via l'API
            apiId: id // Stocker l'ID original de l'API
        )
    }
}

