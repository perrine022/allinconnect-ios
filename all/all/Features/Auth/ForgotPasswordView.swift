//
//  ForgotPasswordView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var isEmailSent: Bool = false
    @Published var errorMessage: String?
    
    private let authAPIService: AuthAPIService
    
    init(authAPIService: AuthAPIService? = nil) {
        // Créer le service dans un contexte MainActor
        if let authAPIService = authAPIService {
            self.authAPIService = authAPIService
        } else {
            self.authAPIService = AuthAPIService()
        }
    }
    
    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func sendResetEmail() {
        isLoading = true
        errorMessage = nil
        
        guard isValid else {
            errorMessage = "Veuillez entrer une adresse email valide"
            isLoading = false
            return
        }
        
        // Afficher immédiatement le message de succès
        isLoading = false
        isEmailSent = true
        
        // Envoyer la demande en arrière-plan (sans bloquer l'UI)
        Task {
            do {
                // Appeler l'API en arrière-plan
                try await authAPIService.forgotPassword(email: email.trimmingCharacters(in: .whitespaces).lowercased())
                print("✅ Email de réinitialisation envoyé avec succès")
            } catch {
                // En cas d'erreur, on ne change pas l'état de succès pour ne pas perturber l'utilisateur
                // L'email sera peut-être quand même envoyé côté serveur
                print("⚠️ Erreur lors de l'envoi de l'email de réinitialisation: \(error)")
            }
        }
    }
}

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Icône
                    ZStack {
                        Circle()
                            .fill(Color.appRed.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50))
                            .foregroundColor(.appRed)
                    }
                    .padding(.top, 40)
                    
                    // Titre
                    Text("Mot de passe oublié")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    if !viewModel.isEmailSent {
                        Text("Entre ton adresse email et nous t'enverrons un lien pour réinitialiser ton mot de passe.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 30)
                        
                        // Champ email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.email, prompt: Text("ton@email.com").foregroundColor(.gray.opacity(0.6)))
                                .focused($isEmailFocused)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.send)
                                .onSubmit {
                                    if viewModel.isValid {
                                        viewModel.sendResetEmail()
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
                                .padding(.top, 8)
                        }
                        
                        // Bouton envoyer
                        Button(action: {
                            hideKeyboard()
                            viewModel.sendResetEmail()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Envoyer")
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
                        .padding(.top, 20)
                    } else {
                        // Message de succès
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Email envoyé !")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Nous avons envoyé un lien de réinitialisation à \(viewModel.email). Vérifiez votre boîte de réception.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 30)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Retour à la connexion")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appGold)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}

