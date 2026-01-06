//
//  DefaultImageHelper.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

/// Helper pour obtenir des images par défaut selon la catégorie/spécialité
struct DefaultImageHelper {
    
    /// Retourne une image par défaut pour une catégorie d'offre
    static func defaultImageForOfferCategory(_ category: OfferCategory?) -> String {
        guard let category = category else {
            return "tag.fill"
        }
        
        switch category {
        case .santeBienEtre:
            return "figure.strengthtraining.traditional" // Sport/Santé
        case .beauteEsthetique:
            return "sparkles" // Beauté
        case .foodPlaisirs:
            return "fork.knife" // Food
        case .loisirsDivertissements:
            return "gamecontroller.fill" // Loisirs
        case .servicePratiques:
            return "wrench.and.screwdriver.fill" // Services
        case .entrePros:
            return "briefcase.fill" // Entre pros
        }
    }
    
    /// Retourne une image par défaut pour une catégorie de partenaire (string)
    static func defaultImageForPartnerCategory(_ category: String) -> String {
        let categoryLower = category.lowercased()
        
        // Mapping basé sur les mots-clés dans la catégorie
        if categoryLower.contains("sport") || categoryLower.contains("santé") || categoryLower.contains("sante") || categoryLower.contains("bien être") || categoryLower.contains("bien-etre") || categoryLower.contains("fitness") || categoryLower.contains("gym") {
            return "figure.strengthtraining.traditional"
        } else if categoryLower.contains("beauté") || categoryLower.contains("beaute") || categoryLower.contains("esthétique") || categoryLower.contains("esthetique") || categoryLower.contains("spa") || categoryLower.contains("coiffure") {
            return "sparkles"
        } else if categoryLower.contains("food") || categoryLower.contains("restaurant") || categoryLower.contains("gourmand") || categoryLower.contains("boulangerie") || categoryLower.contains("café") || categoryLower.contains("cafe") {
            return "fork.knife"
        } else if categoryLower.contains("loisir") || categoryLower.contains("divertissement") || categoryLower.contains("jeu") || categoryLower.contains("cinéma") || categoryLower.contains("cinema") || categoryLower.contains("théâtre") || categoryLower.contains("theatre") {
            return "gamecontroller.fill"
        } else if categoryLower.contains("service") || categoryLower.contains("pratique") || categoryLower.contains("réparation") || categoryLower.contains("reparation") || categoryLower.contains("plomberie") || categoryLower.contains("électricité") || categoryLower.contains("electricite") {
            return "wrench.and.screwdriver.fill"
        } else if categoryLower.contains("pro") || categoryLower.contains("professionnel") || categoryLower.contains("entreprise") || categoryLower.contains("business") {
            return "briefcase.fill"
        } else {
            // Par défaut
            return "person.circle.fill"
        }
    }
    
    /// Retourne une image par défaut pour une catégorie d'offre (string)
    static func defaultImageForOfferCategoryString(_ category: String?) -> String {
        guard let category = category else {
            return "tag.fill"
        }
        
        // Essayer de mapper vers OfferCategory
        if let offerCategory = OfferCategory.allCases.first(where: { $0.displayName.lowercased() == category.lowercased() }) {
            return defaultImageForOfferCategory(offerCategory)
        }
        
        // Sinon utiliser le mapping par mots-clés
        return defaultImageForPartnerCategory(category)
    }
}










