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
    
    // Catégories (mêmes que sur la homepage)
    @Published var santeBienEtre: Bool = true
    @Published var beauteEsthetique: Bool = true
    @Published var foodPlaisirsGourmands: Bool = true
    @Published var loisirsDivertissements: Bool = true
    @Published var servicePratiques: Bool = true
    @Published var entrePros: Bool = true
    
    // État de chargement et erreurs
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Services
    private let notificationPreferencesAPIService: NotificationPreferencesAPIService
    private let profileAPIService: ProfileAPIService
    
    // Mapping des catégories avec les valeurs backend
    let categories: [(key: String, backendValue: String, title: String, emoji: String)] = [
        ("santeBienEtre", "SANTE_BIEN_ETRE", "Santé & bien être", "💪"),
        ("beauteEsthetique", "BEAUTE_ESTHETIQUE", "Beauté & Esthétique", "💅"),
        ("foodPlaisirsGourmands", "FOOD_PLAISIRS", "Food & plaisirs gourmands", "🍔"),
        ("loisirsDivertissements", "LOISIRS_DIVERTISSEMENTS", "Loisirs & Divertissements", "🎮"),
        ("servicePratiques", "SERVICE_PRATIQUES", "Service & pratiques", "🔧"),
        ("entrePros", "ENTRE_PROS", "Entre pros", "👔")
    ]
    
    init(
        notificationPreferencesAPIService: NotificationPreferencesAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil
    ) {
        self.notificationPreferencesAPIService = notificationPreferencesAPIService ?? NotificationPreferencesAPIService()
        self.profileAPIService = profileAPIService ?? ProfileAPIService()
    }
    
    /// Charge les préférences depuis l'API ou depuis UserLightResponse
    func loadPreferences(from userLight: UserLightResponse? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Si on a déjà les préférences dans userLight, les utiliser
                if let preferences = userLight?.notificationPreference {
                    applyPreferences(preferences)
                    isLoading = false
                    return
                }
                
                // Sinon, charger depuis l'API
                let preferences = try await notificationPreferencesAPIService.getNotificationPreferences()
                applyPreferences(preferences)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des préférences"
                print("Erreur lors du chargement des préférences: \(error)")
            }
        }
    }
    
    /// Applique les préférences chargées aux propriétés du ViewModel
    private func applyPreferences(_ preferences: NotificationPreferencesResponse) {
        newOffers = preferences.notifyNewOffers
        newIndependent = preferences.notifyNewProNearby
        localEvents = preferences.notifyLocalEvents
        notificationRadius = Double(preferences.notificationRadius)
        
        // Réinitialiser toutes les catégories à false
        santeBienEtre = false
        beauteEsthetique = false
        foodPlaisirsGourmands = false
        loisirsDivertissements = false
        servicePratiques = false
        entrePros = false
        
        // Activer les catégories préférées
        for category in preferences.preferredCategories {
            switch category {
            case "SANTE_BIEN_ETRE":
                santeBienEtre = true
            case "BEAUTE_ESTHETIQUE":
                beauteEsthetique = true
            case "FOOD_PLAISIRS":
                foodPlaisirsGourmands = true
            case "LOISIRS_DIVERTISSEMENTS":
                loisirsDivertissements = true
            case "SERVICE_PRATIQUES":
                servicePratiques = true
            case "ENTRE_PROS":
                entrePros = true
            default:
                break
            }
        }
    }
    
    /// Sauvegarde les préférences sur le backend
    func savePreferences() {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // Construire la liste des catégories préférées
                var preferredCategories: [String] = []
                if santeBienEtre { preferredCategories.append("SANTE_BIEN_ETRE") }
                if beauteEsthetique { preferredCategories.append("BEAUTE_ESTHETIQUE") }
                if foodPlaisirsGourmands { preferredCategories.append("FOOD_PLAISIRS") }
                if loisirsDivertissements { preferredCategories.append("LOISIRS_DIVERTISSEMENTS") }
                if servicePratiques { preferredCategories.append("SERVICE_PRATIQUES") }
                if entrePros { preferredCategories.append("ENTRE_PROS") }
                
                let request = NotificationPreferencesRequest(
                    notifyNewOffers: newOffers,
                    notifyNewProNearby: newIndependent,
                    notifyLocalEvents: localEvents,
                    notificationRadius: Int(notificationRadius),
                    preferredCategories: preferredCategories
                )
                
                try await notificationPreferencesAPIService.updateNotificationPreferences(request)
                
                isSaving = false
                successMessage = "Préférences sauvegardées avec succès"
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                isSaving = false
                errorMessage = "Erreur lors de la sauvegarde des préférences"
                print("Erreur lors de la sauvegarde des préférences: \(error)")
            }
        }
    }
}

