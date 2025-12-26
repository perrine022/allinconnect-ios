//
//  SubscriptionsAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Subscription Plan Response
struct SubscriptionPlanResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let price: Double
    let category: String? // "PROFESSIONAL", "INDIVIDUAL", ou "FAMILY"
    let duration: String? // "MONTHLY" ou "ANNUAL"
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case category
        case duration
    }
    
    // Helper pour formater le prix
    var formattedPrice: String {
        String(format: "%.2f€", price)
    }
    
    // Helper pour obtenir le label de prix avec durée
    var priceLabel: String {
        if let duration = duration {
            switch duration {
            case "MONTHLY":
                return "\(formattedPrice) / mois"
            case "ANNUAL":
                return "\(formattedPrice) / an"
            default:
                return formattedPrice
            }
        }
        return formattedPrice
    }
    
    // Helper pour vérifier si c'est un plan annuel
    var isAnnual: Bool {
        duration == "ANNUAL"
    }
    
    // Helper pour vérifier si c'est un plan mensuel
    var isMonthly: Bool {
        duration == "MONTHLY"
    }
}

// MARK: - Family Card Emails Response
struct FamilyCardEmailsResponse: Codable {
    let cardId: Int
    let ownerEmail: String
    let emails: [String] // Les 4 emails de la famille (peut être moins de 4)
    let isOwner: Bool // Si l'utilisateur connecté est le propriétaire
    
    enum CodingKeys: String, CodingKey {
        case cardId = "cardId"
        case ownerEmail = "ownerEmail"
        case emails
        case isOwner = "isOwner"
    }
}

// MARK: - Update Family Card Emails Request
struct UpdateFamilyCardEmailsRequest: Codable {
    let emails: [String] // Les 4 emails (peut être moins de 4)
    
    enum CodingKeys: String, CodingKey {
        case emails
    }
}

// MARK: - Subscriptions API Service
@MainActor
class SubscriptionsAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        // Utiliser le service fourni ou créer une nouvelle instance
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            // Accéder à shared dans un contexte MainActor
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Get Available Plans
    func getPlans() async throws -> [SubscriptionPlanResponse] {
        let plans: [SubscriptionPlanResponse] = try await apiService.request(
            endpoint: "/subscriptions/plans",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return plans
    }
    
    // MARK: - Subscribe to a Plan
    func subscribe(planId: Int) async throws {
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/subscriptions/subscribe/\(planId)",
            method: .post,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Get My Payments
    func getMyPayments() async throws -> [PaymentResponse] {
        let payments: [PaymentResponse] = try await apiService.request(
            endpoint: "/subscriptions/my-payments",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return payments
    }
    
    // MARK: - Get Family Card Emails
    func getFamilyCardEmails() async throws -> FamilyCardEmailsResponse {
        return try await apiService.request(
            endpoint: "/cards/family/emails",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Update Family Card Emails
    func updateFamilyCardEmails(_ request: UpdateFamilyCardEmailsRequest) async throws {
        // Encoder la requête en JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/cards/family/emails",
            method: .put,
            parameters: parameters,
            headers: nil
        )
    }
    
    // MARK: - Get Stripe Payment Link (deprecated - utiliser createPaymentIntent à la place)
    func getStripePaymentLink(planId: Int) async throws -> String {
        struct PaymentLinkResponse: Codable {
            let paymentLinkUrl: String
            
            enum CodingKeys: String, CodingKey {
                case paymentLinkUrl = "paymentLinkUrl"
            }
        }
        
        let response: PaymentLinkResponse = try await apiService.request(
            endpoint: "/subscriptions/payment-link/\(planId)",
            method: .get,
            parameters: nil,
            headers: nil
        )
        
        return response.paymentLinkUrl
    }
    
    // MARK: - Create Payment Intent for Stripe Payment Sheet
    func createPaymentIntent(planId: Int) async throws -> PaymentIntentResponse {
        struct PaymentIntentRequest: Codable {
            let planId: Int
            
            enum CodingKeys: String, CodingKey {
                case planId = "planId"
            }
        }
        
        let request = PaymentIntentRequest(planId: planId)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let response: PaymentIntentResponse = try await apiService.request(
            endpoint: "/subscriptions/create-payment-intent",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        return response
    }
}

// MARK: - Payment Intent Response
struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let amount: Double
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case clientSecret = "clientSecret"
        case amount
        case currency
    }
}

