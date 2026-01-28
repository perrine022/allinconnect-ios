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
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    
    var body: some Scene {
        WindowGroup {
            AnimatedSplashView(
                hasSeenTutorial: $hasSeenTutorial,
                isLoggedIn: $isLoggedIn,
                locationService: locationService
            )
        }
    }
}

// MARK: - App Content View
struct AppContentView: View {
    @Binding var hasSeenTutorial: Bool
    @Binding var isLoggedIn: Bool
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Group {
            if !hasSeenTutorial {
                // Étape 0: Tutoriel (premier lancement uniquement)
                TutorialView(
                    onComplete: {
                        hasSeenTutorial = true
                        // Après le tutoriel, aller directement à la connexion/inscription
                    },
                    onSkip: {
                        hasSeenTutorial = true
                        // Si on passe le tutoriel, aller directement à la connexion/inscription
                    }
                )
            } else if !isLoggedIn {
                // Étape 1: Connexion/Inscription (après tutoriel)
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
                // Étape 2: App principale (si connecté)
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
        // Note: Les notifications push sont gérées dans AppDelegate au lancement
    }
    
    @MainActor
    private func registerPushTokenAfterLogin() async {
        // L'utilisateur est identifié via le token JWT, pas besoin de récupérer userId
        await PushManager.shared.registerTokenAfterLogin()
    }
}
