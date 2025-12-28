//
//  ChangePasswordView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChangePasswordViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
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
                            
                            // Formulaire
                            VStack(spacing: 20) {
                                // Mot de passe actuel
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mot de passe actuel")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if viewModel.showOldPassword {
                                            TextField("", text: $viewModel.oldPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else {
                                            SecureField("", text: $viewModel.oldPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Button(action: {
                                            viewModel.showOldPassword.toggle()
                                        }) {
                                            Image(systemName: viewModel.showOldPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                                
                                // Nouveau mot de passe
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nouveau mot de passe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if viewModel.showNewPassword {
                                            TextField("", text: $viewModel.newPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else {
                                            SecureField("", text: $viewModel.newPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Button(action: {
                                            viewModel.showNewPassword.toggle()
                                        }) {
                                            Image(systemName: viewModel.showNewPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    
                                    if !viewModel.newPassword.isEmpty && viewModel.newPassword.count < 6 {
                                        Text("Le mot de passe doit contenir au moins 6 caractères")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                // Confirmer nouveau mot de passe
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirmer le nouveau mot de passe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        if viewModel.showConfirmPassword {
                                            TextField("", text: $viewModel.confirmPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else {
                                            SecureField("", text: $viewModel.confirmPassword)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Button(action: {
                                            viewModel.showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: viewModel.showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    
                                    if !viewModel.confirmPassword.isEmpty && viewModel.newPassword != viewModel.confirmPassword {
                                        Text("Les mots de passe ne correspondent pas")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Bouton valider
                            Button(action: {
                                viewModel.changePassword()
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
                                        Text("Valider")
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
        ChangePasswordView()
            .environmentObject(AppState())
    }
}

