//
//  PaymentAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Payment Sheet Request
struct PaymentSheetRequest: Codable {
    let amount: Int // Montant en centimes (ex: 2000 pour 20.00€)
    let currency: String // "eur"
    let description: String?
    let captureImmediately: Bool
    // Note: userId n'est plus nécessaire - le backend le récupère automatiquement depuis le JWT
    
    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case description
        case captureImmediately = "captureImmediately"
    }
}

// MARK: - Payment Sheet Response
struct PaymentSheetResponse: Codable {
    let paymentIntent: String // "pi_..."
    let ephemeralKey: String // "ek_..."
    let customer: String // "cus_..."
    let publishableKey: String // "pk_test_..."
    
    enum CodingKeys: String, CodingKey {
        case paymentIntent = "paymentIntent"
        case ephemeralKey = "ephemeralKey"
        case customer
        case publishableKey = "publishableKey"
    }
}

// MARK: - Create Payment Intent Request
struct CreatePaymentIntentRequest: Codable {
    let amount: Int
    let currency: String
    let description: String?
    let captureImmediately: Bool
    // Note: userId n'est plus nécessaire - le backend le récupère automatiquement depuis le JWT
    
    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case description
        case captureImmediately = "captureImmediately"
    }
}

// MARK: - Create Payment Intent Response
struct CreatePaymentIntentResponse: Codable {
    let paymentIntentId: String // "pi_..."
    let clientSecret: String // "pi_..._secret_..."
    let ephemeralKey: String // "ek_..."
    let publishableKey: String // "pk_test_..."
    
    enum CodingKeys: String, CodingKey {
        case paymentIntentId = "paymentIntentId"
        case clientSecret = "clientSecret"
        case ephemeralKey = "ephemeralKey"
        case publishableKey = "publishableKey"
    }
}

// MARK: - Create Customer Response
struct CreateCustomerResponse: Codable {
    let customerId: String // "cus_..."
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customerId"
    }
}

// MARK: - Payment Status Response
struct PaymentStatusResponse: Codable {
    let status: String // "succeeded", "requires_payment_method", etc.
    
    enum CodingKeys: String, CodingKey {
        case status
    }
}

// MARK: - Payment API Service
@MainActor
class PaymentAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        self.apiService = apiService ?? APIService.shared
    }
    
    // MARK: - Get Public Key
    /// Récupère la clé publique Stripe depuis le backend
    func getPublicKey() async throws -> String {
        print("[PaymentAPIService] getPublicKey() - Début")
        print("[PaymentAPIService] Endpoint: GET /api/v1/payment/public-key")
        
        do {
            // Le backend retourne une chaîne brute, pas un JSON
            guard let url = URL(string: "\(APIConfig.baseURL)/payment/public-key") else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            if let token = AuthTokenManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            // La réponse est une chaîne brute (pas de JSON)
            guard let publicKey = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                throw APIError.invalidResponse
            }
            
            print("[PaymentAPIService] ✅ Clé publique récupérée: \(publicKey.prefix(20))...")
            return publicKey
        } catch {
            print("[PaymentAPIService] getPublicKey() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Create Payment Sheet
    /// Crée un Payment Sheet pour le paiement mobile (iOS/Android)
    /// Le backend récupère automatiquement le userId depuis le JWT, pas besoin de l'envoyer
    func createPaymentSheet(request: PaymentSheetRequest) async throws -> PaymentSheetResponse {
        print("📡 [API] createPaymentSheet() - Début")
        print("📡 [API] ───────────────────────────────────────────────────")
        print("📡 [API] Endpoint: POST /api/v1/payment/payment-sheet")
        print("📡 [API] URL complète: \(APIConfig.baseURL)/payment/payment-sheet")
        
        // Vérifier le token
        if let token = AuthTokenManager.shared.getToken() {
            print("📡 [API] ✅ Token JWT présent: \(token.prefix(30))...")
        } else {
            print("📡 [API] ⚠️ Aucun token JWT trouvé")
        }
        
        print("📡 [API] Body de la requête:")
        print("   - amount: \(request.amount) centimes (\(Double(request.amount) / 100.0)€)")
        print("   - currency: \(request.currency)")
        print("   - description: \(request.description ?? "N/A")")
        print("   - captureImmediately: \(request.captureImmediately)")
        print("   - userId: (récupéré automatiquement depuis le JWT par le backend)")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(request)
            
            // Log du JSON brut
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📡 [API] JSON envoyé: \(jsonString)")
            }
            
            guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("📡 [API] ❌ Erreur: Impossible de convertir en [String: Any]")
                throw APIError.invalidResponse
            }
            
            print("📡 [API] ───────────────────────────────────────────────────")
            print("📡 [API] Envoi de la requête au backend...")
            let startTime = Date()
            
            let response: PaymentSheetResponse = try await apiService.request(
                endpoint: "/payment/payment-sheet",
                method: .post,
                parameters: parameters,
                headers: nil
            )
            
            let duration = Date().timeIntervalSince(startTime)
            print("📡 [API] ───────────────────────────────────────────────────")
            print("📡 [API] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
            print("📡 [API] Détails de la réponse:")
            print("   - paymentIntent: \(response.paymentIntent)")
            print("   - customer: \(response.customer)")
            print("   - ephemeralKey: \(response.ephemeralKey.prefix(40))...")
            print("   - publishableKey: \(response.publishableKey.prefix(40))...")
            print("📡 [API] ───────────────────────────────────────────────────")
            
            return response
        } catch {
            print("📡 [API] ───────────────────────────────────────────────────")
            print("📡 [API] ❌ ERREUR lors de l'appel API")
            print("📡 [API] Type: \(type(of: error))")
            print("📡 [API] Message: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                print("📡 [API] Détails APIError: \(apiError)")
            }
            print("📡 [API] ───────────────────────────────────────────────────")
            throw error
        }
    }
    
    // MARK: - Create Payment Intent
    /// Crée un Payment Intent pour le paiement standard (Web ou Custom)
    /// Le backend récupère automatiquement le userId depuis le JWT, pas besoin de l'envoyer
    func createPaymentIntent(request: CreatePaymentIntentRequest) async throws -> CreatePaymentIntentResponse {
        print("[PaymentAPIService] createPaymentIntent() - Début")
        print("[PaymentAPIService] Endpoint: POST /api/v1/payment/create-payment-intent")
        print("[PaymentAPIService] Amount: \(request.amount) centimes (\(Double(request.amount) / 100.0)€)")
        print("[PaymentAPIService] Note: userId récupéré automatiquement depuis le JWT par le backend")
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(request)
            
            guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw APIError.invalidResponse
            }
            
            let response: CreatePaymentIntentResponse = try await apiService.request(
                endpoint: "/payment/create-payment-intent",
                method: .post,
                parameters: parameters,
                headers: nil
            )
            
            print("[PaymentAPIService] ✅ Payment Intent créé avec succès")
            print("[PaymentAPIService]   - paymentIntentId: \(response.paymentIntentId)")
            print("[PaymentAPIService]   - clientSecret: \(response.clientSecret.prefix(20))...")
            
            return response
        } catch {
            print("[PaymentAPIService] createPaymentIntent() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Create Customer
    /// Crée un client Stripe
    func createCustomer() async throws -> CreateCustomerResponse {
        print("[PaymentAPIService] createCustomer() - Début")
        print("[PaymentAPIService] Endpoint: POST /api/v1/payment/create-customer")
        
        do {
            let response: CreateCustomerResponse = try await apiService.request(
                endpoint: "/payment/create-customer",
                method: .post,
                parameters: nil,
                headers: nil
            )
            
            print("[PaymentAPIService] ✅ Customer créé avec succès: \(response.customerId)")
            return response
        } catch {
            print("[PaymentAPIService] createCustomer() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Get Payment Status
    /// Vérifie le statut d'un paiement
    func getPaymentStatus(paymentIntentId: String) async throws -> PaymentStatusResponse {
        print("[PaymentAPIService] getPaymentStatus() - Début")
        print("[PaymentAPIService] Endpoint: GET /api/v1/payment/status/\(paymentIntentId)")
        
        do {
            let response: PaymentStatusResponse = try await apiService.request(
                endpoint: "/payment/status/\(paymentIntentId)",
                method: .get,
                parameters: nil,
                headers: nil
            )
            
            print("[PaymentAPIService] ✅ Statut récupéré: \(response.status)")
            return response
        } catch {
            print("[PaymentAPIService] getPaymentStatus() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
}


