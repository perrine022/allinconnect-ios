//
//  CustomerRequestAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Customer Request Request Model
struct CustomerRequestRequest: Codable {
    let userId: Int
    let title: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case userId
        case title
        case message
    }
}

// MARK: - Customer Request Response Model
struct CustomerRequestResponse: Codable {
    let id: Int
    let userId: Int
    let title: String
    let message: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case title
        case message
        case createdAt
    }
}

// MARK: - Customer Request API Service
@MainActor
class CustomerRequestAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Create Customer Request
    /// Crée une nouvelle demande client
    /// Endpoint: POST /api/v1/customer-requests
    /// Body: { "userId": 1, "title": "Sujet", "message": "Mon message" }
    func createCustomerRequest(userId: Int, title: String, message: String) async throws -> CustomerRequestResponse {
        print("═══════════════════════════════════════════════════════════")
        print("📧 [CUSTOMER_REQUEST] createCustomerRequest() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("📧 [CUSTOMER_REQUEST] Endpoint: POST /api/v1/customer-requests")
        print("📧 [CUSTOMER_REQUEST] Paramètres:")
        print("   - userId: \(userId)")
        print("   - title: \(title)")
        print("   - message: \(message.prefix(50))...")
        
        let request = CustomerRequestRequest(
            userId: userId,
            title: title,
            message: message
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let response: CustomerRequestResponse = try await apiService.request(
            endpoint: "/customer-requests",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        
        print("📧 [CUSTOMER_REQUEST] ✅ Demande créée avec succès: ID=\(response.id)")
        print("═══════════════════════════════════════════════════════════")
        
        return response
    }
}
