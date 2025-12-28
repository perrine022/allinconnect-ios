//
//  LoginView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct LoginView: View {
    @Binding var signUpNavigationId: UUID?
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LoginViewModel()
    @State private var showForgotPassword = false
    
    init(signUpNavigationId: Binding<UUID?> = .constant(nil)) {
        self._signUpNavigationId = signUpNavigationId
    }
    @State private var showPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Logo
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("ALL")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            ZStack {
                                Circle().fill(Color.appRed).frame(width: 32, height: 32)
                                Circle().fill(Color.appRed.opacity(0.6)).frame(width: 28, height: 28)
                                Circle().fill(Color.appRed.opacity(0.3)).frame(width: 24, height: 24)
                            }
                            Text("IN")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("Connect")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.appRed.opacity(0.9))
                    }
                    .padding(.top, 40)
                    
                    // Titre
                    Text("Connexion")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Formulaire
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.email, prompt: Text("votre@email.com").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .password
                                }
                        }
                        
                        // Mot de passe
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mot de passe")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack {
                                if showPassword {
                                    TextField("", text: $viewModel.password, prompt: Text("Votre mot de passe").foregroundColor(.gray.opacity(0.6)))
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                } else {
                                    SecureField("", text: $viewModel.password, prompt: Text("Votre mot de passe").foregroundColor(.gray.opacity(0.6)))
                                        .focused($focusedField, equals: .password)
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .submitLabel(.go)
                            .onSubmit {
                                if viewModel.isValid {
                                    viewModel.login()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Message d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 20)
                    }
                    
                    // Bouton se connecter
                    Button(action: {
                        hideKeyboard()
                        viewModel.login()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Se connecter")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isValid && !viewModel.isLoading ? Color.appGold : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Mot de passe oublié
                    HStack {
                        Spacer()
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Mot de passe oublié ?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appGold)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    // Ligne de séparation
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Bouton Inscrivez-vous
                    Button(action: {
                        signUpNavigationId = UUID()
                    }) {
                        Text("Inscrivez-vous")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appGold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
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
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $showForgotPassword) {
            NavigationStack {
                ForgotPasswordView()
            }
        }
    }
}

// Wrapper pour LoginView depuis allApp (sans besoin de binding externe)
struct LoginViewWrapper: View {
    @State private var signUpNavigationId: UUID?
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            LoginView(signUpNavigationId: $signUpNavigationId)
                .navigationDestination(item: $signUpNavigationId) { _ in
                    SignUpView()
                        .environmentObject(appState)
                }
        }
    }
}

#Preview {
    LoginView()
}

