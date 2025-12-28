//
//  FamilyCardManagementView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct FamilyCardManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FamilyCardEmailsViewModel()
    @FocusState private var focusedField: Int?
    
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
                                Text("Gérer ma famille")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Description
                            Text("Vous pouvez ajouter jusqu'à 4 membres pour votre carte famille (5 personnes au total avec le propriétaire). Les membres existants et les invitations en attente sont affichés ci-dessous.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                            
                            // Afficher les membres existants (sans le propriétaire)
                            if !viewModel.nonOwnerMembers.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Membres actifs")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(viewModel.nonOwnerMembers, id: \.id) { member in
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.system(size: 20))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                if let firstName = member.firstName, let lastName = member.lastName {
                                                    Text("\(firstName) \(lastName)")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.white)
                                                }
                                                Text(member.email)
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Afficher les invitations en attente
                            if !viewModel.invitedEmails.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Invitations en attente")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(viewModel.invitedEmails, id: \.self) { email in
                                        HStack {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 20))
                                            
                                            Text(email)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Séparateur
                            if !viewModel.members.isEmpty || !viewModel.invitedEmails.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                            
                            // Titre pour ajouter de nouveaux membres
                            Text("Ajouter un nouveau membre")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Champs email
                            VStack(spacing: 16) {
                                ForEach(0..<4, id: \.self) { index in
                                    HStack(spacing: 12) {
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
                                        
                                        // Bouton supprimer si l'email n'est pas vide
                                        if index < viewModel.emails.count && !viewModel.emails[index].isEmpty {
                                            Button(action: {
                                                viewModel.updateEmail(at: index, value: "")
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.appRed)
                                                    .font(.system(size: 18))
                                                    .frame(width: 44, height: 44)
                                                    .background(Color.appRed.opacity(0.2))
                                                    .cornerRadius(10)
                                            }
                                        }
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
                            
                            // Bouton valider
                            Button(action: {
                                Task {
                                    await viewModel.saveEmails()
                                    // Attendre un peu pour voir le message de succès
                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text(viewModel.isLoading ? "Enregistrement..." : "Valider")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.isLoading ? Color.gray.opacity(0.5) : Color.appDarkRedButton)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
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
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FamilyCardManagementView()
            .environmentObject(AppState())
    }
}

