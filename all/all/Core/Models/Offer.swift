//
//  Offer.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

enum OfferType: String, Codable {
    case offer = "Offre"
    case event = "Event"
}

struct Offer: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let businessName: String
    let validUntil: String
    let startDate: String? // Date de début au format DD/MM/YYYY
    let discount: String
    let imageName: String
    let imageUrl: String? // URL de l'image depuis le backend (chemin relatif)
    let offerType: OfferType
    let isClub10: Bool
    let partnerId: UUID?
    let apiId: Int? // ID original de l'API pour pouvoir recharger les détails
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        businessName: String,
        validUntil: String,
        startDate: String? = nil,
        discount: String,
        imageName: String,
        imageUrl: String? = nil,
        offerType: OfferType = .offer,
        isClub10: Bool = false,
        partnerId: UUID? = nil,
        apiId: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.businessName = businessName
        self.validUntil = validUntil
        self.startDate = startDate
        self.discount = discount
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.offerType = offerType
        self.isClub10 = isClub10
        self.partnerId = partnerId
        self.apiId = apiId
    }
    
    /// Retourne l'URL complète de l'image
    /// Le backend renvoie maintenant des URLs absolues directement
    func fullImageUrl() -> String? {
        guard let imageUrl = imageUrl, !imageUrl.isEmpty else {
            return nil
        }
        
        // Si l'URL commence déjà par "http", c'est une URL absolue, on l'utilise directement
        if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
            return imageUrl
        }
        
        // Sinon, construire l'URL complète (fallback pour compatibilité)
        let baseURL = APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        let path = imageUrl.hasPrefix("/") ? imageUrl : "/\(imageUrl)"
        return "\(baseURL)\(path)"
    }
    
    // Fonction utilitaire pour extraire l'ID API depuis l'UUID si possible
    func extractApiId() -> Int? {
        if let apiId = apiId {
            return apiId
        }
        // Essayer d'extraire depuis l'UUID si généré avec le format standard
        let uuidString = id.uuidString
        // Format: XXXXXXXX-0000-0000-0000-XXXXXXXXXXXX
        // On peut extraire les 8 premiers caractères hex
        if uuidString.count >= 8 {
            let hexString = String(uuidString.prefix(8))
            return Int(hexString, radix: 16)
        }
        return nil
    }
}

