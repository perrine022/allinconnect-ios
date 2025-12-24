//
//  SignUpView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SignUpViewModel()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var clientSubscriptionNavigationId: UUID?
    @State private var proSubscriptionNavigationId: UUID?
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, password, confirmPassword, postalCode
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
                        VStack(spacing: 24) {
                            // Titre avec bouton retour
                            HStack {
                                Button(action: {
                                    dismiss()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text("Retour")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Titre
                            Text("Inscription")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            
                            // Formulaire
                            VStack(spacing: 16) {
                                // Prénom
                                SignUpInputField(
                                    title: "Prénom",
                                    text: $viewModel.firstName,
                                    placeholder: "Votre prénom",
                                    isFocused: focusedField == .firstName
                                )
                                .focused($focusedField, equals: .firstName)
                                
                                // Nom
                                SignUpInputField(
                                    title: "Nom",
                                    text: $viewModel.lastName,
                                    placeholder: "Votre nom",
                                    isFocused: focusedField == .lastName
                                )
                                .focused($focusedField, equals: .lastName)
                                
                                // Email
                                SignUpInputField(
                                    title: "Email",
                                    text: $viewModel.email,
                                    placeholder: "votre@email.com",
                                    keyboardType: .emailAddress,
                                    isFocused: focusedField == .email
                                )
                                .focused($focusedField, equals: .email)
                                .autocapitalization(.none)
                                
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
                                    .background(focusedField == .password ? Color.white.opacity(0.95) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(focusedField == .password ? Color.appGold : Color.clear, lineWidth: 2)
                                    )
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                
                                // Confirmer mot de passe
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Confirmer le mot de passe")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                        
                                        // Indicateur de correspondance
                                        if !viewModel.confirmPassword.isEmpty {
                                            if viewModel.password == viewModel.confirmPassword {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.system(size: 14))
                                                    Text("Correspond")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.green)
                                                }
                                            } else {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 14))
                                                    Text("Ne correspond pas")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                    }
                                    
                                    HStack {
                                        if showConfirmPassword {
                                            TextField("", text: $viewModel.confirmPassword, prompt: Text("Confirmez votre mot de passe").foregroundColor(.gray.opacity(0.6)))
                                                .focused($focusedField, equals: .confirmPassword)
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                        } else {
                                            SecureField("", text: $viewModel.confirmPassword, prompt: Text("Confirmez votre mot de passe").foregroundColor(.gray.opacity(0.6)))
                                                .focused($focusedField, equals: .confirmPassword)
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                        }
                                        
                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(focusedField == .confirmPassword ? Color.white.opacity(0.95) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                focusedField == .confirmPassword ? Color.appGold : 
                                                (!viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword) ? Color.red : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                
                                // Code postal
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Code postal")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                        
                                        if !viewModel.postalCode.isEmpty {
                                            Text("\(viewModel.postalCode.count)/5")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(viewModel.postalCode.count == 5 ? .green : .gray.opacity(0.7))
                                        }
                                    }
                                    
                                    TextField("", text: $viewModel.postalCode, prompt: Text("69001").foregroundColor(.gray.opacity(0.6)))
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(focusedField == .postalCode ? Color.white.opacity(0.95) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(focusedField == .postalCode ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(10)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .postalCode)
                                        .onChange(of: viewModel.postalCode) { oldValue, newValue in
                                            // Limiter à 5 chiffres uniquement
                                            let filtered = newValue.filter { $0.isNumber }
                                            if filtered.count <= 5 {
                                                viewModel.postalCode = filtered
                                            } else {
                                                viewModel.postalCode = String(filtered.prefix(5))
                                            }
                                        }
                                }
                                .padding(.horizontal, 20)
                                
                                // Choix Client/Pro
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Type de compte")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            viewModel.userType = .client
                                        }) {
                                            HStack {
                                                Image(systemName: viewModel.userType == .client ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(viewModel.userType == .client ? .appGold : .gray.opacity(0.6))
                                                
                                                Text("Client")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(viewModel.userType == .client ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.4))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(viewModel.userType == .client ? Color.appGold : Color.clear, lineWidth: 2)
                                            )
                                            .cornerRadius(10)
                                        }
                                        
                                        Button(action: {
                                            viewModel.userType = .pro
                                        }) {
                                            HStack {
                                                Image(systemName: viewModel.userType == .pro ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(viewModel.userType == .pro ? .appGold : .gray.opacity(0.6))
                                                
                                                Text("Pro")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(viewModel.userType == .pro ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.4))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(viewModel.userType == .pro ? Color.appGold : Color.clear, lineWidth: 2)
                                            )
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Message d'erreur
                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.red.opacity(0.9))
                                        .padding(.horizontal, 20)
                                }
                                
                                // Indication si les mots de passe ne correspondent pas
                                if !viewModel.password.isEmpty && !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                        Text("Les mots de passe ne correspondent pas")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.red.opacity(0.9))
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                // Bouton S'inscrire
                                Button(action: {
                                    hideKeyboard()
                                    viewModel.signUp { success in
                                        if success {
                                            // Tous les utilisateurs doivent s'abonner après l'inscription
                                            if viewModel.userType == .pro {
                                                // Afficher la vue d'abonnement Pro
                                                proSubscriptionNavigationId = UUID()
                                            } else {
                                                // Afficher la vue d'abonnement Client
                                                clientSubscriptionNavigationId = UUID()
                                            }
                                        }
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        } else {
                                            Text("S'inscrire")
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
                            }
                            
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
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture {
            hideKeyboard()
        }
        .navigationDestination(item: $clientSubscriptionNavigationId) { _ in
            ClientSubscriptionView(userType: $viewModel.userType, onComplete: {
                clientSubscriptionNavigationId = nil
                // Rediriger vers le profil avec l'abonnement actif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.selectedTab = .profile
                }
            })
        }
        .navigationDestination(item: $proSubscriptionNavigationId) { _ in
            ProSubscriptionView(userType: $viewModel.userType, onComplete: {
                proSubscriptionNavigationId = nil
                // Rediriger vers le profil avec l'abonnement actif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.selectedTab = .profile
                }
            })
        }
    }
}

struct SignUpInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.6)))
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(isFocused ? Color.white.opacity(0.95) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.appGold : Color.clear, lineWidth: 2)
                )
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AppState())
    }
}

