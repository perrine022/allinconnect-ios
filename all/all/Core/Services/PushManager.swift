//
//  PushManager.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class PushManager: NSObject {
    static let shared = PushManager()
    
    private let pushRegistrationURL = "https://my-api.com/api/push/register"
    private let storedTokenKey = "apns_device_token"
    private let storedUserIdKey = "push_user_id"
    
    private var deviceToken: String?
    private var userId: String?
    
    private override init() {
        super.init()
        loadStoredData()
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }
    
    // MARK: - Register for Remote Notifications
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Handle Device Token
    func handleDeviceToken(_ tokenData: Data) {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Vérifier si le token a changé
        if let storedToken = UserDefaults.standard.string(forKey: storedTokenKey),
           storedToken == tokenString {
            print("PushManager: Device token unchanged, skipping registration")
            return
        }
        
        // Stocker le nouveau token
        self.deviceToken = tokenString
        UserDefaults.standard.set(tokenString, forKey: storedTokenKey)
        
        // Enregistrer le token si on a un userId
        if let userId = getUserId() {
            Task {
                await registerTokenWithBackend(token: tokenString, userId: userId)
            }
        } else {
            print("PushManager: No userId available, token will be registered after login")
        }
    }
    
    // MARK: - Register Token After Login
    func registerTokenAfterLogin(userId: String) async {
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: storedUserIdKey)
        
        if let token = deviceToken ?? UserDefaults.standard.string(forKey: storedTokenKey) {
            await registerTokenWithBackend(token: token, userId: userId)
        }
    }
    
    // MARK: - Unregister Token on Logout
    func unregisterToken() {
        self.userId = nil
        UserDefaults.standard.removeObject(forKey: storedUserIdKey)
        // Note: Le token reste stocké localement mais ne sera plus associé à un userId
    }
    
    // MARK: - Private Methods
    private func loadStoredData() {
        self.deviceToken = UserDefaults.standard.string(forKey: storedTokenKey)
        self.userId = UserDefaults.standard.string(forKey: storedUserIdKey)
    }
    
    private func getUserId() -> String? {
        // D'abord essayer le userId stocké
        if let userId = self.userId {
            return userId
        }
        
        // Sinon, essayer de récupérer depuis UserDefaults
        if let userId = UserDefaults.standard.string(forKey: storedUserIdKey) {
            self.userId = userId
            return userId
        }
        
        // En dernier recours, essayer de récupérer depuis l'API
        // (Cette partie sera appelée de manière asynchrone si nécessaire)
        return nil
    }
    
    private func registerTokenWithBackend(token: String, userId: String) async {
        let requestBody: [String: Any] = [
            "userId": userId,
            "token": token,
            "platform": "ios",
            "environment": "prod"
        ]
        
        guard let url = URL(string: pushRegistrationURL) else {
            print("PushManager: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token d'authentification si disponible
        if let authToken = AuthTokenManager.shared.getToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("PushManager: Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("PushManager: Successfully registered device token")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("PushManager: Failed to register token - Status: \(httpResponse.statusCode), Message: \(errorMessage)")
            }
        } catch {
            print("PushManager: Error registering token: \(error.localizedDescription)")
        }
    }
}

