//
//  SavingsAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Savings Response
struct SavingsResponse: Codable, Identifiable {
    let id: Int
    let shopName: String
    let description: String?
    let amount: Double
    let date: String // ISO 8601 format
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopName
        case description
        case amount
        case date
    }
}

// MARK: - Create/Update Savings Request
struct SavingsRequest: Codable {
    let shopName: String
    let description: String?
    let amount: Double
    let date: String // ISO 8601 format
    
    enum CodingKeys: String, CodingKey {
        case shopName
        case description
        case amount
        case date
    }
}

// MARK: - Savings API Service
@MainActor
class SavingsAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Get All Savings
    func getSavings() async throws -> [SavingsResponse] {
        let savings: [SavingsResponse] = try await apiService.request(
            endpoint: "/savings",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return savings
    }
    
    // MARK: - Create Savings
    func createSavings(_ request: SavingsRequest) async throws -> SavingsResponse {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let savings: SavingsResponse = try await apiService.request(
            endpoint: "/savings",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        return savings
    }
    
    // MARK: - Update Savings
    func updateSavings(id: Int, request: SavingsRequest) async throws -> SavingsResponse {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let savings: SavingsResponse = try await apiService.request(
            endpoint: "/savings/\(id)",
            method: .put,
            parameters: parameters,
            headers: nil
        )
        return savings
    }
    
    // MARK: - Delete Savings
    func deleteSavings(id: Int) async throws {
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/savings/\(id)",
            method: .delete,
            parameters: nil,
            headers: nil
        )
    }
}

// MARK: - Extension to convert SavingsResponse to SavingsEntry
extension SavingsResponse {
    func toSavingsEntry() -> SavingsEntry {
        // Parse ISO 8601 date
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        var parsedDate = Date()
        if let date = isoDateFormatter.date(from: date) {
            parsedDate = date
        } else if let date = dateFormatter.date(from: date) {
            parsedDate = date
        }
        
        return SavingsEntry(
            id: UUID(),
            apiId: id,
            amount: amount,
            date: parsedDate,
            store: shopName,
            description: description
        )
    }
}

