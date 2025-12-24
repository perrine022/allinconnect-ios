//
//  FamilyCardEmailsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

struct FamilyCardEmailsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FamilyCardEmailsViewModel
    @FocusState private var focusedField: Int?
    
    init(viewModel: FamilyCardEmailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                VStack(spacing: 24) {
                    // Titre
                    HStack {
                        Text("Gérer les emails de la carte famille")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Description
                    Text("Vous pouvez ajouter jusqu'à 4 adresses email pour votre carte famille. Seul le propriétaire de la carte peut modifier ces informations.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                    
                    // Champs email
                    VStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email \(index + 1)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("", text: Binding(
                                    get: { index < viewModel.emails.count ? viewModel.emails[index] : "" },
                                    set: { newValue in
                                        viewModel.updateEmail(at: index, value: newValue)
                                    }
                                ), prompt: Text("email@exemple.com").foregroundColor(.gray.opacity(0.6)))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .focused($focusedField, equals: index)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Message d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    // Message de succès
                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                    }
                    
                    // Bouton sauvegarder
                    Button(action: {
                        Task {
                            await viewModel.saveEmails()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Enregistrement..." : "Enregistrer")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isLoading ? Color.gray.opacity(0.5) : Color.appGold)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 100)
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

@MainActor
class FamilyCardEmailsViewModel: ObservableObject {
    @Published var emails: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    
    init(subscriptionsAPIService: SubscriptionsAPIService? = nil) {
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
        loadEmails()
    }
    
    func loadEmails() {
        Task {
            do {
                let familyEmails = try await subscriptionsAPIService.getFamilyCardEmails()
                // S'assurer qu'on a toujours 4 emplacements (peut être vide)
                emails = Array(familyEmails.emails.prefix(4))
                while emails.count < 4 {
                    emails.append("")
                }
            } catch {
                errorMessage = "Erreur lors du chargement des emails"
                print("Erreur lors du chargement des emails: \(error)")
            }
        }
    }
    
    func updateEmail(at index: Int, value: String) {
        if index < emails.count {
            emails[index] = value
        } else {
            // Ajouter des emplacements vides si nécessaire
            while emails.count <= index {
                emails.append("")
            }
            emails[index] = value
        }
    }
    
    func saveEmails() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Filtrer les emails vides
        let validEmails = emails.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Valider les emails
        for email in validEmails {
            if !isValidEmail(email) {
                errorMessage = "L'email \(email) n'est pas valide"
                isLoading = false
                return
            }
        }
        
        do {
            try await subscriptionsAPIService.updateFamilyCardEmails(UpdateFamilyCardEmailsRequest(emails: validEmails))
            successMessage = "Emails mis à jour avec succès"
            
            // Effacer le message après 3 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.successMessage = nil
            }
        } catch {
            errorMessage = "Erreur lors de la mise à jour des emails"
            print("Erreur lors de la mise à jour des emails: \(error)")
        }
        
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

