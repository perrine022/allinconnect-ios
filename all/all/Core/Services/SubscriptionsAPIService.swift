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
    let stripePriceId: String? // ID Stripe du price (ex: "price_123...")
    let stripeProductId: String? // ID Stripe du product (optionnel)
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case category
        case duration
        case stripePriceId = "stripePriceId"
        case stripeProductId = "stripeProductId"
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

// MARK: - Card Members Response (nouvel endpoint)
struct CardMembersResponse: Codable {
    let activeMembers: [CardMember]
    let pendingInvitations: [String]
    
    enum CodingKeys: String, CodingKey {
        case activeMembers = "activeMembers"
        case pendingInvitations = "pendingInvitations"
    }
}

// MARK: - Card Owner Response
struct CardOwnerResponse: Codable {
    let isOwner: Bool
    
    enum CodingKeys: String, CodingKey {
        case isOwner = "isOwner"
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
    // Récupère tous les plans de paiement configurés (Titre, Prix, Description, Catégorie, Durée)
    // Endpoint: GET /api/v1/subscriptions/plans
    // Les plans doivent être filtrés côté front selon le type d'utilisateur :
    // - INDIVIDUAL et FAMILY pour les clients
    // - PROFESSIONAL pour les professionnels
    /// Récupère la liste des plans d'abonnement disponibles
    /// Endpoint public : Ne nécessite pas de token valide (même avec un token expiré, l'endpoint fonctionne)
    func getPlans() async throws -> [SubscriptionPlanResponse] {
        print("[SubscriptionsAPIService] 📞 Appel GET /api/v1/subscriptions/plans (endpoint public)")
        do {
            let plans: [SubscriptionPlanResponse] = try await apiService.request(
                endpoint: "/subscriptions/plans",
                method: .get,
                parameters: nil,
                headers: nil
            )
            print("[SubscriptionsAPIService] ✅ Plans récupérés: \(plans.count) plans")
            for plan in plans {
                print("[SubscriptionsAPIService]   - \(plan.title): \(plan.formattedPrice) (category: \(plan.category ?? "N/A"), duration: \(plan.duration ?? "N/A"))")
            }
            return plans
        } catch let apiError as APIError {
            // Si on reçoit une 401 sur cet endpoint public, c'est anormal mais on log quand même
            // Le backend ne devrait plus retourner 401 pour cet endpoint, mais on gère toutes les erreurs
            if case .unauthorized = apiError {
                print("[SubscriptionsAPIService] ⚠️ Erreur 401 sur endpoint public (anormal mais géré)")
            }
            throw apiError
        } catch {
            print("[SubscriptionsAPIService] ❌ Erreur lors de la récupération des plans: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Client Plans
    /// Récupère les plans d'abonnement pour les clients (INDIVIDUAL et FAMILY)
    /// Endpoint: GET /api/v1/subscriptions/client
    func getClientPlans() async throws -> [SubscriptionPlanResponse] {
        print("[SubscriptionsAPIService] 📞 Appel GET /api/v1/subscriptions/client")
        do {
            let plans: [SubscriptionPlanResponse] = try await apiService.request(
                endpoint: "/subscriptions/client",
                method: .get,
                parameters: nil,
                headers: nil
            )
            print("[SubscriptionsAPIService] ✅ Plans client récupérés: \(plans.count) plans")
            for plan in plans {
                print("[SubscriptionsAPIService]   - \(plan.title): \(plan.formattedPrice) (category: \(plan.category ?? "N/A"), duration: \(plan.duration ?? "N/A"))")
            }
            return plans
        } catch {
            print("[SubscriptionsAPIService] ❌ Erreur lors de la récupération des plans client: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Pro Plans
    /// Récupère les plans d'abonnement pour les professionnels (PROFESSIONAL)
    /// Endpoint: GET /api/v1/subscriptions/pro
    func getProPlans() async throws -> [SubscriptionPlanResponse] {
        print("[SubscriptionsAPIService] 📞 Appel GET /api/v1/subscriptions/pro")
        do {
            let plans: [SubscriptionPlanResponse] = try await apiService.request(
                endpoint: "/subscriptions/pro",
                method: .get,
                parameters: nil,
                headers: nil
            )
            print("[SubscriptionsAPIService] ✅ Plans pro récupérés: \(plans.count) plans")
            for plan in plans {
                print("[SubscriptionsAPIService]   - \(plan.title): \(plan.formattedPrice) (category: \(plan.category ?? "N/A"), duration: \(plan.duration ?? "N/A"))")
            }
            return plans
        } catch {
            print("[SubscriptionsAPIService] ❌ Erreur lors de la récupération des plans pro: \(error)")
            throw error
        }
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
    
    // MARK: - Invite Family Member
    // Note: Le backend accepte cet endpoint même avec un token invalide/expiré (fallback utilisateur test)
    func inviteFamilyMember(email: String) async throws {
        print("[SubscriptionsAPIService] Inviting family member with email: \(email)")
        
        // Vérifier si le token est présent (pour les logs uniquement)
        // Le backend gère maintenant le fallback si le token est invalide/expiré
        if let token = AuthTokenManager.shared.getToken(), !token.isEmpty {
            print("[SubscriptionsAPIService] ✅ Token présent: \(token.prefix(20))...")
        } else {
            print("[SubscriptionsAPIService] ⚠️ Token manquant ou vide - Le backend utilisera un utilisateur de test")
        }
        
        // Endpoint correct : POST /api/v1/subscriptions/invite
        // Format du body requis : {"email": "test@gmail.com"}
        struct InviteRequest: Codable {
            let email: String
        }
        
        let request = InviteRequest(email: email)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("[SubscriptionsAPIService] ERROR: Failed to encode invite request")
            throw APIError.invalidResponse
        }
        
        print("[SubscriptionsAPIService] Endpoint: POST /api/v1/cards/invite")
        print("[SubscriptionsAPIService] Request payload: \(parameters)")
        print("[SubscriptionsAPIService] Content-Type: application/json (géré automatiquement)")
        
        // Le header Authorization sera envoyé automatiquement si le token existe
        // Sinon, le backend utilisera un utilisateur de test en fallback
        
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/cards/invite",
            method: .post,
            parameters: parameters,
            headers: nil // Les headers par défaut (incluant Authorization si disponible) sont ajoutés automatiquement
        )
        
        print("[SubscriptionsAPIService] ✅ Successfully invited family member: \(email)")
    }
    
    // MARK: - Remove Family Member (nouveau endpoint)
    func removeFamilyMember(memberId: Int? = nil, email: String? = nil) async throws {
        print("[SubscriptionsAPIService] Removing family member - memberId: \(memberId?.description ?? "nil"), email: \(email ?? "nil")")
        
        guard memberId != nil || email != nil else {
            print("[SubscriptionsAPIService] ERROR: Either memberId or email must be provided")
            throw APIError.invalidResponse
        }
        
        struct RemoveMemberRequest: Codable {
            let memberId: Int?
            let email: String?
            
            enum CodingKeys: String, CodingKey {
                case memberId
                case email
            }
        }
        
        // Construire le payload selon les spécifications du backend
        // Le backend attend soit {"memberId": 12} soit {"email": "email@example.com"}
        var parameters: [String: Any] = [:]
        
        if let memberId = memberId {
            parameters["memberId"] = memberId
        } else if let email = email {
            parameters["email"] = email
        }
        
        print("[SubscriptionsAPIService] Request payload: \(parameters)")
        
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/cards/remove-member",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        print("[SubscriptionsAPIService] Successfully removed family member")
    }
    
    // MARK: - Get Card Members (nouvel endpoint avec noms complets)
    func getCardMembers() async throws -> CardMembersResponse {
        return try await apiService.request(
            endpoint: "/cards/members",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Get Card Owner
    func getCardOwner() async throws -> CardOwnerResponse {
        print("[SubscriptionsAPIService] Fetching card owner information")
        let response: CardOwnerResponse = try await apiService.request(
            endpoint: "/cards/owner",
            method: .get,
            parameters: nil,
            headers: nil
        )
        print("[SubscriptionsAPIService] Card owner: \(response.isOwner ? "User is owner" : "User is not owner")")
        return response
    }
    
    // MARK: - Get Family Card Emails (deprecated - utiliser getUserLight à la place)
    func getFamilyCardEmails() async throws -> FamilyCardEmailsResponse {
        return try await apiService.request(
            endpoint: "/cards/family/emails",
            method: .get,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Update Family Card Emails (deprecated - utiliser inviteFamilyMember à la place)
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
    // Note: Le backend accepte cet endpoint même avec un token invalide/expiré (fallback utilisateur test)
    func createPaymentIntent(planId: Int) async throws -> PaymentIntentResponse {
        print("[SubscriptionsAPIService] 🔄 Création du Payment Intent pour planId=\(planId)")
        
        // Vérifier si le token est présent (pour les logs uniquement)
        // Le backend gère maintenant le fallback si le token est invalide/expiré
        if let token = AuthTokenManager.shared.getToken(), !token.isEmpty {
            print("[SubscriptionsAPIService] ✅ Token présent: \(token.prefix(20))...")
        } else {
            print("[SubscriptionsAPIService] ⚠️ Token manquant ou vide - Le backend utilisera un utilisateur de test")
        }
        
        // Vérifier l'URL complète
        let fullURL = "\(APIConfig.baseURL)/subscriptions/create-payment-intent"
        print("[SubscriptionsAPIService] 📍 URL complète: POST \(fullURL)")
        
        // Préparer le body JSON avec planId (format requis: {"planId": 3})
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
            print("[SubscriptionsAPIService] ❌ ERREUR: Échec de l'encodage du body JSON")
            throw APIError.invalidResponse
        }
        
        // Vérifier le format du body
        print("[SubscriptionsAPIService] 📦 Body JSON: \(parameters)")
        print("[SubscriptionsAPIService] 📋 Content-Type: application/json (géré automatiquement)")
        
        // Le header Authorization sera envoyé automatiquement si le token existe
        // Sinon, le backend utilisera un utilisateur de test en fallback
        
        // Faire l'appel API
        do {
            let response: PaymentIntentResponse = try await apiService.request(
                endpoint: "/subscriptions/create-payment-intent",
                method: .post,
                parameters: parameters,
                headers: nil // Les headers par défaut (incluant Authorization si disponible) sont ajoutés automatiquement
            )
            
            print("[SubscriptionsAPIService] ✅ Payment Intent créé avec succès")
            print("[SubscriptionsAPIService]   - clientSecret: \(response.clientSecret.prefix(20))...")
            print("[SubscriptionsAPIService]   - amount: \(response.amount)")
            print("[SubscriptionsAPIService]   - currency: \(response.currency)")
            
            return response
        } catch {
            print("[SubscriptionsAPIService] ❌ ERREUR lors de la création du Payment Intent: \(error)")
            // Le backend ne devrait plus retourner 401 pour cet endpoint, mais on gère toutes les erreurs
            throw error
        }
    }
    
    // MARK: - Cancel Subscription
    /// Annule un abonnement
    /// Endpoint: POST /api/v1/subscriptions/cancel?atPeriodEnd={true|false}
    /// - Parameter atPeriodEnd: true pour résilier à la fin de la période, false pour résilier immédiatement
    func cancelSubscription(atPeriodEnd: Bool = true) async throws {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [SUBSCRIPTIONS] cancelSubscription() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("💳 [SUBSCRIPTIONS] Endpoint: POST /api/v1/subscriptions/cancel")
        print("💳 [SUBSCRIPTIONS] atPeriodEnd: \(atPeriodEnd)")
        
        // Construire l'URL avec le paramètre query
        var urlComponents = URLComponents(string: "\(APIConfig.baseURL)/subscriptions/cancel")
        urlComponents?.queryItems = [
            URLQueryItem(name: "atPeriodEnd", value: String(atPeriodEnd))
        ]
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Ajouter le token d'authentification
        if let authToken = AuthTokenManager.shared.getToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            throw APIError.unauthorized(reason: "Token manquant")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                print("💳 [SUBSCRIPTIONS] ✅ Abonnement résilié avec succès")
                print("   - Type: \(atPeriodEnd ? "À la fin de la période" : "Immédiat")")
                print("═══════════════════════════════════════════════════════════")
            } else if httpResponse.statusCode == 401 {
                throw APIError.unauthorized(reason: "Token invalide")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch let error as APIError {
            print("💳 [SUBSCRIPTIONS] ❌ Erreur API: \(error)")
            print("═══════════════════════════════════════════════════════════")
            throw error
        } catch {
            print("💳 [SUBSCRIPTIONS] ❌ Erreur lors de la résiliation: \(error.localizedDescription)")
            print("═══════════════════════════════════════════════════════════")
            throw APIError.networkError(error)
        }
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

