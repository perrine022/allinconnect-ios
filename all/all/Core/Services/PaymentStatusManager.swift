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
    // Après la fermeture du Payment Sheet, vérifier le statut premium avec retry
    func checkPaymentStatus(maxRetries: Int = 2) async -> Bool {
        pendingPaymentCheck = true
        defer { pendingPaymentCheck = false }
        
        let profileAPIService = ProfileAPIService()
        
        // Première tentative immédiate
        for attempt in 0...maxRetries {
            do {
                // Appeler GET /api/v1/users/me/light
                let userLight = try await profileAPIService.getUserLight()
                
                // Vérifier si le statut premium est à jour (isMember ou isCardActive)
                let isPremium = userLight.isMember == true || userLight.isCardActive == true
                
                if isPremium {
                    // Le statut est à jour, le paiement a réussi
                    lastPaymentStatus = .success
                    NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                    print("[PaymentStatusManager] ✅ Statut premium confirmé après \(attempt + 1) tentative(s)")
                    return true
                } else {
                    // Le statut n'est pas encore à jour
                    if attempt < maxRetries {
                        // Attendre 1 seconde avant de réessayer
                        print("[PaymentStatusManager] ⏳ Statut pas encore à jour, attente 1 seconde avant retry \(attempt + 2)/\(maxRetries + 1)...")
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                    } else {
                        // Dernière tentative échouée
                        print("[PaymentStatusManager] ⚠️ Statut premium non confirmé après \(maxRetries + 1) tentatives")
                        lastPaymentStatus = .pending
                        return false
                    }
                }
            } catch {
                print("[PaymentStatusManager] ❌ Erreur lors de la vérification du statut (tentative \(attempt + 1)): \(error)")
                if attempt < maxRetries {
                    // Attendre 1 seconde avant de réessayer en cas d'erreur
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                } else {
                    lastPaymentStatus = .pending
                    return false
                }
            }
        }
        
        return false
    }
}

