//
//  NotificationPreferencesAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Notification Preferences Response Model
struct NotificationPreferencesResponse: Codable {
    let notifyNewOffers: Bool
    let notifyNewProNearby: Bool
    let notifyLocalEvents: Bool
    let notificationRadius: Int
    let preferredCategories: [String]
    
    enum CodingKeys: String, CodingKey {
        case notifyNewOffers = "notifyNewOffers"
        case notifyNewProNearby = "notifyNewProNearby"
        case notifyLocalEvents = "notifyLocalEvents"
        case notificationRadius = "notificationRadius"
        case preferredCategories = "preferredCategories"
    }
}

// MARK: - Notification Preferences Request Model
struct NotificationPreferencesRequest: Codable {
    let notifyNewOffers: Bool
    let notifyNewProNearby: Bool
    let notifyLocalEvents: Bool
    let notificationRadius: Int
    let preferredCategories: [String]
    
    enum CodingKeys: String, CodingKey {
        case notifyNewOffers = "notifyNewOffers"
        case notifyNewProNearby = "notifyNewProNearby"
        case notifyLocalEvents = "notifyLocalEvents"
        case notificationRadius = "notificationRadius"
        case preferredCategories = "preferredCategories"
    }
}

// MARK: - Notification Preferences API Service
class NotificationPreferencesAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        self.apiService = apiService ?? APIService.shared
    }
    
    /// Récupère les préférences de notification de l'utilisateur
    func getNotificationPreferences() async throws -> NotificationPreferencesResponse {
        print("🔔 [API] 📞 Appel GET /api/v1/notification-preferences")
        print("🔔 [API] BaseURL: \(APIConfig.baseURL)")
        
        let preferences: NotificationPreferencesResponse = try await apiService.request(
            endpoint: "/notification-preferences",
            method: .get,
            parameters: nil,
            headers: nil
        )
        
        print("🔔 [API] ✅ Réponse reçue:")
        print("   - notifyNewOffers: \(preferences.notifyNewOffers)")
        print("   - notifyNewProNearby: \(preferences.notifyNewProNearby)")
        print("   - notifyLocalEvents: \(preferences.notifyLocalEvents)")
        print("   - notificationRadius: \(preferences.notificationRadius)")
        print("   - preferredCategories: \(preferences.preferredCategories)")
        
        return preferences
    }
    
    /// Met à jour les préférences de notification de l'utilisateur
    func updateNotificationPreferences(_ request: NotificationPreferencesRequest) async throws {
        print("🔔 [API] 📞 Appel PUT /api/v1/notification-preferences")
        print("🔔 [API] BaseURL: \(APIConfig.baseURL)")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("🔔 [API] ❌ Erreur: Impossible de convertir en [String: Any]")
            throw APIError.invalidResponse
        }
        
        print("🔔 [API] Payload JSON:")
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("   \(jsonString)")
        }
        print("🔔 [API] Paramètres envoyés:")
        for (key, value) in parameters {
            print("   - \(key): \(value)")
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/notification-preferences",
            method: .put,
            parameters: parameters,
            headers: nil
        )
        
        print("🔔 [API] ✅ Préférences mises à jour avec succès")
    }
}


