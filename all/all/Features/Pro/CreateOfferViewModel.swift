//
//  CreateOfferViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class CreateOfferViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var validUntil: String = ""
    @Published var discount: String = ""
    @Published var offerType: OfferType = .offer
    @Published var isClub10: Bool = false
    @Published var imageName: String = "tag.fill"
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !validUntil.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func publishOffer() -> Offer {
        // Pour l'instant, on simule la publication
        // Plus tard, on appellera l'API pour créer l'offre
        // L'offre sera créée avec le partnerId de l'utilisateur connecté
        
        // Créer une nouvelle offre
        let newOffer = Offer(
            title: title,
            description: description,
            businessName: "Mon entreprise", // Plus tard, récupérer depuis le profil du pro
            validUntil: validUntil,
            discount: discount,
            imageName: imageName,
            offerType: offerType,
            isClub10: isClub10,
            partnerId: nil // Plus tard, récupérer l'ID du partenaire connecté
        )
        
        return newOffer
    }
}

