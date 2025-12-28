//
//  OnboardingView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @FocusState private var focusedField: Field?
    @State private var showLogin = false
    var onComplete: () -> Void
    
    enum Field {
        case firstName, lastName, email, postalCode
    }
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Logo
                    VStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Text("ALL")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            ZStack {
                                Circle().fill(Color.appRed).frame(width: 22, height: 22)
                                Circle().fill(Color.appRed.opacity(0.6)).frame(width: 19, height: 19)
                                Circle().fill(Color.appRed.opacity(0.3)).frame(width: 16, height: 16)
                            }
                            Text("IN")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("Connect")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appRed.opacity(0.9))
                    }
                    .padding(.top, 20)
                    
                    // Titre
                    Text("Bienvenue !")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    Text("Pour commencer, nous avons besoin de quelques informations")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 4)
                    
                    // Bouton Se connecter
                    Button(action: {
                        // Fake connexion pour l'instant
                        UserDefaults.standard.set(true, forKey: "is_logged_in")
                        UserDefaults.standard.set("fake@email.com", forKey: "user_email")
                        hideKeyboard()
                        onComplete()
                    }) {
                        Text("Se connecter")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appGold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Formulaire
                    VStack(spacing: 12) {
                        // Prénom
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prénom")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.firstName, prompt: Text("Votre prénom").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .firstName)
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .lastName
                                }
                        }
                        
                        // Nom
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nom")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.lastName, prompt: Text("Votre nom").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .lastName)
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.words)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .email
                                }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.email, prompt: Text("votre@email.com").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(viewModel.emailError != nil ? Color.red.opacity(0.1) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.emailError != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .postalCode
                                }
                            
                            if let error = viewModel.emailError {
                                Text(error)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Code postal
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Code postal")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.postalCode, prompt: Text("69001").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .postalCode)
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(viewModel.postalCodeError != nil ? Color.red.opacity(0.1) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.postalCodeError != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .onChange(of: viewModel.postalCode) { _, newValue in
                                    // Limiter à 5 chiffres uniquement
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count <= 5 {
                                        viewModel.postalCode = filtered
                                    } else {
                                        viewModel.postalCode = String(filtered.prefix(5))
                                    }
                                }
                            
                            if let error = viewModel.postalCodeError {
                                Text(error)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Bouton continuer
                    Button(action: {
                        if viewModel.isComplete {
                            viewModel.saveUserInfo()
                            hideKeyboard()
                            onComplete()
                        }
                    }) {
                        Text("Continuer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.isComplete ? Color.appGold : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isComplete)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Message d'aide
                    if !viewModel.isComplete && (!viewModel.firstName.isEmpty || !viewModel.lastName.isEmpty || !viewModel.email.isEmpty || !viewModel.postalCode.isEmpty) {
                        Text("Veuillez remplir tous les champs correctement")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.top, 6)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}

