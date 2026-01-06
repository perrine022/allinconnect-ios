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
    @State private var pushNotificationOfferId: Int?
    @State private var pushNotificationProfessionalId: Int?
    
    var body: some View {
        Group {
            if !isLoggedIn {
                // Rediriger vers la connexion si l'utilisateur n'est pas connecté
                LoginViewWrapper()
                    .environmentObject(appState)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
                        isLoggedIn = true
                        // Enregistrer le token push après la connexion
                        Task { @MainActor in
                            await PushManager.shared.registerTokenAfterLogin()
                        }
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
                    // Désenregistrer le token push après la déconnexion
                    PushManager.shared.unregisterToken()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PushNotificationTapped"))) { notification in
                    handlePushNotificationNavigation(notification: notification)
                }
                .navigationDestination(item: $pushNotificationOfferId) { offerId in
                    OfferDetailView(offerId: offerId)
                }
                .navigationDestination(item: $pushNotificationProfessionalId) { professionalId in
                    // Charger le partenaire depuis l'API et naviguer vers sa fiche
                    PartnerDetailViewFromId(professionalId: professionalId)
                }
                .onAppear {
                    // Enregistrer le token push au démarrage si l'utilisateur est connecté
                    Task { @MainActor in
                        await PushManager.shared.registerTokenAfterLogin()
                    }
                }
            }
        }
    }
    
    private func handlePushNotificationNavigation(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        print("[TabBarView] Gestion navigation depuis notification push: \(userInfo)")
        
        // Pour une offre ou un événement
        if let offerIdString = userInfo["offerId"] as? String,
           let offerId = Int(offerIdString) {
            print("[TabBarView] Navigation vers offre: \(offerId)")
            // Basculer vers l'onglet Offres si nécessaire
            appState.selectedTab = .offers
            // Naviguer vers l'offre
            pushNotificationOfferId = offerId
        }
        
        // Pour un nouvel établissement
        if let professionalIdString = userInfo["professionalId"] as? String,
           let professionalId = Int(professionalIdString) {
            print("[TabBarView] Navigation vers professionnel: \(professionalId)")
            // Basculer vers l'onglet Accueil ou Offres
            appState.selectedTab = .home
            // Naviguer vers le partenaire
            pushNotificationProfessionalId = professionalId
        }
    }
}

// Vue helper pour charger un partenaire depuis son ID
struct PartnerDetailViewFromId: View {
    let professionalId: Int
    @StateObject private var viewModel: PartnerDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(professionalId: Int) {
        self.professionalId = professionalId
        // Créer un Partner temporaire qui sera remplacé par les données de l'API
        let tempPartner = Partner(
            name: "Chargement...",
            category: "",
            address: "",
            city: "",
            postalCode: "",
            rating: 0,
            reviewCount: 0,
            imageName: "person.circle.fill",
            headerImageName: "person.circle.fill",
            apiId: professionalId
        )
        _viewModel = StateObject(wrappedValue: PartnerDetailViewModel(partner: tempPartner))
    }
    
    var body: some View {
        PartnerDetailView(partner: viewModel.partner)
    }
}





#Preview {
    TabBarView()
}

