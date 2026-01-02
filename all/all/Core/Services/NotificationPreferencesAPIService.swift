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
        let preferences: NotificationPreferencesResponse = try await apiService.request(
            endpoint: "/notification-preferences",
            method: .get,
            parameters: nil,
            headers: nil
        )
        return preferences
    }
    
    /// Met à jour les préférences de notification de l'utilisateur
    func updateNotificationPreferences(_ request: NotificationPreferencesRequest) async throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        guard let parameters = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        struct EmptyResponse: Codable {}
        let _: EmptyResponse = try await apiService.request(
            endpoint: "/notification-preferences",
            method: .put,
            parameters: parameters,
            headers: nil
        )
    }
}


