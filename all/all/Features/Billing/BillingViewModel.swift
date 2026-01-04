//
//  BillingViewModel.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class BillingViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var premiumEnabled: Bool = false
    @Published var subscriptionStatus: String? // "ACTIVE", "PAST_DUE", "CANCELED", etc.
    @Published var currentPeriodEnd: Date?
    
    // Cache optionnel (la source de vérité reste le backend)
    private let premiumCacheKey = "premium_enabled_cache"
    
    private let billingAPIService: BillingAPIService
    
    init(billingAPIService: BillingAPIService? = nil) {
        print("[BillingViewModel] init() - Début")
        if let billingAPIService = billingAPIService {
            self.billingAPIService = billingAPIService
        } else {
            self.billingAPIService = BillingAPIService()
        }
        
        // Charger le cache optionnel au démarrage
        loadPremiumCache()
        
        // Charger le statut depuis le backend
        Task {
            await loadSubscriptionStatus()
        }
        print("[BillingViewModel] init() - Fin")
    }
    
    // MARK: - Load Subscription Status
    func loadSubscriptionStatus() async {
        print("[BillingViewModel] loadSubscriptionStatus() - Début")
        isLoading = true
        errorMessage = nil
        
        do {
            let status = try await billingAPIService.getSubscriptionStatus()
            premiumEnabled = status.premiumEnabled
            subscriptionStatus = status.subscriptionStatus
            
            // Parser la date de fin de période
            if let periodEndString = status.currentPeriodEnd {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
                currentPeriodEnd = formatter.date(from: periodEndString)
            }
            
            // Mettre à jour le cache
            savePremiumCache(status.premiumEnabled)
            
            isLoading = false
            print("[BillingViewModel] loadSubscriptionStatus() - Succès: premiumEnabled=\(status.premiumEnabled), status=\(status.subscriptionStatus ?? "nil")")
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement du statut: \(error.localizedDescription)"
            print("[BillingViewModel] loadSubscriptionStatus() - Erreur: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Start Subscription
    /// Démarre le processus d'abonnement en appelant le backend pour créer le PaymentSheet
    /// Retourne les données nécessaires pour afficher le PaymentSheet Stripe
    func startSubscription(priceId: String) async throws -> SubscriptionPaymentSheetResponse {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] startSubscription() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Appeler le backend pour créer la subscription et récupérer le PaymentSheet
            let response = try await billingAPIService.createSubscriptionPaymentSheet(priceId: priceId)
            
            isLoading = false
            print("💳 [BILLING] startSubscription() - Succès")
            print("   - subscriptionId: \(response.subscriptionId ?? "nil")")
            print("   - customerId: \(response.customerId)")
            print("   - intentType: \(response.intentType ?? "auto-détecté")")
            
            return response
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de l'initialisation du paiement: \(error.localizedDescription)"
            print("💳 [BILLING] startSubscription() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Handle Payment Success
    /// Appelée après que le PaymentSheet renvoie .completed
    /// Selon le guide : Appeler GET /api/v1/payment/status/{paymentIntentId} pour forcer la synchronisation
    func handlePaymentSuccess(paymentIntentClientSecret: String?) async {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] handlePaymentSuccess() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        // Étape 1 : Extraire le paymentIntentId du clientSecret
        // Format: "pi_xxx_secret_xxx" -> extraire "pi_xxx"
        var paymentIntentId: String? = nil
        if let clientSecret = paymentIntentClientSecret {
            if let secretIndex = clientSecret.range(of: "_secret_") {
                // Extraire tout ce qui est avant "_secret_"
                paymentIntentId = String(clientSecret[..<secretIndex.lowerBound])
            } else if clientSecret.hasPrefix("pi_") {
                // Si pas de "_secret_", prendre les premiers caractères jusqu'à un certain point
                let components = clientSecret.components(separatedBy: "_")
                if components.count >= 2 {
                    paymentIntentId = "\(components[0])_\(components[1])"
                }
            } else if clientSecret.hasPrefix("seti_") {
                // Pour setup_intent, on peut aussi extraire l'ID de la même manière
                if let secretIndex = clientSecret.range(of: "_secret_") {
                    paymentIntentId = String(clientSecret[..<secretIndex.lowerBound])
                }
            }
            
            if let id = paymentIntentId {
                print("💳 [BILLING] PaymentIntentId extrait: \(id)")
            } else {
                print("💳 [BILLING] ⚠️ Impossible d'extraire le paymentIntentId du clientSecret")
            }
        }
        
        // Étape 2 : Appeler GET /api/v1/payment/status/{paymentIntentId} pour forcer la synchronisation
        // Selon le guide : "Cet appel déclenche l'activation manuelle du mode Premium sur le backend si Stripe confirme le succès"
        if let paymentIntentId = paymentIntentId {
            print("💳 [BILLING] Appel GET /api/v1/payment/status/\(paymentIntentId) pour forcer la synchronisation...")
            let paymentAPIService = PaymentAPIService()
            do {
                let statusResponse = try await paymentAPIService.getPaymentStatus(paymentIntentId: paymentIntentId)
                print("💳 [BILLING] ✅ Statut du paiement: \(statusResponse.status)")
            } catch {
                print("💳 [BILLING] ⚠️ Erreur lors de la vérification du statut: \(error.localizedDescription)")
                // On continue quand même, le webhook peut avoir déjà traité
            }
        }
        
        // Étape 3 : Attendre un court délai pour que le webhook Stripe soit traité
        print("💳 [BILLING] ⏳ Attente de 1 seconde pour laisser le webhook Stripe traiter le paiement...")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Étape 4 : Rafraîchir le profil utilisateur via GET /api/v1/users/me
        // Selon la checklist : "Une fois que Stripe renvoie .completed, l'app doit rafraîchir le profil"
        // "Le profil renvoie maintenant un objet card (de type CardDTO) et un subscriptionStatus"
        // "Si subscriptionStatus == 'ACTIVE', c'est gagné !"
        print("💳 [BILLING] Rafraîchissement du profil utilisateur via GET /api/v1/users/me...")
        let profileAPIService = ProfileAPIService()
        var subscriptionActive = false
        
        // Faire quelques tentatives pour laisser le webhook se traiter (max 3 tentatives)
        for attempt in 0..<3 {
            do {
                let userMe = try await profileAPIService.getUserMe()
                print("💳 [BILLING] ✅ Profil utilisateur récupéré (tentative \(attempt + 1)/3)")
                print("   - premiumEnabled: \(userMe.premiumEnabled?.description ?? "nil")")
                print("   - subscriptionType: \(userMe.subscriptionType ?? "nil")")
                print("   - card: \(userMe.card != nil ? "présent" : "nil")")
                
                // Vérifier si premiumEnabled == true (le backend met à jour ce champ via webhook)
                // Note: subscriptionStatus est vérifié via loadSubscriptionStatus() qui appelle /billing/subscription/status
                if userMe.premiumEnabled == true {
                    subscriptionActive = true
                    print("💳 [BILLING] ✅ premiumEnabled == true - Premium activé !")
                    break
                } else {
                    print("💳 [BILLING] ⏳ Tentative \(attempt + 1)/3 : subscriptionStatus pas encore ACTIVE, attente...")
                    if attempt < 2 {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes entre chaque tentative
                    }
                }
            } catch {
                print("💳 [BILLING] ⚠️ Erreur lors du rafraîchissement du profil (tentative \(attempt + 1)/3): \(error.localizedDescription)")
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes entre chaque tentative
                }
            }
        }
        
        // Étape 5 : Recharger aussi le statut de l'abonnement via l'endpoint dédié
        print("💳 [BILLING] Rechargement du statut de l'abonnement via GET /billing/subscription/status...")
        await loadSubscriptionStatus()
        
        if subscriptionActive || premiumEnabled {
            successMessage = "Abonnement activé avec succès !"
            print("💳 [BILLING] ✅ Premium activé avec succès")
        } else {
            print("💳 [BILLING] ⚠️ Premium pas encore activé, le webhook peut être en cours de traitement")
            print("💳 [BILLING] 💡 L'utilisateur peut rafraîchir manuellement ou attendre quelques secondes")
        }
        
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] handlePaymentSuccess() - Fin")
        print("═══════════════════════════════════════════════════════════")
    }
    
    // MARK: - Create Portal Session
    func createPortalSession() async throws -> URL {
        print("[BillingViewModel] createPortalSession() - Début")
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await billingAPIService.createPortalSession()
            guard let url = URL(string: response.url) else {
                throw APIError.invalidResponse
            }
            isLoading = false
            print("[BillingViewModel] createPortalSession() - Succès: url=\(response.url)")
            return url
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de la création de la session: \(error.localizedDescription)"
            print("[BillingViewModel] createPortalSession() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Cache Management (optionnel)
    private func loadPremiumCache() {
        premiumEnabled = UserDefaults.standard.bool(forKey: premiumCacheKey)
    }
    
    private func savePremiumCache(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: premiumCacheKey)
    }
}

