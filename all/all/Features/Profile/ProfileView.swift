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
    @State private var showHelpSupport = false
    @State private var showTerms = false
    @State private var showPrivacyPolicy = false
    @State private var showProOffers = false
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
                    // Section utilisateur
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.appGold)
                                .frame(width: 100, height: 100)
                            
                            Text(String(viewModel.user.firstName.prefix(1)).uppercased())
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        // Nom
                        Text(viewModel.user.fullName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Email
                        Text("marie@email.fr")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Badge CLUB10 et boutons Espace (si PRO)
                        VStack(spacing: 12) {
                            Text("MEMBRE CLUB10")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                            
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
                            }
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
                    }
                    
                    // Menu options
                    VStack(spacing: 0) {
                        // Option "Mes offres" uniquement dans l'espace PRO
                        if viewModel.user.userType == .pro && viewModel.currentSpace == .pro {
                            ProfileMenuRow(
                                icon: "tag.fill",
                                title: "Mes offres",
                                action: {
                                    showProOffers = true
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
                                showHelpSupport = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "doc.text.fill",
                            title: "Conditions générales",
                            action: {
                                showTerms = true
                            }
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 54)
                        
                        ProfileMenuRow(
                            icon: "shield.fill",
                            title: "Politique de confidentialité",
                            action: {
                                showPrivacyPolicy = true
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
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $showHelpSupport) {
            NavigationStack {
                HelpSupportView()
            }
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                TermsView(isPrivacyPolicy: false)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                TermsView(isPrivacyPolicy: true)
            }
        }
        .sheet(isPresented: $showProOffers) {
            NavigationStack {
                ProOffersView()
            }
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
