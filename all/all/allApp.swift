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
    @State private var hasSeenTutorial = TutorialViewModel.hasSeenTutorial()
    @State private var hasCompletedOnboarding = OnboardingViewModel.hasCompletedOnboarding()
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    
    var body: some Scene {
        WindowGroup {
            AppContentView(
                hasSeenTutorial: $hasSeenTutorial,
                hasCompletedOnboarding: $hasCompletedOnboarding,
                isLoggedIn: $isLoggedIn,
                locationService: locationService
            )
        }
    }
}

// MARK: - App Content View
struct AppContentView: View {
    @Binding var hasSeenTutorial: Bool
    @Binding var hasCompletedOnboarding: Bool
    @Binding var isLoggedIn: Bool
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Group {
            if !hasSeenTutorial {
                // Étape 0: Tutoriel (premier lancement uniquement)
                TutorialView(
                    onComplete: {
                        hasSeenTutorial = true
                        // Après le tutoriel, afficher l'inscription si premier lancement
                        if !hasCompletedOnboarding {
                            // L'inscription sera affichée automatiquement
                        }
                    },
                    onSkip: {
                        hasSeenTutorial = true
                        // Si on passe le tutoriel, aller directement à la connexion/inscription
                    }
                )
            } else if !hasCompletedOnboarding {
                // Étape 1: Inscription (après tutoriel, premier lancement)
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            } else if !isLoggedIn {
                // Étape 2: Connexion (si déjà lancé l'app)
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
        // L'utilisateur est identifié via le token JWT, pas besoin de récupérer userId
        await PushManager.shared.registerTokenAfterLogin()
    }
}
