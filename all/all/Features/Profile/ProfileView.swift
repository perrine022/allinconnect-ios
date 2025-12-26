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
        if isLoggedIn {
            profileContent
                .onAppear {
                    // Recharger les données d'abonnement quand on arrive sur la vue
                    viewModel.loadSubscriptionData()
                    // Recharger les offres si on est en espace pro
                    if viewModel.currentSpace == .pro {
                        viewModel.loadMyOffers()
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
    
    private var profileContent: some View {
        ZStack {
            // Background avec gradient
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
                VStack(spacing: 24) {
                    // Titre
                    HStack {
                        Text("Profil")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Section utilisateur
                    VStack(spacing: 16) {
                        // Photo, prénom et badge CLUB10 sur la même ligne
                        HStack(spacing: 12) {
                            // Avatar (réduit de 5 fois : 100/5 = 20)
                            ZStack {
                                Circle()
                                    .fill(Color.appGold)
                                    .frame(width: 20, height: 20)
                                
                                Text(String(viewModel.user.firstName.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            // Prénom
                            Text(viewModel.user.firstName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Badge CLUB10 au bout de la ligne - uniquement si abonnement actif
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
                        
                        // Boutons Espace Client/Pro (uniquement pour les professionnels)
                        if viewModel.user.userType == .pro {
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.switchToClientSpace()
                                }) {
                                    Text("Espace Client")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(viewModel.currentSpace == .client ? .black : .white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(viewModel.currentSpace == .client ? Color.appGold : Color.appDarkRed1.opacity(0.6))
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
                                        .background(viewModel.currentSpace == .pro ? Color.appGold : Color.appDarkRed1.opacity(0.6))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Bloc Abonnement PRO (dans l'espace PRO - toujours affiché)
                    if viewModel.currentSpace == .pro {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 18))
                                
                                Text("Abonnement Pro")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                // Prochain prélèvement
                                HStack {
                                    Text("Prochain prélèvement")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text(viewModel.nextPaymentDate)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Engagement
                                HStack {
                                    Text("Engagement jusqu'au")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text(viewModel.commitmentUntil)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.appDarkRed1.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Bloc "Mes offres" (dans l'espace PRO - toujours affiché)
                    if viewModel.currentSpace == .pro {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 18))
                                
                                Text("Mes offres")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            // Liste des offres (limitées à 3 pour l'aperçu)
                            if viewModel.myOffers.isEmpty {
                                Text("Aucune offre pour le moment")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(Array(viewModel.myOffers.prefix(3))) { offer in
                                        HStack(spacing: 10) {
                                            Image(systemName: offer.imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .foregroundColor(.gray.opacity(0.3))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(offer.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text("Jusqu'au \(offer.validUntil)")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        if offer.id != viewModel.myOffers.prefix(3).last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                            }
                            
                            // Bouton "Gérer mes offres"
                            Button(action: {
                                proOffersNavigationId = UUID()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Gérer mes offres")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .background(Color.appGold)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color.appDarkRed1.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Section Abonnement et Carte (espace client)
                    if viewModel.currentSpace == .client {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 18))
                                
                                Text("Mon abonnement")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            // Type de carte
                            if let cardType = viewModel.cardType {
                                HStack {
                                    Text("Type de carte:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text(viewModel.formattedCardType)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                            }
                            
                            // Abonnement actif
                            if viewModel.hasActiveClub10Subscription {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Abonnement actif")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
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
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if !viewModel.club10Amount.isEmpty {
                                        HStack {
                                            Text("Montant:")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(.gray.opacity(0.9))
                                            
                                            Spacer()
                                            
                                            Text(viewModel.club10Amount)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            } else {
                                Text("Aucun abonnement actif")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Bouton pour gérer les emails de la carte famille
                            if (viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY") && viewModel.isCardOwner {
                                Button(action: {
                                    familyCardEmailsNavigationId = UUID()
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Gérer les emails de la carte famille")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .background(Color.appGold)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.appDarkRed1.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Bloc "Mes favoris" (espace client uniquement)
                    if viewModel.currentSpace == .client {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 18))
                                
                                Text("Mes favoris")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if viewModel.isLoadingFavorites {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            // Liste des favoris
                            if viewModel.favoritePartners.isEmpty {
                                Text("Aucun favori pour le moment")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.favoritePartners.prefix(5))) { partner in
                                        Button(action: {
                                            selectedPartner = partner
                                        }) {
                                            HStack(spacing: 12) {
                                                // Icône ou image
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.appGold.opacity(0.2))
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: partner.imageName)
                                                        .foregroundColor(.appGold)
                                                        .font(.system(size: 20))
                                                }
                                                
                                                // Informations
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(partner.name)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                    
                                                    Text(partner.category)
                                                        .font(.system(size: 13, weight: .regular))
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                                
                                                Spacer()
                                                
                                                // Bouton pour retirer des favoris
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
                                                .background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                            }
                            
                            // Message d'erreur
                            if let error = viewModel.favoritesError {
                                Text(error)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.red.opacity(0.9))
                            }
                        }
                        .padding(16)
                        .background(Color.appDarkRed1.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Menu options
                    VStack(spacing: 0) {
                        // Options PRO uniquement dans l'espace PRO (toujours affichées pour les tests)
                        if viewModel.currentSpace == .pro {
                            ProfileMenuRow(
                                icon: "building.2.fill",
                                title: "Gérer mon établissement",
                                action: {
                                    manageEstablishmentNavigationId = UUID()
                                }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 54)
                            
                            ProfileMenuRow(
                                icon: "creditcard.fill",
                                title: "Gérer mes abonnements",
                                action: {
                                    manageSubscriptionsNavigationId = UUID()
                                }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 54)
                        }
                        
                        // Options CLUB10 (espace client)
                        if viewModel.currentSpace == .client {
                            ProfileMenuRow(
                                icon: "creditcard.fill",
                                title: "Gérer mes abonnements",
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
                    
                    // Bouton déconnexion
                    Button(action: {
                        // Afficher une confirmation avant de déconnecter
                        withAnimation {
                            // Déconnecter l'utilisateur
                            LoginViewModel.logout()
                            // Réinitialiser l'état local
                            isLoggedIn = false
                            // Réinitialiser le ViewModel
                            viewModel.reset()
                            // Naviguer vers l'onglet Accueil après déconnexion
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
                        .foregroundColor(.appRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appRed, lineWidth: 1.5)
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Version de l'app
                    Text("All In Connect v1.0.0")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, address, city, birthDay, birthMonth, birthYear
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                    .scaleEffect(1.5)
                                    .padding(.vertical, 20)
                            }
                            
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.appGold)
                                    .frame(width: 100, height: 100)
                                
                                Text(String(viewModel.firstName.prefix(1)).uppercased())
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 8)
                            
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
                                    viewModel.checkForChanges()
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
                                    viewModel.checkForChanges()
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
                                    viewModel.checkForChanges()
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
                                    viewModel.checkForChanges()
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
                                    viewModel.checkForChanges()
                                }
                                
                                // Date de naissance
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date de naissance")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    HStack(spacing: 12) {
                                        // Jour
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Jour")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray.opacity(0.7))
                                            
                                            TextField("", text: $viewModel.birthDay, prompt: Text("JJ").foregroundColor(.gray.opacity(0.5)))
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                                .focused($focusedField, equals: .birthDay)
                                                .frame(width: 60)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 12)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthDay) { _, newValue in
                                                    // Filtrer pour garder uniquement les chiffres
                                                    let digitsOnly = newValue.filter { $0.isNumber }
                                                    if digitsOnly != newValue {
                                                        viewModel.birthDay = digitsOnly
                                                        return
                                                    }
                                                    
                                                    // Limiter à 2 chiffres max
                                                    if digitsOnly.count > 2 {
                                                        viewModel.birthDay = String(digitsOnly.prefix(2))
                                                    } else {
                                                        viewModel.birthDay = digitsOnly
                                                    }
                                                    
                                                    // Valider que c'est un nombre entre 1 et 31
                                                    if let day = Int(viewModel.birthDay), day > 31 {
                                                        viewModel.birthDay = "31"
                                                    }
                                                    
                                                    viewModel.checkForChanges()
                                                }
                                        }
                                        
                                        // Mois
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Mois")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray.opacity(0.7))
                                            
                                            TextField("", text: $viewModel.birthMonth, prompt: Text("MM").foregroundColor(.gray.opacity(0.5)))
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                                .focused($focusedField, equals: .birthMonth)
                                                .frame(width: 60)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 12)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthMonth) { _, newValue in
                                                    // Filtrer pour garder uniquement les chiffres
                                                    let digitsOnly = newValue.filter { $0.isNumber }
                                                    if digitsOnly != newValue {
                                                        viewModel.birthMonth = digitsOnly
                                                        return
                                                    }
                                                    
                                                    // Limiter à 2 chiffres max
                                                    if digitsOnly.count > 2 {
                                                        viewModel.birthMonth = String(digitsOnly.prefix(2))
                                                    } else {
                                                        viewModel.birthMonth = digitsOnly
                                                    }
                                                    
                                                    // Valider que c'est un nombre entre 1 et 12
                                                    if let month = Int(viewModel.birthMonth), month > 12 {
                                                        viewModel.birthMonth = "12"
                                                    }
                                                    
                                                    viewModel.checkForChanges()
                                                }
                                        }
                                        
                                        // Année
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Année")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.gray.opacity(0.7))
                                            
                                            TextField("", text: $viewModel.birthYear, prompt: Text("AAAA").foregroundColor(.gray.opacity(0.5)))
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                                .focused($focusedField, equals: .birthYear)
                                                .frame(width: 80)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 12)
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthYear) { _, newValue in
                                                    // Filtrer pour garder uniquement les chiffres
                                                    let digitsOnly = newValue.filter { $0.isNumber }
                                                    if digitsOnly != newValue {
                                                        viewModel.birthYear = digitsOnly
                                                        return
                                                    }
                                                    
                                                    // Limiter à 4 chiffres max
                                                    if digitsOnly.count > 4 {
                                                        viewModel.birthYear = String(digitsOnly.prefix(4))
                                                    } else {
                                                        viewModel.birthYear = digitsOnly
                                                    }
                                                    
                                                    // Valider que l'année est avant l'année actuelle
                                                    let currentYear = Calendar.current.component(.year, from: Date())
                                                    if let year = Int(viewModel.birthYear), year > currentYear {
                                                        viewModel.birthYear = String(currentYear)
                                                    }
                                                    
                                                    viewModel.checkForChanges()
                                                }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Message d'erreur pour la date
                                    if let dateError = viewModel.birthDateError {
                                        Text(dateError)
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Bouton Enregistrer
                            Button(action: {
                                viewModel.saveProfile()
                                // Fermer après succès
                                if viewModel.successMessage != nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Enregistrer")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((viewModel.isValid && !viewModel.isLoading) ? Color.appGold : Color.gray.opacity(0.5))
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
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {
                            dismiss()
                        })
                    }
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppState())
    }
}
