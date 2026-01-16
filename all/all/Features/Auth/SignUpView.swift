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
    @State private var subscriptionNavigationId: UUID?
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName, lastName, email, password, postalCode, birthDay, birthMonth, birthYear, referralCode
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
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
                                // Nom (en premier)
                                SignUpInputField(
                                    title: "Nom",
                                    text: $viewModel.lastName,
                                    placeholder: "Votre nom",
                                    isFocused: focusedField == .lastName
                                )
                                .focused($focusedField, equals: .lastName)
                                
                                // Prénom (en deuxième)
                                SignUpInputField(
                                    title: "Prénom",
                                    text: $viewModel.firstName,
                                    placeholder: "Votre prénom",
                                    isFocused: focusedField == .firstName
                                )
                                .focused($focusedField, equals: .firstName)
                                
                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    SignUpInputField(
                                        title: "Email",
                                        text: $viewModel.email,
                                        placeholder: "votre@email.com",
                                        keyboardType: .emailAddress,
                                        isFocused: focusedField == .email,
                                        hasError: !viewModel.email.isEmpty && !viewModel.isValidEmail
                                    )
                                    .focused($focusedField, equals: .email)
                                    .autocapitalization(.none)
                                    
                                    // Message d'erreur pour l'email
                                    if !viewModel.email.isEmpty && !viewModel.isValidEmail {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text("Format invalide. Utilisez le format : exemple@domaine.com")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                        .padding(.horizontal, 20)
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
                                    .background(focusedField == .password ? Color.white.opacity(0.95) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(focusedField == .password ? Color.appGold : Color.clear, lineWidth: 2)
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
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    viewModel.postalCodeError != nil ? Color.red :
                                                    focusedField == .postalCode ? Color.appGold : Color.clear,
                                                    lineWidth: viewModel.postalCodeError != nil ? 1 : 2
                                                )
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
                                            // Valider le code postal
                                            viewModel.validatePostalCode()
                                        }
                                    
                                    // Message d'erreur pour le code postal
                                    if let postalCodeError = viewModel.postalCodeError {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text(postalCodeError)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                
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
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(viewModel.birthDayError != nil ? Color.red : Color.clear, lineWidth: 1)
                                                )
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthDay) { _, _ in
                                                    viewModel.validateBirthDate()
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
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(viewModel.birthMonthError != nil ? Color.red : Color.clear, lineWidth: 1)
                                                )
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthMonth) { _, _ in
                                                    viewModel.validateBirthDate()
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
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(viewModel.birthYearError != nil ? Color.red : Color.clear, lineWidth: 1)
                                                )
                                                .cornerRadius(10)
                                                .onChange(of: viewModel.birthYear) { _, _ in
                                                    viewModel.validateBirthDate()
                                                }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Messages d'erreur pour la date de naissance
                                    if let dayError = viewModel.birthDayError {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text(dayError)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                    } else if let monthError = viewModel.birthMonthError {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text(monthError)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                    } else if let yearError = viewModel.birthYearError {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text(yearError)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                    } else if let dateError = viewModel.birthDateError {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 12))
                                            Text(dateError)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Code de parrainage (optionnel)
                                SignUpInputField(
                                    title: "Parrainage",
                                    text: $viewModel.referralCode,
                                    placeholder: "Code de parrainage (optionnel)",
                                    isFocused: focusedField == .referralCode
                                )
                                .focused($focusedField, equals: .referralCode)
                                .autocapitalization(.allCharacters)
                                
                                // Message d'erreur
                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.red.opacity(0.9))
                                        .padding(.horizontal, 20)
                                }
                                
                                // Bouton S'inscrire
                                Button(action: {
                                    hideKeyboard()
                                    viewModel.signUp { success in
                                        if success {
                                            // Rediriger vers la page de sélection d'abonnement avec tous les plans
                                            subscriptionNavigationId = UUID()
                                        }
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Text("S'inscrire")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.isValid && !viewModel.isLoading ? Color.appRed : Color.gray.opacity(0.5))
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
        .navigationDestination(item: $subscriptionNavigationId) { _ in
            StripePaymentView(filterCategory: nil)
        }
    }
}

struct SignUpInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false
    var hasError: Bool = false
    
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
                .background(isFocused ? Color.white.opacity(0.95) : (hasError ? Color.red.opacity(0.1) : Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            hasError ? Color.red :
                            isFocused ? Color.appGold : Color.clear,
                            lineWidth: hasError ? 1 : 2
                        )
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

