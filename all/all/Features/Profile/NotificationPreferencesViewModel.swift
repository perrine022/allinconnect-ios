//
//  NotificationPreferencesViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    // Notifications générales
    @Published var newOffers: Bool = true
    @Published var newIndependent: Bool = true
    @Published var localEvents: Bool = true
    @Published var localizedOffers: Bool = true // Nouvelles offres selon la localisation
    
    // Catégories (mêmes que sur la homepage)
    @Published var santeBienEtre: Bool = true
    @Published var beauteEsthetique: Bool = true
    @Published var foodPlaisirsGourmands: Bool = true
    @Published var loisirsDivertissements: Bool = true
    @Published var servicePratiques: Bool = true
    @Published var entrePros: Bool = true
    
    // Mapping des catégories
    let categories: [(key: String, title: String, emoji: String)] = [
        ("santeBienEtre", "Santé & bien être", "💪"),
        ("beauteEsthetique", "Beauté & Esthétique", "💅"),
        ("foodPlaisirsGourmands", "Food & plaisirs gourmands", "🍔"),
        ("loisirsDivertissements", "Loisirs & Divertissements", "🎮"),
        ("servicePratiques", "Service & pratiques", "🔧"),
        ("entrePros", "Entre pros", "👔")
    ]
    
    func savePreferences() {
        // Sauvegarder les préférences
    }
}

