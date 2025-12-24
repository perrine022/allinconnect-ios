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
    @StateObject private var locationService = LocationService.shared
    @State private var hasCompletedOnboarding = OnboardingViewModel.hasCompletedOnboarding()
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    
    var body: some Scene {
        WindowGroup {
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
                    }
            }
        }
    }
}
