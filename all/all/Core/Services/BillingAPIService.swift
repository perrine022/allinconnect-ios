//
//  BillingAPIService.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine

// MARK: - Start Subscription Response
struct StartSubscriptionResponse: Codable {
    let customerId: String
    let ephemeralKeySecret: String
    let paymentIntentClientSecret: String
    let subscriptionId: String
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customerId"
        case ephemeralKeySecret = "ephemeralKeySecret"
        case paymentIntentClientSecret = "paymentIntentClientSecret"
        case subscriptionId = "subscriptionId"
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
    
    // MARK: - Start Subscription
    func startSubscription() async throws -> StartSubscriptionResponse {
        print("[BillingAPIService] startSubscription() - Début")
        do {
            let response: StartSubscriptionResponse = try await apiService.request(
                endpoint: "/billing/subscription/start",
                method: .post,
                parameters: nil,
                headers: nil
            )
            print("[BillingAPIService] startSubscription() - Succès: customerId=\(response.customerId), subscriptionId=\(response.subscriptionId)")
            return response
        } catch {
            print("[BillingAPIService] startSubscription() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Subscription Status
    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        print("[BillingAPIService] getSubscriptionStatus() - Début")
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

