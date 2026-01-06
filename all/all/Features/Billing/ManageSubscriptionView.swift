//
//  ManageSubscriptionView.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import SwiftUI
import SafariServices

struct ManageSubscriptionView: View {
    @StateObject private var viewModel = BillingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPortal = false
    @State private var portalURL: URL?
    
    var body: some View {
        ZStack {
            // Background gradient
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
                        Text("Gérer mon abonnement")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Statut de l'abonnement
                    VStack(spacing: 16) {
                        HStack {
                            Text("Statut")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(viewModel.premiumEnabled ? "Actif" : "Inactif")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.premiumEnabled ? .green : .gray)
                        }
                        
                        if let planName = viewModel.planName {
                            HStack {
                                Text("Plan")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(planName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let status = viewModel.subscriptionStatus {
                            HStack {
                                Text("Statut détaillé")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(status)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let periodEnd = viewModel.currentPeriodEnd {
                            HStack {
                                Text("Prochain renouvellement")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(formatDate(periodEnd))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let lastFour = viewModel.lastFour, let cardBrand = viewModel.cardBrand {
                            HStack {
                                Text("Carte")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                HStack(spacing: 4) {
                                    Text(cardBrand.capitalized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("•••• \(lastFour)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appDarkRed1.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    // Bouton pour gérer la facturation
                    Button(action: {
                        Task {
                            await openPortal()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Gérer la facturation")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isLoading ? Color.gray.opacity(0.5) : Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 20)
                    
                    // Informations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gestion de l'abonnement")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Vous pouvez modifier votre méthode de paiement, consulter vos factures, ou annuler votre abonnement depuis le portail de gestion Stripe.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    
                    // Messages d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showPortal) {
            if let url = portalURL {
                SafariView(url: url) {
                    // Recharger le statut après fermeture du portail
                    Task {
                        await viewModel.loadSubscriptionStatus()
                        await viewModel.loadSubscriptionDetails()
                    }
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSubscriptionStatus()
                await viewModel.loadSubscriptionDetails()
            }
        }
    }
    
    private func openPortal() async {
        do {
            let url = try await viewModel.createPortalSession()
            portalURL = url
            showPortal = true
        } catch {
            // L'erreur est déjà gérée dans le ViewModel
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ManageSubscriptionView()
    }
}

