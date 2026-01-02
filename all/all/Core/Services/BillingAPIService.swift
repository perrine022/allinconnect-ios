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
        
        // 1. URL appelée (endpoint exact)
        let endpoint = "/billing/subscription/payment-sheet"
        let fullURL = "\(APIConfig.baseURL)\(endpoint)"
        print("💳 [BILLING] 📍 URL appelée (endpoint exact):")
        print("   Endpoint: \(endpoint)")
        print("   URL complète: \(fullURL)")
        print("   Méthode: POST")
        
        // 2. Payload (priceId)
        let requestBody: [String: Any] = [
            "priceId": priceId
        ]
        print("💳 [BILLING] 📦 Payload envoyé:")
        print("   priceId: \(priceId)")
        print("   Body JSON: \(requestBody)")
        
        print("💳 [BILLING] Note: Le backend crée une Subscription Stripe avec default_incomplete")
        print("💳 [BILLING] Note: Le backend expand latest_invoice.payment_intent pour récupérer le client_secret")
        
        do {
            let startTime = Date()
            let response: SubscriptionPaymentSheetResponse = try await apiService.request(
                endpoint: endpoint,
                method: .post,
                parameters: requestBody,
                headers: nil
            )
            let duration = Date().timeIntervalSince(startTime)
            
            // 3. Réponse reçue (en masquant les secrets)
            print("💳 [BILLING] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
            print("💳 [BILLING] 📥 Réponse reçue (secrets masqués):")
            
            // Masquer les secrets (afficher seulement les préfixes et quelques caractères)
            let paymentIntentMasked = response.paymentIntent.count > 20 
                ? "\(response.paymentIntent.prefix(10))...\(response.paymentIntent.suffix(10))" 
                : "\(response.paymentIntent.prefix(10))..."
            let ephemeralKeyMasked = response.ephemeralKey.count > 20 
                ? "\(response.ephemeralKey.prefix(10))...\(response.ephemeralKey.suffix(10))" 
                : "\(response.ephemeralKey.prefix(10))..."
            let publishableKeyMasked = response.publishableKey.count > 20 
                ? "\(response.publishableKey.prefix(10))...\(response.publishableKey.suffix(10))" 
                : "\(response.publishableKey.prefix(10))..."
            
            print("   - paymentIntent: \(paymentIntentMasked) (longueur: \(response.paymentIntent.count) caractères)")
            print("   - customerId: \(response.customerId)")
            print("   - ephemeralKey: \(ephemeralKeyMasked) (longueur: \(response.ephemeralKey.count) caractères)")
            print("   - publishableKey: \(publishableKeyMasked) (longueur: \(response.publishableKey.count) caractères)")
            print("   - subscriptionId: \(response.subscriptionId ?? "nil")")
            
            // 4. Vérification des préfixes
            print("💳 [BILLING] 🔍 Vérification des préfixes:")
            
            // paymentIntent doit commencer par "pi_" et contenir "_secret_"
            let paymentIntentValid = response.paymentIntent.hasPrefix("pi_") && response.paymentIntent.contains("_secret_")
            print("   - paymentIntent:")
            print("     • startsWith \"pi_\": \(response.paymentIntent.hasPrefix("pi_") ? "✅" : "❌")")
            print("     • contains \"_secret_\": \(response.paymentIntent.contains("_secret_") ? "✅" : "❌")")
            if !paymentIntentValid {
                print("     ⚠️ ATTENTION: Format paymentIntent invalide - PaymentSheet ne fonctionnera pas")
                print("     ⚠️ Format attendu: pi_xxx_secret_xxx")
                print("     ⚠️ Format reçu: \(response.paymentIntent)")
            } else {
                print("     ✅ Format paymentIntent valide")
            }
            
            // customerId doit commencer par "cus_"
            let customerIdValid = response.customerId.hasPrefix("cus_")
            print("   - customerId:")
            print("     • startsWith \"cus_\": \(customerIdValid ? "✅" : "❌")")
            if !customerIdValid {
                print("     ⚠️ ATTENTION: Format customerId invalide")
                print("     ⚠️ Format attendu: cus_xxx")
                print("     ⚠️ Format reçu: \(response.customerId)")
            } else {
                print("     ✅ Format customerId valide")
            }
            
            // ephemeralKey doit commencer par "ek_"
            let ephemeralKeyValid = response.ephemeralKey.hasPrefix("ek_")
            print("   - ephemeralKey:")
            print("     • startsWith \"ek_\": \(ephemeralKeyValid ? "✅" : "❌")")
            if !ephemeralKeyValid {
                print("     ⚠️ ATTENTION: Format ephemeralKey invalide")
                print("     ⚠️ Format attendu: ek_xxx")
                print("     ⚠️ Format reçu: \(response.ephemeralKey)")
            } else {
                print("     ✅ Format ephemeralKey valide")
            }
            
            // Résumé de validation
            if paymentIntentValid && customerIdValid && ephemeralKeyValid {
                print("💳 [BILLING] ✅ Tous les formats sont valides - PaymentSheet peut être affiché")
            } else {
                print("💳 [BILLING] ❌ Certains formats sont invalides - PaymentSheet risque de ne pas fonctionner")
            }
            
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

