//
//  ProfileView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    @State private var notificationPreferencesNavigationId: UUID?
    @State private var editProfileNavigationId: UUID?
    @State private var proOffersNavigationId: UUID?
    @State private var manageEstablishmentNavigationId: UUID?
    @State private var manageSubscriptionsNavigationId: UUID?
    @State private var settingsNavigationId: UUID?
    @State private var selectedPartner: Partner?
    @State private var signUpNavigationId: UUID?
    @State private var familyCardEmailsNavigationId: UUID?
    
    var body: some View {
        Group {
            if isLoggedIn {
                profileContent
                    .onAppear {
                        // Les données sont déjà chargées dans loadInitialData() lors de l'init
                        // On peut recharger si nécessaire
                        if !viewModel.isLoadingInitialData {
                            Task {
                                await viewModel.loadSubscriptionData()
                                if viewModel.currentSpace == .pro {
                                    viewModel.loadMyOffers()
                                }
                                if viewModel.currentSpace == .client {
                                    await viewModel.loadFavorites()
                                    // Charger aussi les offres si l'utilisateur a une carte professionnelle
                                    if viewModel.cardType == "PROFESSIONAL" {
                                        viewModel.loadMyOffers()
                                    }
                                }
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
                        // Réinitialiser l'état lors de la déconnexion
                        isLoggedIn = false
                        // Réinitialiser le ViewModel pour nettoyer les données
                        viewModel.reset()
                    }
            } else {
                NavigationStack {
                    LoginView(signUpNavigationId: $signUpNavigationId)
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
                            isLoggedIn = true
                        }
                        .navigationDestination(item: $signUpNavigationId) { _ in
                            SignUpView()
                        }
                }
            }
        }
        .navigationDestination(item: $notificationPreferencesNavigationId) { _ in
            NotificationPreferencesView()
        }
        .navigationDestination(item: $editProfileNavigationId) { _ in
            EditProfileView()
        }
        .navigationDestination(item: $proOffersNavigationId) { _ in
            ProOffersView()
        }
        .navigationDestination(item: $manageEstablishmentNavigationId) { _ in
            ManageEstablishmentView()
        }
        .navigationDestination(item: $manageSubscriptionsNavigationId) { _ in
            ManageSubscriptionsView()
        }
        .navigationDestination(item: $settingsNavigationId) { _ in
            SettingsView()
        }
        .navigationDestination(item: $familyCardEmailsNavigationId) { _ in
            FamilyCardEmailsView(viewModel: FamilyCardEmailsViewModel())
        }
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToManageEstablishment"))) { _ in
            // Navigation forcée vers "Gérer mon établissement" pour les pros après paiement
            manageEstablishmentNavigationId = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EstablishmentUpdated"))) { _ in
            // Recharger les données pour mettre à jour le badge après sauvegarde de l'établissement
            Task {
                await viewModel.loadSubscriptionData()
            }
        }
    }
    
    private var profileContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                    .ignoresSafeArea()
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                profileTitle
                                profileLoadingView
                                profileUserSection
                                profileSubscriptionSection
                                profileOffersSection
                                profileFavoritesSection
                                profileMenuSection
                                profileLogoutButton
                                profileVersionText
                                
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToTop"))) { notification in
                            if let tab = notification.userInfo?["tab"] as? TabItem, tab == .profile {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            }
                        }
                    }
                }
            
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(
                        selectedTab: $appState.selectedTab,
                        onTabSelected: { tab in
                            appState.navigateToTab(tab, dismiss: {
                                // Pas de dismiss ici car on est déjà dans la vue principale
                            })
                        },
                        showProfileBadge: appState.showProfileBadge
                    )
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Profile Subviews
    private var profileTitle: some View {
        HStack {
            Text("Profil")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .id("top")
    }
    
    @ViewBuilder
    private var profileLoadingView: some View {
        if viewModel.isLoadingInitialData && !viewModel.hasLoadedOnce {
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .appDarkRedButton))
                    .scaleEffect(1.5)
                
                Text("Chargement de votre profil...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 100)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingInitialData)
        }
    }
    
    @ViewBuilder
    private var profileUserSection: some View {
        if viewModel.hasLoadedOnce {
            VStack(spacing: 16) {
                // Photo, prénom et badge CLUB10 sur la même ligne
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        if !viewModel.user.firstName.isEmpty {
                            Text(String(viewModel.user.firstName.prefix(1)).uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    
                    // Prénom
                    if !viewModel.user.firstName.isEmpty {
                        Text(viewModel.user.firstName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 100, height: 24)
                    }
                
                    Spacer()
                    
                    // Badge CLUB10
                    if viewModel.hasActiveClub10Subscription || (viewModel.user.userType == .pro && viewModel.hasActiveProSubscription) {
                        Text("MEMBRE CLUB10")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 20)
                
                // Boutons Espace Client/Pro
                if !viewModel.user.firstName.isEmpty && viewModel.user.userType == .pro {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.switchToClientSpace()
                        }) {
                            Text("Espace Client")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.currentSpace == .client ? .black : .white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(viewModel.currentSpace == .client ? Color.red : Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            viewModel.switchToProSpace()
                        }) {
                            Text("Espace Pro")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.currentSpace == .pro ? .black : .white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(viewModel.currentSpace == .pro ? Color.red : Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
        }
    }
    
    @ViewBuilder
    private var profileSubscriptionSection: some View {
        if viewModel.hasLoadedOnce {
            if viewModel.currentSpace == .pro {
                proSubscriptionBlock
            } else {
                clientSubscriptionBlock
            }
        }
    }
    
    private var proSubscriptionBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                
                Text("Abonnement Pro")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Prochain prélèvement")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Spacer()
                    
                    Text(viewModel.nextPaymentDate)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                if !viewModel.formattedCardValidityDate.isEmpty {
                    HStack {
                        Text("Engagement jusqu'au")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        Spacer()
                        
                        Text(viewModel.formattedCardValidityDate)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var clientSubscriptionBlock: some View {
        let isFamilyCardNonOwner = (viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY") && !viewModel.isCardOwner
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                
                Text("Mon abonnement")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isFamilyCardNonOwner ? .black : .white)
                
                Spacer()
            }
            
            if viewModel.cardType != nil {
                HStack {
                    Text("Type de carte:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFamilyCardNonOwner ? .gray.opacity(0.9) : .white.opacity(0.9))
                    
                    Spacer()
                    
                    Text(viewModel.formattedCardType)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            if viewModel.hasActiveClub10Subscription {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Abonnement actif")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isFamilyCardNonOwner ? .gray.opacity(0.9) : .white.opacity(0.9))
                        
                        Spacer()
                        
                        Text("ACTIF")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                    
                    if !viewModel.club10NextPaymentDate.isEmpty {
                        HStack {
                            Text("Prochain paiement:")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                            
                            Spacer()
                            
                            Text(viewModel.club10NextPaymentDate)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isFamilyCardNonOwner ? .black : .white)
                        }
                    }
                    
                    if viewModel.user.userType == .pro {
                        HStack {
                            Text("Abonnement:")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                            
                            Spacer()
                            
                            Text("Lié à votre abonnement pro")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isFamilyCardNonOwner ? .black : .white)
                        }
                    } else if !viewModel.club10Amount.isEmpty {
                        HStack {
                            Text("Montant:")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                            
                            Spacer()
                            
                            Text(viewModel.club10Amount)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isFamilyCardNonOwner ? .black : .white)
                        }
                    }
                }
            } else {
                Text("Aucun abonnement actif")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isFamilyCardNonOwner ? .gray.opacity(0.7) : .white.opacity(0.7))
            }
        }
        .padding(16)
        .background(isFamilyCardNonOwner ? Color.white : Color.appDarkRed1.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFamilyCardNonOwner ? Color.gray.opacity(0.2) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var profileOffersSection: some View {
        if viewModel.hasLoadedOnce && ((viewModel.currentSpace == .pro) || (viewModel.cardType == "PROFESSIONAL" && viewModel.currentSpace == .pro)) {
            offersBlock
        }
    }
    
    private var offersBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                
                Text("Mes offres")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            if viewModel.myOffers.isEmpty {
                Text("Aucune offre pour le moment")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray.opacity(0.7))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.myOffers.prefix(3))) { offer in
                        HStack(spacing: 10) {
                            OfferImage(offer: offer, contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(offer.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                Text("Jusqu'au \(offer.validUntil)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        
                        if offer.id != viewModel.myOffers.prefix(3).last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
            
            Button(action: {
                proOffersNavigationId = UUID()
            }) {
                HStack {
                    Spacer()
                    Text("Gérer mes offres")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var profileFavoritesSection: some View {
        if viewModel.hasLoadedOnce && viewModel.currentSpace == .client {
            favoritesBlock
        }
    }
    
    private var favoritesBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
                
                Text("Mes favoris")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                if viewModel.isLoadingFavorites {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(0.8)
                }
            }
            
            if let error = viewModel.favoritesError {
                Text(error)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.vertical, 8)
            }
            
            if viewModel.favoritePartners.isEmpty && !viewModel.isLoadingFavorites {
                Text("Aucun favori pour le moment")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray.opacity(0.7))
            } else if !viewModel.favoritePartners.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.favoritePartners.prefix(5))) { partner in
                        Button(action: {
                            selectedPartner = partner
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: partner.imageName)
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(partner.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                    
                                    Text(partner.category)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.togglePartnerFavorite(for: partner)
                                }) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.appRed)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if partner.id != viewModel.favoritePartners.prefix(5).last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var profileMenuSection: some View {
        if viewModel.hasLoadedOnce {
            VStack(spacing: 0) {
                if viewModel.currentSpace == .pro {
                    ProfileMenuRow(
                        icon: "building.2.fill",
                        title: "Gérer mon établissement",
                        showBadge: viewModel.isEstablishmentEmpty,
                        action: {
                            manageEstablishmentNavigationId = UUID()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 54)
                    
                    ProfileMenuRow(
                        icon: "creditcard.fill",
                        title: "Gérer mon abonnement",
                        action: {
                            manageSubscriptionsNavigationId = UUID()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 54)
                }
                
                if viewModel.currentSpace == .client && viewModel.user.userType != .pro {
                    ProfileMenuRow(
                        icon: "creditcard.fill",
                        title: "Gérer mon abonnement",
                        action: {
                            manageSubscriptionsNavigationId = UUID()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 54)
                }
                
                ProfileMenuRow(
                    icon: "person.fill",
                    title: "Modifier mon profil",
                    action: {
                        editProfileNavigationId = UUID()
                    }
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 54)
                
                ProfileMenuRow(
                    icon: "bell.fill",
                    title: "Préférences de notifications",
                    action: {
                        notificationPreferencesNavigationId = UUID()
                    }
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 54)
                
                ProfileMenuRow(
                    icon: "gearshape.fill",
                    title: "Paramètres",
                    action: {
                        settingsNavigationId = UUID()
                    }
                )
            }
            .background(Color.appDarkRed1.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var profileLogoutButton: some View {
        if viewModel.hasLoadedOnce {
            Button(action: {
                withAnimation {
                    LoginViewModel.logout()
                    isLoggedIn = false
                    viewModel.reset()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appState.selectedTab = .home
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                    
                    Text("Déconnexion")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appRed)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var profileVersionText: some View {
        if viewModel.hasLoadedOnce {
            Text("All In Connect v1.0.0")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 8)
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, address, city, postalCode
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.appDarkRed2,
                            Color.appDarkRed1,
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Titre
                            HStack {
                                Text("Modifier mon profil")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Indicateur de chargement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .appDarkRedButton))
                                    .scaleEffect(1.5)
                                    .padding(.vertical, 20)
                            }
                            
                            // Messages d'erreur et de succès
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                            }
                            
                            VStack(spacing: 16) {
                                // Nom (avant prénom)
                                SignUpInputField(
                                    title: "Nom *",
                                    text: $viewModel.lastName,
                                    placeholder: "Votre nom",
                                    isFocused: focusedField == .lastName
                                )
                                .focused($focusedField, equals: .lastName)
                                .onChange(of: viewModel.lastName) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                                // Prénom
                                SignUpInputField(
                                    title: "Prénom *",
                                    text: $viewModel.firstName,
                                    placeholder: "Votre prénom",
                                    isFocused: focusedField == .firstName
                                )
                                .focused($focusedField, equals: .firstName)
                                .onChange(of: viewModel.firstName) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                                // Email
                                SignUpInputField(
                                    title: "Email *",
                                    text: $viewModel.email,
                                    placeholder: "votre@email.com",
                                    keyboardType: .emailAddress,
                                    isFocused: focusedField == .email
                                )
                                .focused($focusedField, equals: .email)
                                .autocapitalization(.none)
                                .onChange(of: viewModel.email) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                                // Adresse
                                SignUpInputField(
                                    title: "Adresse (optionnel)",
                                    text: $viewModel.address,
                                    placeholder: "Ex: 45 Rue de la République",
                                    isFocused: focusedField == .address
                                )
                                .focused($focusedField, equals: .address)
                                .onChange(of: viewModel.address) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                                // Ville
                                SignUpInputField(
                                    title: "Ville",
                                    text: $viewModel.city,
                                    placeholder: "Ex: Paris",
                                    isFocused: focusedField == .city
                                )
                                .focused($focusedField, equals: .city)
                                .onChange(of: viewModel.city) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                                // Code postal
                                SignUpInputField(
                                    title: "Code postal",
                                    text: $viewModel.postalCode,
                                    placeholder: "Ex: 75001",
                                    keyboardType: .numberPad,
                                    isFocused: focusedField == .postalCode
                                )
                                .focused($focusedField, equals: .postalCode)
                                .onChange(of: viewModel.postalCode) { _, _ in
                                    Task { @MainActor in
                                        viewModel.checkForChanges()
                                    }
                                }
                                
                            }
                            
                            // Bouton Enregistrer
                            Button(action: {
                                viewModel.saveProfile()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Enregistrer")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((viewModel.isValid && !viewModel.isLoading) ? Color.red : Color.gray.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.isValid || viewModel.isLoading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(
                        selectedTab: $appState.selectedTab,
                        onTabSelected: { tab in
                            appState.navigateToTab(tab, dismiss: {
                                dismiss()
                            })
                        },
                        showProfileBadge: appState.showProfileBadge
                    )
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onReceive(viewModel.$successMessage) { successMessage in
            if successMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppState())
    }
}
