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
    // Après la fermeture du Payment Sheet, rafraîchir simplement les données utilisateur
    // Le backend a déjà tout mis à jour via le webhook Stripe
    // Source de vérité : GET /api/v1/users/me
    // Option A (simple) : Un appel après un court délai pour laisser le webhook se traiter
    func checkPaymentStatus(maxRetries: Int = 3) async -> Bool {
        pendingPaymentCheck = true
        defer { pendingPaymentCheck = false }
        
        let profileAPIService = ProfileAPIService()
        
        // Option A simple : Attendre un court délai puis appeler une fois
        // Si le réseau est lent, on peut faire quelques retries (max 3 tentatives, 2 secondes entre chaque)
        let delayBetweenAttempts: UInt64 = 2_000_000_000 // 2 secondes
        
        for attempt in 0..<maxRetries {
            do {
                // Appeler GET /api/v1/users/me pour rafraîchir les données
                // Le backend a déjà tout mis à jour (subscriptionType, renewalDate, etc.)
                print("🔍 [STATUS] ───────────────────────────────────────────────────")
                print("🔍 [STATUS] Tentative \(attempt + 1)/\(maxRetries) : Vérification du statut premium")
                print("🔍 [STATUS] Appel GET /api/v1/users/me...")
                let startTime = Date()
                
                let userMe = try await profileAPIService.getUserMe()
                
                let duration = Date().timeIntervalSince(startTime)
                print("🔍 [STATUS] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
                print("🔍 [STATUS] Données utilisateur:")
                print("   - premiumEnabled: \(userMe.premiumEnabled?.description ?? "nil")")
                print("   - subscriptionType: \(userMe.subscriptionType ?? "nil")")
                print("   - userId: \(userMe.id?.description ?? "nil")")
                
                // Vérifier si le statut premium est activé
                // Le backend a déjà mis à jour tous les champs (subscriptionType, renewalDate, etc.)
                let isPremium = userMe.premiumEnabled == true
                
                if isPremium {
                    // Le statut est confirmé, le paiement a réussi
                    lastPaymentStatus = .success
                    // Note: Le prix du plan sera passé depuis StripePaymentView si disponible
                    NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                    print("🔍 [STATUS] ───────────────────────────────────────────────────")
                    print("✅ [STATUS] Statut premium CONFIRMÉ après \(attempt + 1) tentative(s)")
                    print("   - premiumEnabled: \(userMe.premiumEnabled ?? false)")
                    print("   - subscriptionType: \(userMe.subscriptionType ?? "N/A")")
                    print("🔍 [STATUS] ───────────────────────────────────────────────────")
                    return true
                } else {
                    // Le statut n'est pas encore activé (webhook peut prendre quelques millisecondes)
                    if attempt < maxRetries - 1 {
                        // Attendre 2 secondes avant le prochain essai (polling simple si réseau lent)
                        print("⏳ [STATUS] Statut premium pas encore activé")
                        print("   - premiumEnabled: \(userMe.premiumEnabled?.description ?? "nil")")
                        print("   - subscriptionType: \(userMe.subscriptionType ?? "nil")")
                        print("   ⏳ Attente de 2 secondes avant retry \(attempt + 2)/\(maxRetries)...")
                        print("   → Le webhook Stripe peut prendre quelques secondes")
                        try await Task.sleep(nanoseconds: delayBetweenAttempts)
                    } else {
                        // Dernière tentative échouée
                        print("🔍 [STATUS] ───────────────────────────────────────────────────")
                        print("⚠️ [STATUS] Statut premium NON CONFIRMÉ après \(maxRetries) tentatives")
                        print("   - premiumEnabled: \(userMe.premiumEnabled ?? false)")
                        print("   - subscriptionType: \(userMe.subscriptionType ?? "N/A")")
                        print("   → Le webhook peut prendre plus de temps, vérification manuelle recommandée")
                        print("🔍 [STATUS] ───────────────────────────────────────────────────")
                        lastPaymentStatus = .pending
                        return false
                    }
                }
            } catch {
                print("🔍 [STATUS] ───────────────────────────────────────────────────")
                print("❌ [STATUS] Erreur lors de la vérification (tentative \(attempt + 1)/\(maxRetries))")
                print("   - Type: \(type(of: error))")
                print("   - Message: \(error.localizedDescription)")
                if attempt < maxRetries - 1 {
                    // Attendre 2 secondes avant le prochain essai en cas d'erreur
                    print("   ⏳ Attente de 2 secondes avant retry...")
                    try? await Task.sleep(nanoseconds: delayBetweenAttempts)
                } else {
                    print("   ❌ Toutes les tentatives ont échoué")
                    print("🔍 [STATUS] ───────────────────────────────────────────────────")
                    lastPaymentStatus = .pending
                    return false
                }
            }
        }
        
        return false
    }
}

