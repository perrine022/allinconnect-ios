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
    @Published var members: [CardMember] = []
    @Published var invitedEmails: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let profileAPIService: ProfileAPIService
    
    init(subscriptionsAPIService: SubscriptionsAPIService? = nil, profileAPIService: ProfileAPIService? = nil) {
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        loadEmails()
    }
    
    func loadEmails() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Charger depuis /users/me/light
                let userLight = try await profileAPIService.getUserLight()
                
                // Récupérer les membres et invitations depuis card
                if let card = userLight.card {
                    members = card.members ?? []
                    invitedEmails = card.invitedEmails ?? []
                    
                    // Combiner les emails des membres et les invitations en attente
                    let memberEmails = members.map { $0.email }
                    let allEmails = memberEmails + invitedEmails
                    
                    // S'assurer qu'on a toujours 4 emplacements (peut être vide)
                    emails = Array(allEmails.prefix(4))
                    while emails.count < 4 {
                        emails.append("")
                    }
                } else {
                    // Pas de carte famille, initialiser avec des champs vides
                    emails = ["", "", "", ""]
                }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des membres"
                print("Erreur lors du chargement des membres: \(error)")
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
        
        // Récupérer les emails actuels (membres + invitations)
        let currentMemberEmails = Set(members.map { $0.email })
        let currentInvitedEmails = Set(invitedEmails)
        let currentAllEmails = currentMemberEmails.union(currentInvitedEmails)
        
        // Filtrer les nouveaux emails (ceux qui ne sont pas déjà membres ou invités)
        let newEmails = emails.filter { email in
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            return !trimmedEmail.isEmpty && !currentAllEmails.contains(trimmedEmail)
        }
        
        // Valider les nouveaux emails
        for email in newEmails {
            if !isValidEmail(email) {
                errorMessage = "L'email \(email) n'est pas valide"
                isLoading = false
                return
            }
        }
        
        // Vérifier la limite de 4 membres (membres existants + invitations + nouveaux)
        let totalCount = currentAllEmails.count + newEmails.count
        if totalCount > 4 {
            errorMessage = "Une carte famille est limitée à 4 membres au total"
            isLoading = false
            return
        }
        
        // Inviter chaque nouvel email
        do {
            for email in newEmails {
                try await subscriptionsAPIService.inviteFamilyMember(email: email.trimmingCharacters(in: .whitespaces))
            }
            
            successMessage = newEmails.isEmpty ? "Aucun changement" : "\(newEmails.count) membre(s) invité(s) avec succès"
            
            // Recharger les données
            loadEmails()
            
            // Effacer le message après 3 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.successMessage = nil
            }
        } catch {
            if let apiError = error as? APIError {
                switch apiError {
                case .httpError(let statusCode, let message):
                    if statusCode == 400 {
                        errorMessage = message ?? "Erreur lors de l'invitation. Vérifiez que vous êtes le propriétaire de la carte et que la limite de 4 membres n'est pas atteinte."
                    } else {
                        errorMessage = message ?? "Erreur lors de l'invitation"
                    }
                default:
                    errorMessage = "Erreur lors de l'invitation"
                }
            } else {
                errorMessage = "Erreur lors de l'invitation"
            }
            print("Erreur lors de l'invitation: \(error)")
        }
        
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

