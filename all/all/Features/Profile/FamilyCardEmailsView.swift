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
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
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
                    Text("Vous pouvez ajouter jusqu'à 4 membres pour votre carte famille (5 personnes au total avec le propriétaire). Seul le propriétaire de la carte peut modifier ces informations.")
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
    @Published var ownerEmail: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let profileAPIService: ProfileAPIService
    
    // Membres non-propriétaires (pour l'affichage)
    var nonOwnerMembers: [CardMember] {
        members.filter { $0.email != ownerEmail }
    }
    
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
                // Charger depuis /users/me/light pour avoir l'email de l'utilisateur connecté
                let userLight = try await profileAPIService.getUserLight()
                
                // Récupérer l'email de l'utilisateur connecté (propriétaire)
                // On doit aussi charger /users/me pour avoir l'email complet
                let userMe = try await profileAPIService.getUserMe()
                ownerEmail = userMe.email ?? ""
                
                // Récupérer les membres et invitations depuis card
                if let card = userLight.card {
                    members = card.members ?? []
                    invitedEmails = card.invitedEmails ?? []
                    
                    // Exclure le propriétaire de la liste des membres (il n'est pas dans la limite de 4)
                    // Filtrer les membres qui ne sont pas le propriétaire
                    let nonOwnerMembers = members.filter { $0.email != ownerEmail }
                    let nonOwnerMemberEmails = nonOwnerMembers.map { $0.email }
                    
                    // Combiner les emails des membres (sans propriétaire) et les invitations en attente
                    let allEmails = nonOwnerMemberEmails + invitedEmails
                    
                    // S'assurer qu'on a toujours 4 emplacements maximum (peut être vide)
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
        print("[FamilyCardEmailsViewModel] ===== DEBUT saveEmails =====")
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Récupérer l'email du propriétaire
        let userMe = try? await profileAPIService.getUserMe()
        let ownerEmail = userMe?.email ?? ""
        print("[FamilyCardEmailsViewModel] Owner email: \(ownerEmail)")
        
        // Récupérer les emails actuels (membres + invitations), en excluant le propriétaire
        let currentMemberEmails = Set(members.filter { $0.email != ownerEmail }.map { $0.email })
        let currentInvitedEmails = Set(invitedEmails)
        let currentAllEmails = currentMemberEmails.union(currentInvitedEmails)
        
        print("[FamilyCardEmailsViewModel] Current member emails: \(currentMemberEmails)")
        print("[FamilyCardEmailsViewModel] Current invited emails: \(currentInvitedEmails)")
        print("[FamilyCardEmailsViewModel] Current all emails: \(currentAllEmails)")
        print("[FamilyCardEmailsViewModel] New emails from form: \(emails)")
        
        // Filtrer les emails saisis (non vides)
        let trimmedEmails = emails.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let newEmailsSet = Set(trimmedEmails)
        
        print("[FamilyCardEmailsViewModel] Trimmed emails from form: \(trimmedEmails)")
        print("[FamilyCardEmailsViewModel] New emails set: \(newEmailsSet)")
        
        // Trouver les emails à ajouter (nouveaux)
        let emailsToAdd = newEmailsSet.subtracting(currentAllEmails)
        print("[FamilyCardEmailsViewModel] Emails to ADD: \(emailsToAdd)")
        
        // Trouver les emails à supprimer (étaient là avant mais plus maintenant)
        let emailsToRemove = currentAllEmails.subtracting(newEmailsSet)
        print("[FamilyCardEmailsViewModel] Emails to REMOVE: \(emailsToRemove)")
        
        // Valider les nouveaux emails
        for email in emailsToAdd {
            if !isValidEmail(email) {
                errorMessage = "L'email \(email) n'est pas valide"
                isLoading = false
                print("[FamilyCardEmailsViewModel] ERROR: Invalid email format: \(email)")
                return
            }
            if email == ownerEmail {
                errorMessage = "Vous ne pouvez pas vous inviter vous-même"
                isLoading = false
                print("[FamilyCardEmailsViewModel] ERROR: Cannot invite owner email")
                return
            }
        }
        
        // Vérifier la limite de 4 membres (en plus du propriétaire)
        // Total = 1 propriétaire + 4 membres maximum = 5 personnes au total
        let totalCount = newEmailsSet.count
        if totalCount > 4 {
            errorMessage = "Une carte famille est limitée à 4 membres (en plus du propriétaire). Total maximum : 5 personnes."
            isLoading = false
            print("[FamilyCardEmailsViewModel] ERROR: Too many members (\(totalCount) > 4)")
            return
        }
        
        // Traiter les suppressions et ajouts
        do {
            var addedCount = 0
            var removedCount = 0
            
            // 1. Supprimer les membres/invitations qui ne sont plus dans la liste
            for emailToRemove in emailsToRemove {
                print("[FamilyCardEmailsViewModel] Removing email: \(emailToRemove)")
                
                // Vérifier si c'est un membre inscrit (par ID) ou une invitation (par email)
                if let member = members.first(where: { $0.email == emailToRemove && $0.email != ownerEmail }) {
                    // C'est un membre inscrit, utiliser memberId
                    print("[FamilyCardEmailsViewModel] Removing member with ID: \(member.id)")
                    try await subscriptionsAPIService.removeFamilyMember(memberId: member.id, email: nil)
                    removedCount += 1
                } else {
                    // C'est une invitation en attente, utiliser email
                    print("[FamilyCardEmailsViewModel] Removing invitation with email: \(emailToRemove)")
                    try await subscriptionsAPIService.removeFamilyMember(memberId: nil, email: emailToRemove)
                    removedCount += 1
                }
            }
            
            // 2. Ajouter les nouveaux emails
            for emailToAdd in emailsToAdd {
                print("[FamilyCardEmailsViewModel] Adding email: \(emailToAdd)")
                try await subscriptionsAPIService.inviteFamilyMember(email: emailToAdd)
                addedCount += 1
            }
            
            print("[FamilyCardEmailsViewModel] Success - Added: \(addedCount), Removed: \(removedCount)")
            
            // Message de succès
            var messages: [String] = []
            if addedCount > 0 {
                messages.append("\(addedCount) membre(s) invité(s)")
            }
            if removedCount > 0 {
                messages.append("\(removedCount) membre(s) retiré(s)")
            }
            
            if messages.isEmpty {
                successMessage = "Aucun changement"
            } else {
                successMessage = messages.joined(separator: ", ") + " avec succès"
            }
            
            // Recharger les données
            loadEmails()
            
            // Effacer le message après 3 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.successMessage = nil
            }
        } catch {
            print("[FamilyCardEmailsViewModel] ERROR: \(error)")
            if let apiError = error as? APIError {
                switch apiError {
                case .httpError(let statusCode, let message):
                    print("[FamilyCardEmailsViewModel] HTTP Error - Status: \(statusCode), Message: \(message ?? "nil")")
                    if statusCode == 400 {
                        errorMessage = message ?? "Erreur lors de l'opération. Vérifiez que vous êtes le propriétaire de la carte et que la limite de 4 membres (5 personnes au total avec le propriétaire) n'est pas atteinte."
                    } else {
                        errorMessage = message ?? "Erreur lors de l'opération (code: \(statusCode))"
                    }
                default:
                    errorMessage = "Erreur lors de l'opération: \(apiError.localizedDescription)"
                }
            } else {
                errorMessage = "Erreur lors de l'opération: \(error.localizedDescription)"
            }
        }
        
        print("[FamilyCardEmailsViewModel] ===== FIN saveEmails =====")
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

