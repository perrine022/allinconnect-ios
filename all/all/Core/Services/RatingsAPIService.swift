//
//  RatingsAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Rating Request
struct RatingRequest: Codable {
    let ratedId: Int
    let score: Int
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case ratedId
        case score
        case comment
    }
}

// MARK: - Rater Response Model
struct RaterResponse: Codable {
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
}

// MARK: - Rating Response Model
struct RatingResponse: Codable, Identifiable {
    let id: Int
    let score: Int
    let comment: String?
    let createdAt: String
    let rater: RaterResponse?
    
    enum CodingKeys: String, CodingKey {
        case id
        case score
        case comment
        case createdAt
        case rater
    }
}

// MARK: - Ratings API Service
@MainActor
class RatingsAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Create Rating
    func createRating(ratedId: Int, score: Int, comment: String?) async throws -> RatingResponse {
        let request = RatingRequest(
            ratedId: ratedId,
            score: score,
            comment: comment
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        let rating: RatingResponse = try await apiService.request(
            endpoint: "/ratings",
            method: .post,
            parameters: parameters,
            headers: nil
        )
        return rating
    }
    
    // MARK: - Get Ratings by User
    func getRatingsByUser(userId: Int) async throws -> [RatingResponse] {
        let ratings: [RatingResponse] = try await apiService.request(
            endpoint: "/ratings/user/\(userId)",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return ratings
    }
    
    // MARK: - Get Average Rating
    func getAverageRating(userId: Int) async throws -> Double {
        let average: Double = try await apiService.request(
            endpoint: "/ratings/user/\(userId)/average",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return average
    }
}

// MARK: - Mapping Extension
extension RatingResponse {
    func toReview() -> Review {
        // Construire le nom complet depuis le rater
        let userName: String
        if let rater = rater {
            userName = "\(rater.firstName) \(rater.lastName)"
        } else {
            userName = "Utilisateur"
        }
        
        // Parser la date createdAt
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var parsedDate = Date()
        if let date = dateFormatter.date(from: createdAt) {
            parsedDate = date
        } else {
            // Essayer avec les millisecondes
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            if let date = dateFormatter.date(from: createdAt) {
                parsedDate = date
            }
        }
        
        return Review(
            id: UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", id, id)) ?? UUID(),
            userName: userName,
            rating: Double(score),
            comment: comment ?? "",
            date: parsedDate
        )
    }
}


