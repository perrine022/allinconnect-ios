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
    let id: Int
    let firstName: String
    let lastName: String
    let profilePicture: String? // Photo de profil de l'auteur de l'avis
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case profilePicture
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
    /// Dépose un avis sur un partenaire
    /// Endpoint: POST /api/v1/ratings
    /// Authentification: Requise (Bearer Token)
    func createRating(ratedId: Int, score: Int, comment: String?) async throws -> RatingResponse {
        print("═══════════════════════════════════════════════════════════")
        print("⭐ [RATINGS] createRating() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("⭐ [RATINGS] Endpoint: POST /api/v1/ratings")
        print("⭐ [RATINGS] Paramètres: ratedId=\(ratedId), score=\(score), comment=\(comment ?? "nil")")
        
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
        
        print("⭐ [RATINGS] ✅ Avis créé avec succès: ID=\(rating.id)")
        print("═══════════════════════════════════════════════════════════")
        return rating
    }
    
    // MARK: - Get Ratings by User
    /// Récupère la liste des avis d'un partenaire
    /// Endpoint: GET /api/v1/ratings/user/{userId}
    /// Authentification: Aucune (Endpoint public)
    func getRatingsByUser(userId: Int) async throws -> [RatingResponse] {
        print("⭐ [RATINGS] getRatingsByUser() - Début")
        print("⭐ [RATINGS] Endpoint: GET /api/v1/ratings/user/\(userId)")
        
        let ratings: [RatingResponse] = try await apiService.request(
            endpoint: "/ratings/user/\(userId)",
            method: .get,
            parameters: nil,
            headers: nil
        )
        
        print("⭐ [RATINGS] ✅ \(ratings.count) avis récupérés pour l'utilisateur \(userId)")
        return ratings
    }
    
    // MARK: - Get Average Rating
    /// Récupère la note moyenne d'un partenaire
    /// Endpoint: GET /api/v1/ratings/user/{userId}/average
    /// Authentification: Aucune (Endpoint public)
    /// Retourne: Double (ex: 4.5)
    func getAverageRating(userId: Int) async throws -> Double {
        print("⭐ [RATINGS] getAverageRating() - Début")
        print("⭐ [RATINGS] Endpoint: GET /api/v1/ratings/user/\(userId)/average")
        
        let average: Double = try await apiService.request(
            endpoint: "/ratings/user/\(userId)/average",
            method: .get,
            parameters: nil,
            headers: nil
        )
        
        print("⭐ [RATINGS] ✅ Note moyenne récupérée: \(average) pour l'utilisateur \(userId)")
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
        
        // Parser la date createdAt (format ISO 8601)
        // Format attendu: "2026-01-17T08:30:00" ou "2026-01-17T08:30:00.000Z"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var parsedDate = Date()
        
        // Essayer différents formats ISO 8601
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: createdAt) {
                parsedDate = date
                break
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









