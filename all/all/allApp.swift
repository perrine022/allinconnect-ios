//
//  allApp.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import CoreLocation

@main
struct allApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var locationService = LocationService.shared
    @State private var hasCompletedOnboarding = OnboardingViewModel.hasCompletedOnboarding()
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    
    var body: some Scene {
        WindowGroup {
            AppContentView(
                hasCompletedOnboarding: .constant(true), // Toujours considérer l'onboarding comme complété
                isLoggedIn: $isLoggedIn,
                locationService: locationService
            )
        }
    }
}

// MARK: - App Content View
struct AppContentView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var isLoggedIn: Bool
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Étape 1: Onboarding
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if !isLoggedIn {
                // Étape 2: Connexion/Inscription (après onboarding)
                LoginViewWrapper()
                    .environmentObject(AppState())
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
                        isLoggedIn = true
                        // Enregistrer le token push après la connexion
                        Task { @MainActor in
                            await registerPushTokenAfterLogin()
                        }
                    }
            } else {
                // Étape 3: App principale (si connecté)
                TabBarView()
                    .environmentObject(locationService)
                    .onAppear {
                        // Vérifier la permission au démarrage
                        if locationService.authorizationStatus == .notDetermined {
                            // La permission sera demandée depuis HomeView ou OffersView
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                        isLoggedIn = false
                        // Désenregistrer le token push après la déconnexion
                        PushManager.shared.unregisterToken()
                    }
            }
        }
        .task {
            // Initialiser les notifications push au démarrage
            await initializePushNotifications()
        }
    }
    
    // MARK: - Push Notifications Setup
    @MainActor
    private func initializePushNotifications() async {
        do {
            let granted = try await PushManager.shared.requestAuthorization()
            if granted {
                PushManager.shared.registerForRemoteNotifications()
            } else {
                print("Push notifications authorization denied")
            }
        } catch {
            print("Error requesting push notification authorization: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func registerPushTokenAfterLogin() async {
        // Récupérer l'ID utilisateur depuis l'API
        let profileService = ProfileAPIService()
        do {
            let userId = try await profileService.getCurrentUserId()
            await PushManager.shared.registerTokenAfterLogin(userId: userId)
        } catch {
            print("Error getting user ID, trying fallback: \(error.localizedDescription)")
            // Fallback: utiliser l'email comme identifiant temporaire
            if let email = UserDefaults.standard.string(forKey: "user_email") {
                await PushManager.shared.registerTokenAfterLogin(userId: email)
            }
        }
    }
}
