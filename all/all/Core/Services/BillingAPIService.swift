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
    
    // MARK: - Payment Sheet Initialization
    // TODO: À implémenter selon les nouvelles spécifications backend
    // Endpoint: POST /api/stripe/paymentsheet/init
    // Body: {"planId": 3}
    // Response: PaymentSheetInitResponse
    
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

