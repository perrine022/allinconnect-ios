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
    
    private let pushRegistrationEndpoint = "/push/register" // POST /api/v1/push/register
    private let storedTokenKey = "apns_device_token"
    
    private var deviceToken: String?
    
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
        
        // Enregistrer le token si l'utilisateur est connecté (token JWT disponible)
        if AuthTokenManager.shared.hasToken() {
            Task {
                await registerTokenWithBackend(token: tokenString)
            }
        } else {
            print("PushManager: User not logged in, token will be registered after login")
        }
    }
    
    // MARK: - Register Token After Login
    func registerTokenAfterLogin() async {
        // L'utilisateur est identifié via le token JWT dans l'Authorization header
        // Essayer d'abord le token FCM (Firebase), sinon le token APNS
        if let fcmToken = UserDefaults.standard.string(forKey: "fcm_token") {
            await registerTokenWithBackend(token: fcmToken)
        } else if let token = deviceToken ?? UserDefaults.standard.string(forKey: storedTokenKey) {
            await registerTokenWithBackend(token: token)
        }
    }
    
    // MARK: - Register FCM Token (Firebase)
    func registerFCMToken(_ fcmToken: String) async {
        // Stocker le token FCM
        UserDefaults.standard.set(fcmToken, forKey: "fcm_token")
        
        // Enregistrer le token FCM si l'utilisateur est connecté
        if AuthTokenManager.shared.hasToken() {
            await registerTokenWithBackend(token: fcmToken)
        } else {
            print("PushManager: User not logged in, FCM token will be registered after login")
        }
    }
    
    // MARK: - Unregister Token on Logout
    func unregisterToken() {
        // Note: Le token reste stocké localement mais ne sera plus associé à un utilisateur
        // Le backend peut gérer la désactivation du token
    }
    
    // MARK: - Private Methods
    private func loadStoredData() {
        self.deviceToken = UserDefaults.standard.string(forKey: storedTokenKey)
    }
    
    private func registerTokenWithBackend(token: String) async {
        // Vérifier que l'utilisateur est connecté (token JWT requis)
        guard AuthTokenManager.shared.hasToken() else {
            print("PushManager: Cannot register token - user not authenticated")
            return
        }
        
        // Déterminer l'environnement (SANDBOX pour debug, PRODUCTION pour release)
        #if DEBUG
        let environment = "SANDBOX"
        #else
        let environment = "PRODUCTION"
        #endif
        
        // Récupérer le deviceId (identifierForVendor)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        let requestBody: [String: Any] = [
            "token": token,
            "platform": "IOS",
            "environment": environment,
            "deviceId": deviceId
        ]
        
        // Construire l'URL complète en utilisant APIConfig
        let fullURL = "\(APIConfig.baseURL)\(pushRegistrationEndpoint)"
        
        guard let url = URL(string: fullURL) else {
            print("PushManager: Invalid URL: \(fullURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Ajouter le token d'authentification (requis)
        if let authToken = AuthTokenManager.shared.getToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("PushManager: Cannot register token - no authentication token")
            return
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("[PushManager] Registering device token:")
            print("   URL: POST \(fullURL)")
            print("   Body: \(requestBody)")
            
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

