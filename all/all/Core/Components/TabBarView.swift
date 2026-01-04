//
//  TabBarView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case home = "Accueil"
    case offers = "Offres"
    case card = "Ma Carte"
    case profile = "Profil"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .offers: return "tag.fill"
        case .card: return "creditcard.fill"
        case .profile: return "person.fill"
        }
    }
}

struct TabBarView: View {
    @StateObject private var appState = AppState()
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    
    var body: some View {
        Group {
            if !isLoggedIn {
                // Rediriger vers la connexion si l'utilisateur n'est pas connecté
                LoginViewWrapper()
                    .environmentObject(appState)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
                        isLoggedIn = true
                    }
            } else {
                NavigationStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            // Contenu principal
                            Group {
                                switch appState.selectedTab {
                                case .home:
                                    HomeView()
                                case .offers:
                                    OffersView()
                                case .card:
                                    CardView()
                                case .profile:
                                    ProfileView()
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                            // Footer Bar réutilisable - toujours visible au-dessus
                            VStack {
                                Spacer()
                                FooterBar(selectedTab: $appState.selectedTab) { tab in
                                    appState.navigateToTab(tab)
                                }
                                .frame(width: geometry.size.width)
                            }
                            .ignoresSafeArea(edges: .bottom)
                        }
                    }
                }
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                    isLoggedIn = false
                }
            }
        }
    }
}





#Preview {
    TabBarView()
}

