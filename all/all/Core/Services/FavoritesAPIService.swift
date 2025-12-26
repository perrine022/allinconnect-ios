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
        // La réponse peut être vide (200 OK ou 204 No Content)
        // On utilise EmptyResponse qui peut décoder un JSON vide {}
        struct EmptyResponse: Codable {}
        do {
            let _: EmptyResponse = try await apiService.request(
                endpoint: "/users/favorites/\(professionalId)",
                method: .post,
                parameters: nil,
                headers: nil
            )
        } catch let error as APIError {
            // Si c'est une erreur de décodage avec "Unexpected end of file", 
            // cela signifie que la réponse est vraiment vide, ce qui est acceptable pour un POST
            if case .decodingError(let decodingError) = error {
                if let nsError = decodingError as NSError?,
                   nsError.domain == "NSCocoaErrorDomain",
                   nsError.code == 3840 { // Code pour "Unexpected end of file"
                    // C'est une réponse vide, ce qui est acceptable pour un POST réussi
                    return
                }
            }
            throw error
        }
    }
    
    // MARK: - Remove Favorite
    func removeFavorite(professionalId: Int) async throws {
        // La réponse peut être vide (204 No Content ou 200 OK avec corps vide)
        struct EmptyResponse: Codable {}
        do {
            let _: EmptyResponse = try await apiService.request(
                endpoint: "/users/favorites/\(professionalId)",
                method: .delete,
                parameters: nil,
                headers: nil
            )
        } catch let error as APIError {
            // Si c'est une erreur de décodage avec "Unexpected end of file",
            // cela signifie que la réponse est vraiment vide, ce qui est acceptable pour un DELETE
            if case .decodingError(let decodingError) = error {
                if let nsError = decodingError as NSError?,
                   nsError.domain == "NSCocoaErrorDomain",
                   nsError.code == 3840 { // Code pour "Unexpected end of file"
                    // C'est une réponse vide, ce qui est acceptable pour un DELETE réussi
                    return
                }
            }
            throw error
        }
    }
}

