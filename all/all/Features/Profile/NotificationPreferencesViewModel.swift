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
    
    // Distance pour les offres et événements locaux (en km)
    @Published var notificationRadius: Double = 10.0 // Par défaut 10km
    let radiusOptions: [Double] = [5, 10, 15, 20, 25, 30, 50]
    
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

