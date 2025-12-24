//
//  ProfileView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    @State private var showNotificationPreferences = false
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    @State private var proOffersNavigationId: UUID?
    @State private var manageEstablishmentNavigationId: UUID?
    @State private var helpSupportNavigationId: UUID?
    @State private var termsNavigationId: UUID?
    @State private var privacyPolicyNavigationId: UUID?
    @State private var selectedPartner: Partner?
    
    var body: some View {
        if isLoggedIn {
            profileContent
        } else {
            LoginView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
                    isLoggedIn = true
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
                            
                            // Badge CLUB10 au bout de la ligne
                            Text("MEMBRE CLUB10")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        
                        // Boutons Espace Client/Pro (si utilisateur PRO)
                        if viewModel.user.userType == .pro {
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.switchToClientSpace()
                                }) {
                                    Text("Espace Client")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(viewModel.currentSpace == .client ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(viewModel.currentSpace == .client ? Color.appGold : Color.appDarkRed1.opacity(0.6))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    viewModel.switchToProSpace()
                                }) {
                                    Text("Espace Pro")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(viewModel.currentSpace == .pro ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(viewModel.currentSpace == .pro ? Color.appGold : Color.appDarkRed1.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Bloc Abonnement PRO (uniquement si PRO et dans l'espace PRO)
                    if viewModel.user.userType == .pro && viewModel.currentSpace == .pro {
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
                        
                        // Bloc "Mes offres" (uniquement si PRO et dans l'espace PRO)
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
                    
                    // Menu options
                    VStack(spacing: 0) {
                        // Option "Gérer mon établissement" uniquement dans l'espace PRO
                        if viewModel.user.userType == .pro && viewModel.currentSpace == .pro {
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
                        }
                        
                        ProfileMenuRow(
                            icon: "person.fill",
                            title: "Modifier mon profil",
                            action: {
                                showEditProfile = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "bell.fill",
                            title: "Préférences de notifications",
                            action: {
                                showNotificationPreferences = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "lock.fill",
                            title: "Changer mon mot de passe",
                            action: {
                                showChangePassword = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "questionmark.circle.fill",
                            title: "Aide & Support",
                            action: {
                                helpSupportNavigationId = UUID()
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "doc.text.fill",
                            title: "Conditions générales",
                            action: {
                                termsNavigationId = UUID()
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "shield.fill",
                            title: "Politique de confidentialité",
                            action: {
                                privacyPolicyNavigationId = UUID()
                            }
                        )
                        
                        ProfileMenuRow(
                            icon: "person.fill",
                            title: "Modifier mon profil",
                            action: {
                                showEditProfile = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "bell.fill",
                            title: "Préférences de notifications",
                            action: {
                                showNotificationPreferences = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "lock.fill",
                            title: "Changer mon mot de passe",
                            action: {
                                showChangePassword = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
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
                        LoginViewModel.logout()
                        isLoggedIn = false
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
        .sheet(isPresented: $showNotificationPreferences) {
            NavigationStack {
                NotificationPreferencesView()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                EditProfileView()
            }
        }
        .sheet(isPresented: $showChangePassword) {
            NavigationStack {
                ChangePasswordView()
            }
        }
        .navigationDestination(item: $proOffersNavigationId) { _ in
            ProOffersView()
        }
        .navigationDestination(item: $manageEstablishmentNavigationId) { _ in
            ManageEstablishmentView()
        }
        .navigationDestination(item: $helpSupportNavigationId) { _ in
            HelpSupportView()
        }
        .navigationDestination(item: $termsNavigationId) { _ in
            TermsView(isPrivacyPolicy: false)
        }
        .navigationDestination(item: $privacyPolicyNavigationId) { _ in
            TermsView(isPrivacyPolicy: true)
        }
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = "Marie"
    @State private var lastName: String = "Dupont"
    @State private var email: String = "marie@email.fr"
    
    var body: some View {
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
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.appGold)
                            .frame(width: 100, height: 100)
                        
                        Text(String(firstName.prefix(1)).uppercased())
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prénom")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("", text: $firstName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("", text: $lastName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("", text: $email)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(12)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Enregistrer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appGold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Modifier mon profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Annuler") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
