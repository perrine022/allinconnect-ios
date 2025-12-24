//
//  FavoritesAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Favorites API Service
@MainActor
class FavoritesAPIService: ObservableObject {
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
    
    // MARK: - Get All Favorites
    func getFavorites() async throws -> [PartnerProfessionalResponse] {
        // L'API retourne directement un tableau de professionnels favoris
        let favorites: [PartnerProfessionalResponse] = try await apiService.request(
            endpoint: "/users/favorites",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return favorites
    }
    
    // MARK: - Add Favorite
    func addFavorite(professionalId: Int) async throws {
        // La réponse peut être vide (200 OK)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/users/favorites/\(professionalId)",
            method: .post,
            parameters: nil,
            headers: nil
        )
    }
    
    // MARK: - Remove Favorite
    func removeFavorite(professionalId: Int) async throws {
        // La réponse peut être vide (204 No Content)
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/users/favorites/\(professionalId)",
            method: .delete,
            parameters: nil,
            headers: nil
        )
    }
}

