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
    @EnvironmentObject private var appState: AppState
    @State private var showPortal = false
    @State private var portalURL: URL?
    @State private var modifySubscriptionNavigationId: UUID?
    @State private var showCancelAlert = false
    @State private var isCancelling = false
    @State private var cancelSuccessMessage: String?
    private let subscriptionsAPIService = SubscriptionsAPIService()
    
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
                    
                    // Boutons d'action (uniquement si l'utilisateur a un abonnement actif et non résilié)
                    let isSubscriptionCancelled = viewModel.subscriptionStatus == "CANCELLED" || 
                                                  viewModel.subscriptionStatus == "CANCELED"
                    
                    if viewModel.premiumEnabled && !isSubscriptionCancelled {
                        VStack(spacing: 12) {
                            // Bouton Modifier mon abonnement
                            Button(action: {
                                modifySubscriptionNavigationId = UUID()
                            }) {
                                Text("Modifier mon abonnement")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appGold)
                                    .cornerRadius(12)
                            }
                            
                            // Bouton Résilier mon abonnement
                            Button(action: {
                                showCancelAlert = true
                            }) {
                                Text("Résilier mon abonnement")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red, lineWidth: 1.5)
                                    )
                                    .cornerRadius(12)
                            }
                            
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
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Bouton pour gérer la facturation (si pas d'abonnement actif)
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
                    }
                    
                    // Informations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gestion de l'abonnement")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Tu peux modifier ta méthode de paiement, consulter tes factures, ou annuler ton abonnement depuis le portail de gestion Stripe.")
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
                    
                    // Message de succès pour la résiliation
                    if let successMessage = cancelSuccessMessage {
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
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
        .alert("Résilier l'abonnement", isPresented: $showCancelAlert) {
            Button("Annuler", role: .cancel) { }
            Button("À la fin de la période", role: .none) {
                Task {
                    await cancelSubscription(atPeriodEnd: true)
                }
            }
            Button("Immédiatement", role: .destructive) {
                Task {
                    await cancelSubscription(atPeriodEnd: false)
                }
            }
        } message: {
            Text("Choisis le type de résiliation :\n\n• À la fin de la période : Tu gardes l'accès jusqu'à la fin de la période payée.\n• Immédiatement : L'accès sera coupé tout de suite.")
        }
        .navigationDestination(item: $modifySubscriptionNavigationId) { _ in
            ModifySubscriptionView(currentPlanId: nil)
                .environmentObject(appState)
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
    
    private func cancelSubscription(atPeriodEnd: Bool) async {
        isCancelling = true
        cancelSuccessMessage = nil
        
        do {
            try await subscriptionsAPIService.cancelSubscription(atPeriodEnd: atPeriodEnd)
            
            // Attendre un court délai pour que le backend traite la résiliation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            
            // Recharger les données pour voir le nouveau statut
            await viewModel.loadSubscriptionStatus()
            await viewModel.loadSubscriptionDetails()
            
            // Notifier la mise à jour
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            
            isCancelling = false
            
            // Afficher un message de succès
            if atPeriodEnd {
                cancelSuccessMessage = "Ton abonnement sera résilié à la fin de la période payée. Tu gardes l'accès jusqu'à cette date."
            } else {
                cancelSuccessMessage = "Ton abonnement a été résilié avec succès."
            }
            
            // Effacer le message après 5 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                cancelSuccessMessage = nil
            }
        } catch {
            isCancelling = false
            viewModel.errorMessage = "Erreur lors de la résiliation : \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ManageSubscriptionView()
    }
}

