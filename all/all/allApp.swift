//
//  allApp.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

@main
struct allApp: App {
    @StateObject private var locationService = LocationService.shared
    @State private var hasCompletedOnboarding = OnboardingViewModel.hasCompletedOnboarding()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                TabBarView()
                    .environmentObject(locationService)
                    .onAppear {
                        // Vérifier la permission au démarrage
                        if locationService.authorizationStatus == .notDetermined {
                            // La permission sera demandée depuis HomeView ou OffersView
                        }
                    }
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
