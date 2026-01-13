//
//  AppState.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: TabItem = .home
    @Published var showProfileBadge: Bool = false
    
    func navigateToTab(_ tab: TabItem, dismiss: (() -> Void)? = nil) {
        // Si on reclique sur l'onglet actif, scroller vers le haut
        if selectedTab == tab {
            NotificationCenter.default.post(name: NSNotification.Name("ScrollToTop"), object: nil, userInfo: ["tab": tab])
        }
        
        // Toujours mettre à jour le selectedTab
        selectedTab = tab
        // Notifier toutes les vues qu'elles doivent se fermer pour revenir au TabBarView
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToTab"), object: nil, userInfo: ["tab": tab])
        // Si on a un dismiss à appeler (depuis une vue modale), l'appeler après un court délai
        // pour permettre à la navigation de se faire
        if let dismiss = dismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        }
    }
}

