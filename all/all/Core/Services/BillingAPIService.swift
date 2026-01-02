//
//  BillingAPIService.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine

// MARK: - Payment Sheet Init Response
struct PaymentSheetInitResponse: Codable {
    let paymentIntentClientSecret: String
    let customerId: String
    let ephemeralKeySecret: String
    let publishableKey: String
    
    enum CodingKeys: String, CodingKey {
        case paymentIntentClientSecret = "paymentIntentClientSecret"
        case customerId = "customerId"
        case ephemeralKeySecret = "ephemeralKeySecret"
        case publishableKey = "publishableKey"
    }
}

// MARK: - Start Subscription Response (Legacy - pour compatibilité)
struct StartSubscriptionResponse: Codable {
    let customerId: String?
    let ephemeralKeySecret: String?
    let paymentIntentClientSecret: String?
    let subscriptionId: String?
    let status: String? // "active", "trialing", "incomplete", etc.
    let publishableKey: String? // Clé publique Stripe renvoyée par le backend
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customerId"
        case ephemeralKeySecret = "ephemeralKeySecret"
        case paymentIntentClientSecret = "paymentIntentClientSecret"
        case subscriptionId = "subscriptionId"
        case status = "status"
        case publishableKey = "publishableKey"
    }
}

// MARK: - Subscription Status Response
struct SubscriptionStatusResponse: Codable {
    let premiumEnabled: Bool
    let subscriptionStatus: String? // "ACTIVE", "PAST_DUE", "CANCELED", etc.
    let currentPeriodEnd: String?
    
    enum CodingKeys: String, CodingKey {
        case premiumEnabled = "premiumEnabled"
        case subscriptionStatus = "subscriptionStatus"
        case currentPeriodEnd = "currentPeriodEnd"
    }
}

// MARK: - Subscription Payment Sheet Response
/// Réponse standardisée pour le Payment Sheet d'abonnement
/// Format standardisé : customerId (pas customer) pour cohérence avec le reste de l'API
struct SubscriptionPaymentSheetResponse: Codable {
    let paymentIntent: String // client_secret complet du PaymentIntent (format: "pi_123_secret_abc")
    let customerId: String // ID du customer Stripe (format: "cus_...")
    let ephemeralKey: String // ephemeralKeySecret (format: "ek_...")
    let publishableKey: String // publishableKey (format: "pk_...")
    let subscriptionId: String? // ID de la subscription créée (format: "sub_...")
    
    enum CodingKeys: String, CodingKey {
        case paymentIntent = "paymentIntent"
        case customerId = "customerId" // Standardisé : customerId partout
        case ephemeralKey = "ephemeralKey"
        case publishableKey = "publishableKey"
        case subscriptionId = "subscriptionId"
    }
}

// MARK: - Portal Response
struct PortalResponse: Codable {
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case url
    }
}

// MARK: - Billing API Service
@MainActor
class BillingAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        print("[BillingAPIService] init() - Début")
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
        print("[BillingAPIService] init() - Fin")
    }
    
    // MARK: - Create Subscription Payment Sheet
    /// Crée une Subscription Stripe en statut default_incomplete et renvoie le client_secret du PaymentIntent de la première invoice
    /// Endpoint: POST /api/billing/subscription/payment-sheet
    /// Body: {"priceId": "price_123..."}
    /// Response: SubscriptionPaymentSheetResponse (identique à PaymentSheetInitResponse mais avec subscriptionId)
    func createSubscriptionPaymentSheet(priceId: String) async throws -> SubscriptionPaymentSheetResponse {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] createSubscriptionPaymentSheet() - Début")
        print("═══════════════════════════════════════════════════════════")
        // Note: L'endpoint backend est /api/billing/subscription/payment-sheet (sans /v1)
        // APIConfig.baseURL contient déjà /api/v1, donc on utilise directement /billing/...
        // Si le backend est sur /api/billing/... (sans v1), il faudra ajuster
        print("💳 [BILLING] Endpoint: POST \(APIConfig.baseURL)/billing/subscription/payment-sheet")
        print("💳 [BILLING] ⚠️ Vérifier que le backend mapping correspond à cet endpoint")
        print("💳 [BILLING] priceId: \(priceId)")
        print("💳 [BILLING] Note: Le backend crée une Subscription Stripe avec default_incomplete")
        print("💳 [BILLING] Note: Le backend expand latest_invoice.payment_intent pour récupérer le client_secret")
        
        let requestBody: [String: Any] = [
            "priceId": priceId
        ]
        
        print("💳 [BILLING] Body JSON: \(requestBody)")
        
        do {
            let startTime = Date()
            let response: SubscriptionPaymentSheetResponse = try await apiService.request(
                endpoint: "/billing/subscription/payment-sheet",
                method: .post,
                parameters: requestBody,
                headers: nil
            )
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [BILLING] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
            print("💳 [BILLING]   - paymentIntent (client_secret): \(response.paymentIntent.prefix(30))...")
            print("💳 [BILLING]     Format vérifié: \(response.paymentIntent.contains("_secret_") ? "✅ Format complet (pi_xxx_secret_xxx)" : "⚠️ Format incomplet")")
            print("💳 [BILLING]   - customerId: \(response.customerId)")
            print("💳 [BILLING]   - ephemeralKey: \(response.ephemeralKey.prefix(30))...")
            print("💳 [BILLING]   - publishableKey: \(response.publishableKey.prefix(30))...")
            print("💳 [BILLING]   - subscriptionId: \(response.subscriptionId ?? "nil")")
            print("═══════════════════════════════════════════════════════════")
            return response
        } catch {
            print("═══════════════════════════════════════════════════════════")
            print("💳 [BILLING] ❌ Erreur: \(error.localizedDescription)")
            print("═══════════════════════════════════════════════════════════")
            throw error
        }
    }
    
    // MARK: - Get Subscription Status
    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        print("[BillingAPIService] getSubscriptionStatus() - Début")
        print("[BillingAPIService] Endpoint: GET /api/billing/subscription/status")
        do {
            let response: SubscriptionStatusResponse = try await apiService.request(
                endpoint: "/billing/subscription/status",
                method: .get,
                parameters: nil,
                headers: nil
            )
            print("[BillingAPIService] getSubscriptionStatus() - Succès: premiumEnabled=\(response.premiumEnabled)")
            return response
        } catch {
            print("[BillingAPIService] getSubscriptionStatus() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Create Portal Session
    func createPortalSession() async throws -> PortalResponse {
        print("[BillingAPIService] createPortalSession() - Début")
        print("[BillingAPIService] Endpoint: POST /api/billing/portal")
        do {
            let response: PortalResponse = try await apiService.request(
                endpoint: "/billing/portal",
                method: .post,
                parameters: nil,
                headers: nil
            )
            print("[BillingAPIService] createPortalSession() - Succès: url=\(response.url)")
            return response
        } catch {
            print("[BillingAPIService] createPortalSession() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
}

