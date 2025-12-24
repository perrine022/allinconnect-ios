//
//  ChangePasswordView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                                Text("Changer mon mot de passe")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Formulaire
                            VStack(spacing: 20) {
                                // Mot de passe actuel
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mot de passe actuel")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if showCurrentPassword {
                                            TextField("", text: $currentPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("", text: $currentPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Button(action: {
                                            showCurrentPassword.toggle()
                                        }) {
                                            Image(systemName: showCurrentPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(10)
                                }
                                
                                // Nouveau mot de passe
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nouveau mot de passe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if showNewPassword {
                                            TextField("", text: $newPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("", text: $newPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Button(action: {
                                            showNewPassword.toggle()
                                        }) {
                                            Image(systemName: showNewPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(10)
                                }
                                
                                // Confirmer nouveau mot de passe
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirmer le nouveau mot de passe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if showConfirmPassword {
                                            TextField("", text: $confirmPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        } else {
                                            SecureField("", text: $confirmPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Bouton valider
                            Button(action: {
                                // Action changer mot de passe
                            }) {
                                Text("Valider")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appGold)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {})
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
        ChangePasswordView()
            .environmentObject(AppState())
    }
}

