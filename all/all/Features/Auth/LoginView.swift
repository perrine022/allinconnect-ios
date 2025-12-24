//
//  LoginView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct LoginView: View {
    @Binding var signUpNavigationId: UUID?
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
                    .padding(.top, 60)
                    
                    // Titre
                    Text("Connexion")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Formulaire
                    VStack(spacing: 20) {
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
                    .padding(.top, 20)
                    
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
                    .padding(.top, 10)
                    
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
                    .padding(.top, 12)
                    
                    // Ligne de séparation
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
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
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 40)
                }
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

#Preview {
    LoginView()
}

