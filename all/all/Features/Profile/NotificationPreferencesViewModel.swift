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
    @Published var newOffers: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] newOffers changé: \(oldValue) → \(newOffers)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var newIndependent: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] newIndependent changé: \(oldValue) → \(newIndependent)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var localEvents: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] localEvents changé: \(oldValue) → \(localEvents)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    
    // Distance pour les offres et événements locaux (en km)
    @Published var notificationRadius: Double = 15.0 {
        didSet {
            print("🔔 [VIEWMODEL] notificationRadius changé: \(Int(oldValue)) km → \(Int(notificationRadius)) km")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    
    // Catégories (mêmes que sur la homepage)
    @Published var santeBienEtre: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] santeBienEtre changé: \(oldValue) → \(santeBienEtre)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var beauteEsthetique: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] beauteEsthetique changé: \(oldValue) → \(beauteEsthetique)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var foodPlaisirsGourmands: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] foodPlaisirsGourmands changé: \(oldValue) → \(foodPlaisirsGourmands)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var loisirsDivertissements: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] loisirsDivertissements changé: \(oldValue) → \(loisirsDivertissements)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var servicePratiques: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] servicePratiques changé: \(oldValue) → \(servicePratiques)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    @Published var entrePros: Bool = true {
        didSet {
            print("🔔 [VIEWMODEL] entrePros changé: \(oldValue) → \(entrePros)")
            if !isApplyingPreferences {
                autoSavePreferences()
            }
        }
    }
    
    // État de chargement et erreurs
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Services
    private let notificationPreferencesAPIService: NotificationPreferencesAPIService
    private let profileAPIService: ProfileAPIService
    
    // Flag pour éviter les appels pendant le chargement initial
    private var isApplyingPreferences = false
    private var saveTask: Task<Void, Never>?
    
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
                print("═══════════════════════════════════════════════════════════")
                print("🔔 [NOTIFICATIONS] DÉBUT Chargement des préférences")
                print("═══════════════════════════════════════════════════════════")
                
                // Si on a déjà les préférences dans userLight, les utiliser
                if let preferences = userLight?.notificationPreference {
                    print("🔔 [NOTIFICATIONS] Préférences trouvées dans userLight")
                    print("   - notifyNewOffers: \(preferences.notifyNewOffers)")
                    print("   - notifyNewProNearby: \(preferences.notifyNewProNearby)")
                    print("   - notifyLocalEvents: \(preferences.notifyLocalEvents)")
                    print("   - notificationRadius: \(preferences.notificationRadius)")
                    print("   - preferredCategories: \(preferences.preferredCategories)")
                    applyPreferences(preferences)
                    isLoading = false
                    print("🔔 [NOTIFICATIONS] ✅ Préférences appliquées depuis userLight")
                    print("═══════════════════════════════════════════════════════════")
                    return
                }
                
                // Sinon, charger depuis l'API
                print("🔔 [NOTIFICATIONS] Chargement depuis l'API...")
                print("   Endpoint: GET /api/v1/notification-preferences")
                let preferences = try await notificationPreferencesAPIService.getNotificationPreferences()
                print("🔔 [NOTIFICATIONS] ✅ Préférences récupérées depuis l'API:")
                print("   - notifyNewOffers: \(preferences.notifyNewOffers)")
                print("   - notifyNewProNearby: \(preferences.notifyNewProNearby)")
                print("   - notifyLocalEvents: \(preferences.notifyLocalEvents)")
                print("   - notificationRadius: \(preferences.notificationRadius)")
                print("   - preferredCategories: \(preferences.preferredCategories)")
                applyPreferences(preferences)
                isLoading = false
                print("🔔 [NOTIFICATIONS] ✅ Préférences appliquées depuis l'API")
                print("═══════════════════════════════════════════════════════════")
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des préférences"
                print("🔔 [NOTIFICATIONS] ❌ ERREUR lors du chargement")
                print("   Type: \(type(of: error))")
                print("   Message: \(error.localizedDescription)")
                if let apiError = error as? APIError {
                    print("   Détails APIError: \(apiError)")
                }
                print("═══════════════════════════════════════════════════════════")
            }
        }
    }
    
    /// Applique les préférences chargées aux propriétés du ViewModel
    private func applyPreferences(_ preferences: NotificationPreferencesResponse) {
        // Désactiver les appels automatiques pendant l'application des préférences
        isApplyingPreferences = true
        defer { isApplyingPreferences = false }
        
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
    
    /// Sauvegarde automatique avec debounce pour éviter trop d'appels
    private func autoSavePreferences() {
        // Annuler la tâche précédente si elle existe
        saveTask?.cancel()
        
        // Créer une nouvelle tâche avec un délai de 300ms (debounce)
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            // Vérifier que la tâche n'a pas été annulée
            guard !Task.isCancelled else { return }
            
            // Appeler la sauvegarde
            savePreferences()
        }
    }
    
    /// Sauvegarde les préférences sur le backend
    /// - Parameter showSuccessMessage: Si true, affiche un message de succès (par défaut false pour les sauvegardes automatiques)
    func savePreferences(showSuccessMessage: Bool = false) {
        // Ne pas sauvegarder si on est déjà en train de sauvegarder
        guard !isSaving else {
            print("🔔 [NOTIFICATIONS] ⚠️ Sauvegarde déjà en cours, ignoré")
            return
        }
        
        isSaving = true
        if !showSuccessMessage {
            // Ne pas effacer les messages existants pour les sauvegardes automatiques
        } else {
            errorMessage = nil
            successMessage = nil
        }
        
        Task {
            do {
                print("═══════════════════════════════════════════════════════════")
                print("🔔 [NOTIFICATIONS] DÉBUT Sauvegarde des préférences")
                print("═══════════════════════════════════════════════════════════")
                
                // Construire la liste des catégories préférées
                var preferredCategories: [String] = []
                if santeBienEtre { preferredCategories.append("SANTE_BIEN_ETRE") }
                if beauteEsthetique { preferredCategories.append("BEAUTE_ESTHETIQUE") }
                if foodPlaisirsGourmands { preferredCategories.append("FOOD_PLAISIRS") }
                if loisirsDivertissements { preferredCategories.append("LOISIRS_DIVERTISSEMENTS") }
                if servicePratiques { preferredCategories.append("SERVICE_PRATIQUES") }
                if entrePros { preferredCategories.append("ENTRE_PROS") }
                
                print("🔔 [NOTIFICATIONS] État des toggles:")
                print("   - Nouvelles offres: \(newOffers)")
                print("   - Nouvel indépendant: \(newIndependent)")
                print("   - Événements locaux: \(localEvents)")
                print("   - Rayon: \(Int(notificationRadius)) km")
                print("   - Catégories sélectionnées: \(preferredCategories)")
                
                let request = NotificationPreferencesRequest(
                    notifyNewOffers: newOffers,
                    notifyNewProNearby: newIndependent,
                    notifyLocalEvents: localEvents,
                    notificationRadius: Int(notificationRadius),
                    preferredCategories: preferredCategories
                )
                
                print("🔔 [NOTIFICATIONS] Envoi au backend...")
                print("   Endpoint: PUT /api/v1/notification-preferences")
                print("   BaseURL: \(APIConfig.baseURL)")
                print("   Payload:")
                print("   {")
                print("     \"notifyNewOffers\": \(request.notifyNewOffers),")
                print("     \"notifyNewProNearby\": \(request.notifyNewProNearby),")
                print("     \"notifyLocalEvents\": \(request.notifyLocalEvents),")
                print("     \"notificationRadius\": \(request.notificationRadius),")
                print("     \"preferredCategories\": \(request.preferredCategories)")
                print("   }")
                
                try await notificationPreferencesAPIService.updateNotificationPreferences(request)
                
                print("🔔 [NOTIFICATIONS] ✅ Préférences sauvegardées avec succès")
                print("═══════════════════════════════════════════════════════════")
                
                isSaving = false
                
                // Afficher le message de succès seulement si demandé
                if showSuccessMessage {
                    successMessage = "Préférences sauvegardées avec succès"
                    // Effacer le message de succès après 3 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = nil
                    }
                }
            } catch {
                isSaving = false
                errorMessage = "Erreur lors de la sauvegarde des préférences"
                print("🔔 [NOTIFICATIONS] ❌ ERREUR lors de la sauvegarde")
                print("   Type: \(type(of: error))")
                print("   Message: \(error.localizedDescription)")
                if let apiError = error as? APIError {
                    print("   Détails APIError: \(apiError)")
                }
                print("═══════════════════════════════════════════════════════════")
            }
        }
    }
}

