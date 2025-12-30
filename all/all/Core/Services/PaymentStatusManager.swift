//
//  PaymentStatusManager.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class PaymentStatusManager: ObservableObject {
    static let shared = PaymentStatusManager()
    
    @Published var pendingPaymentCheck: Bool = false
    @Published var lastPaymentStatus: PaymentResultStatus?
    
    enum PaymentResultStatus {
        case success
        case failed
        case pending
    }
    
    private init() {}
    
    // Vérifier le statut du paiement via l'API (Étape C)
    // Après la fermeture du Payment Sheet, vérifier le statut premium avec retry et backoff exponentiel
    // Source de vérité : GET /api/billing/status (pas /users/me/light)
    func checkPaymentStatus(maxRetries: Int = 7) async -> Bool {
        pendingPaymentCheck = true
        defer { pendingPaymentCheck = false }
        
        let billingAPIService = BillingAPIService()
        
        // Backoff exponentiel : 0.5s, 1s, 2s, 3s, 5s, 8s (total ~19.5s max)
        let delays: [UInt64] = [500_000_000, 1_000_000_000, 2_000_000_000, 3_000_000_000, 5_000_000_000, 8_000_000_000]
        
        // Première tentative après délai initial de 0.5s
        for attempt in 0...maxRetries {
            do {
                // Appeler GET /api/billing/status (endpoint dédié, source de vérité backend)
                let statusResponse = try await billingAPIService.getSubscriptionStatus()
                
                // Vérifier si le statut premium est activé (source de vérité backend)
                if statusResponse.premiumEnabled {
                    // Le statut est à jour, le paiement a réussi
                    lastPaymentStatus = .success
                    NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                    print("[PaymentStatusManager] ✅ Statut premium confirmé après \(attempt + 1) tentative(s)")
                    print("[PaymentStatusManager]   - premiumEnabled: \(statusResponse.premiumEnabled)")
                    print("[PaymentStatusManager]   - subscriptionStatus: \(statusResponse.subscriptionStatus ?? "N/A")")
                    return true
                } else {
                    // Le statut n'est pas encore à jour
                    if attempt < maxRetries {
                        // Backoff exponentiel : 0.5s, 1s, 2s, 3s, 5s, 8s
                        let delayIndex = min(attempt, delays.count - 1)
                        let delay = delays[delayIndex]
                        let delaySeconds = Double(delay) / 1_000_000_000.0
                        
                        print("[PaymentStatusManager] ⏳ Statut pas encore à jour (premiumEnabled=\(statusResponse.premiumEnabled)), attente \(Int(delaySeconds))s avant retry \(attempt + 2)/\(maxRetries + 1)...")
                        try await Task.sleep(nanoseconds: delay)
                    } else {
                        // Dernière tentative échouée
                        print("[PaymentStatusManager] ⚠️ Statut premium non confirmé après \(maxRetries + 1) tentatives")
                        print("[PaymentStatusManager]   - premiumEnabled: \(statusResponse.premiumEnabled)")
                        print("[PaymentStatusManager]   - subscriptionStatus: \(statusResponse.subscriptionStatus ?? "N/A")")
                        lastPaymentStatus = .pending
                        return false
                    }
                }
            } catch {
                print("[PaymentStatusManager] ❌ Erreur lors de la vérification du statut (tentative \(attempt + 1)): \(error)")
                if attempt < maxRetries {
                    // Backoff exponentiel en cas d'erreur aussi
                    let delayIndex = min(attempt, delays.count - 1)
                    let delay = delays[delayIndex]
                    let delaySeconds = Double(delay) / 1_000_000_000.0
                    print("[PaymentStatusManager] ⏳ Erreur, attente \(Int(delaySeconds))s avant retry...")
                    try? await Task.sleep(nanoseconds: delay)
                } else {
                    lastPaymentStatus = .pending
                    return false
                }
            }
        }
        
        return false
    }
}

