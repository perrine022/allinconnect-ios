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
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Contenu principal
                    Group {
                        switch selectedTab {
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
                        FooterBar(selectedTab: $selectedTab) { tab in
                            selectedTab = tab
                        }
                        .frame(width: geometry.size.width)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}





#Preview {
    TabBarView()
}

