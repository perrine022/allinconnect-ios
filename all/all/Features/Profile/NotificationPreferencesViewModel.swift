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
    
    // Catégories
    @Published var sportHealth: Bool = true
    @Published var aesthetics: Bool = true
    @Published var entertainment: Bool = true
    @Published var food: Bool = true
    
    func savePreferences() {
        // Sauvegarder les préférences
    }
}

