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
    @StateObject private var profileAPIService = ProfileAPIService()
    
    var body: some View {
        Group {
            if !isLoggedIn {
                // Rediriger vers la connexion si l'utilisateur n'est pas connecté
                // Forcer l'onglet à l'accueil pour éviter toute navigation vers d'autres onglets
                LoginViewWrapper()
                    .environmentObject(appState)
                    .onAppear {
                        // S'assurer que l'onglet est toujours sur l'accueil si l'utilisateur n'est pas connecté
                        appState.selectedTab = .home
                    }
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
                                FooterBar(
                                    selectedTab: $appState.selectedTab,
                                    onTabSelected: { tab in
                                        appState.navigateToTab(tab)
                                    },
                                    showProfileBadge: appState.showProfileBadge
                                )
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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToCardAfterPayment"))) { _ in
                    // Naviguer vers l'onglet "Ma Carte" après un paiement réussi
                    print("📍 [TabBarView] Notification 'NavigateToCardAfterPayment' reçue - Navigation vers Ma Carte")
                    appState.selectedTab = .card
                    // Notifier pour recharger les données de la carte
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadCardData"), object: nil)
                    print("📍 [TabBarView] Navigation effectuée vers l'onglet 'Ma Carte'")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToHomeAfterPayment"))) { _ in
                    // Naviguer vers l'onglet "Accueil" après un paiement réussi
                    print("📍 [TabBarView] Notification 'NavigateToHomeAfterPayment' reçue - Navigation vers Accueil")
                    appState.selectedTab = .home
                    // Notifier pour recharger les données de la carte en arrière-plan
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadCardData"), object: nil)
                    print("📍 [TabBarView] Navigation effectuée vers l'onglet 'Accueil'")
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
                        await checkEstablishmentStatus()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EstablishmentUpdated"))) { _ in
                    Task { @MainActor in
                        await checkEstablishmentStatus()
                    }
                }
            }
        }
    }
    
    private func checkEstablishmentStatus() async {
        do {
            let userMe = try await profileAPIService.getUserMe()
            // Vérifier si l'utilisateur est PRO et si sa fiche établissement est vide
            let isPro = userMe.userType == "PROFESSIONAL" || userMe.userType == "PRO"
            let isEstablishmentEmpty = (userMe.establishmentName?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.establishmentDescription?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.address?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.city?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.postalCode?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.phoneNumber?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) ||
                                       (userMe.email?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            
            appState.showProfileBadge = isPro && isEstablishmentEmpty
        } catch {
            appState.showProfileBadge = false
        }
    }
    
    private func handlePushNotificationNavigation(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        print("[TabBarView] Gestion navigation depuis notification push: \(userInfo)")
        
        // Support du format recommandé avec "screen" et "entityId"
        if let screen = userInfo["screen"] as? String,
           let entityIdString = userInfo["entityId"] as? String,
           let entityId = Int(entityIdString) {
            
            switch screen {
            case "order_detail":
                // Navigation vers détail de commande (si implémenté)
                print("[TabBarView] Navigation vers order_detail: \(entityId)")
                // TODO: Implémenter la navigation vers OrderDetailView si nécessaire
                
            case "message_thread":
                // Navigation vers thread de message (si implémenté)
                print("[TabBarView] Navigation vers message_thread: \(entityId)")
                // TODO: Implémenter la navigation vers MessageThreadView si nécessaire
                
            case "offer_detail", "event_detail":
                // Navigation vers offre/événement
                print("[TabBarView] Navigation vers \(screen): \(entityId)")
                appState.selectedTab = .offers
                pushNotificationOfferId = entityId
                
            case "professional_detail", "partner_detail":
                // Navigation vers professionnel
                print("[TabBarView] Navigation vers \(screen): \(entityId)")
                appState.selectedTab = .home
                pushNotificationProfessionalId = entityId
                
            default:
                print("[TabBarView] Screen non reconnu: \(screen)")
            }
            
            return
        }
        
        // Support des formats existants (rétrocompatibilité)
        // Pour une nouvelle offre ou un événement
        // Le backend peut envoyer offerId comme Int ou String
        if let offerIdInt = userInfo["offerId"] as? Int {
            print("[TabBarView] Navigation vers offre (format legacy): \(offerIdInt)")
            appState.selectedTab = .offers
            pushNotificationOfferId = offerIdInt
        } else if let offerIdString = userInfo["offerId"] as? String,
                  let offerId = Int(offerIdString) {
            print("[TabBarView] Navigation vers offre (format legacy): \(offerId)")
            appState.selectedTab = .offers
            pushNotificationOfferId = offerId
        }
        
        // Pour un nouvel établissement
        // Le backend peut envoyer professionalId comme Int ou String
        if let professionalIdInt = userInfo["professionalId"] as? Int {
            print("[TabBarView] Navigation vers professionnel (format legacy): \(professionalIdInt)")
            appState.selectedTab = .home
            pushNotificationProfessionalId = professionalIdInt
        } else if let professionalIdString = userInfo["professionalId"] as? String,
                  let professionalId = Int(professionalIdString) {
            print("[TabBarView] Navigation vers professionnel (format legacy): \(professionalId)")
            appState.selectedTab = .home
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

