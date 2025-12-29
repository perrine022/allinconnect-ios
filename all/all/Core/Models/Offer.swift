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
        self.offerType = offerType
        self.isClub10 = isClub10
        self.partnerId = partnerId
        self.apiId = apiId
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

