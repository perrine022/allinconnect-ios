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
        print("[BillingAPIService] Endpoint: POST /api/billing/subscription/start")
        
        // Vérifier que le token est présent
        if let token = AuthTokenManager.shared.getToken() {
            print("[BillingAPIService] ✅ Token présent: \(token.prefix(20))...")
        } else {
            print("[BillingAPIService] ⚠️ Token manquant")
        }
        
        do {
            // Utiliser l'endpoint sans /v1 car le backend attend /api/billing/...
            // On construit l'URL complète manuellement pour éviter le préfixe /v1
            // let baseURL = "https://allinconnect-back-1.onrender.com/api" // Production
            let baseURL = "http://127.0.0.1:8080/api" // Local
            let endpoint = "/billing/subscription/start"
            let fullURL = "\(baseURL)\(endpoint)"
            
            print("[BillingAPIService] URL complète: \(fullURL)")
            
            // Créer une requête manuelle pour ce cas spécifique
            guard let url = URL(string: fullURL) else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Ajouter le header Authorization avec un espace après "Bearer"
            if let token = AuthTokenManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("[BillingAPIService] Authorization header: Bearer \(token.prefix(20))...")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("[BillingAPIService] Status code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(StartSubscriptionResponse.self, from: data)
                print("[BillingAPIService] startSubscription() - Succès: customerId=\(decoded.customerId), subscriptionId=\(decoded.subscriptionId)")
                return decoded
            case 401:
                // Lire le message d'erreur précis du body
                var errorReason: String? = nil
                if !data.isEmpty {
                    if let errorDict = try? JSONDecoder().decode([String: String].self, from: data) {
                        errorReason = errorDict["message"] ?? errorDict["error"] ?? errorDict["reason"]
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        errorReason = errorString.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                print("[BillingAPIService] Erreur 401 - Raison: \(errorReason ?? "non spécifiée")")
                throw APIError.unauthorized(reason: errorReason)
            default:
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch let error as APIError {
            print("[BillingAPIService] startSubscription() - Erreur API: \(error.localizedDescription)")
            throw error
        } catch {
            print("[BillingAPIService] startSubscription() - Erreur: \(error.localizedDescription)")
            throw APIError.networkError(error)
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

