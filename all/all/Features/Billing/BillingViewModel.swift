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
    // TODO: À réimplémenter selon les nouvelles spécifications backend
    func startSubscription() async throws -> StartSubscriptionResponse {
        print("[BillingViewModel] ⚠️ startSubscription() - À implémenter")
        isLoading = false
        errorMessage = "Fonctionnalité de paiement en cours de développement"
        throw APIError.invalidResponse
    }
    
    // MARK: - Handle Payment Success
    func handlePaymentSuccess() async {
        print("[BillingViewModel] handlePaymentSuccess() - Début")
        // Recharger le statut depuis le backend
        await loadSubscriptionStatus()
        
        if premiumEnabled {
            successMessage = "Abonnement activé avec succès !"
        }
        print("[BillingViewModel] handlePaymentSuccess() - Fin")
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

