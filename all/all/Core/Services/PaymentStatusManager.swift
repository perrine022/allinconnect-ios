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
    
    // Vérifier le statut du paiement via l'API
    func checkPaymentStatus() async {
        pendingPaymentCheck = true
        
        do {
            let subscriptionsService = SubscriptionsAPIService()
            let userLight = try await ProfileAPIService().getUserLight()
            
            // Si la carte est maintenant active, le paiement a réussi
            if userLight.isCardActive == true {
                lastPaymentStatus = .success
                NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            } else {
                // Vérifier les paiements récents
                let payments = try await subscriptionsService.getMyPayments()
                if let lastPayment = payments.first,
                   let status = lastPayment.status?.uppercased() {
                    switch status {
                    case "SUCCESS", "COMPLETED", "PAID":
                        lastPaymentStatus = .success
                        NotificationCenter.default.post(name: NSNotification.Name("PaymentSuccess"), object: nil)
                    case "FAILED", "CANCELLED", "REFUNDED":
                        lastPaymentStatus = .failed
                        NotificationCenter.default.post(name: NSNotification.Name("PaymentFailed"), object: nil)
                    default:
                        lastPaymentStatus = .pending
                    }
                } else {
                    lastPaymentStatus = .pending
                }
            }
        } catch {
            print("Erreur lors de la vérification du statut du paiement: \(error)")
            lastPaymentStatus = .pending
        }
        
        pendingPaymentCheck = false
    }
}

