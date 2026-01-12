//
//  WalletAPIService.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine

// MARK: - Wallet History Response Model
struct WalletHistoryResponse: Codable, Identifiable {
    let id: Int
    let amount: Double
    let description: String
    let date: String
    let user: WalletUserResponse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case description
        case date
        case user
    }
}

struct WalletUserResponse: Codable {
    let id: Int?
    let firstName: String?
    let lastName: String?
}

// MARK: - Wallet Request Response Model
struct WalletRequestResponse: Codable, Identifiable {
    let id: Int
    let totalAmount: Double
    let status: String // "PENDING", "VALIDATED", "REJECTED"
    let createdAt: String
    let professionals: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount = "totalAmount"
        case status
        case createdAt = "createdAt"
        case professionals
    }
}

// MARK: - Wallet Request Model
struct WalletRequest: Codable {
    let amount: Double
    let professionals: String
}

// MARK: - Wallet API Service
@MainActor
class WalletAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Get Wallet History
    func getWalletHistory() async throws -> [WalletHistoryResponse] {
        let history: [WalletHistoryResponse] = try await apiService.request(
            endpoint: "/wallet/history",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return history
    }
    
    // MARK: - Create Wallet Request
    func createWalletRequest(amount: Double, professionals: String) async throws -> WalletRequestResponse {
        let request = WalletRequest(
            amount: amount,
            professionals: professionals
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let response: WalletRequestResponse = try await apiService.request(
            endpoint: "/wallet/request",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        return response
    }
    
    // MARK: - Get Wallet Requests
    func getWalletRequests() async throws -> [WalletRequestResponse] {
        let requests: [WalletRequestResponse] = try await apiService.request(
            endpoint: "/wallet/requests",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return requests
    }
}















