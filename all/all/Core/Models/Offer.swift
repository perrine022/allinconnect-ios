//
//  Offer.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

enum OfferType: String {
    case offer = "Offre"
    case event = "Event"
}

struct Offer: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let businessName: String
    let validUntil: String
    let discount: String
    let imageName: String
    let offerType: OfferType
    let isClub10: Bool
    let partnerId: UUID?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        businessName: String,
        validUntil: String,
        discount: String,
        imageName: String,
        offerType: OfferType = .offer,
        isClub10: Bool = false,
        partnerId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.businessName = businessName
        self.validUntil = validUntil
        self.discount = discount
        self.imageName = imageName
        self.offerType = offerType
        self.isClub10 = isClub10
        self.partnerId = partnerId
    }
}

