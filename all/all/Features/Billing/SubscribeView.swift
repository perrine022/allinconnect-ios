//
//  SubscribeView.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import SwiftUI

struct SubscribeView: View {
    @StateObject private var viewModel = BillingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPaymentSheet = false
    @State private var paymentSheetData: (customerId: String, ephemeralKey: String, clientSecret: String)?
    
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
                        Text("Abonnement Premium")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Statut actuel
                    if viewModel.premiumEnabled {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 24))
                                Text("Abonnement actif")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            if let periodEnd = viewModel.currentPeriodEnd {
                                Text("Renouvellement le \(formatDate(periodEnd))")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // Avantages Premium
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Avantages Premium")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                PremiumFeatureRow(icon: "star.fill", text: "Accès à toutes les fonctionnalités")
                                PremiumFeatureRow(icon: "crown.fill", text: "Support prioritaire")
                                PremiumFeatureRow(icon: "bolt.fill", text: "Sans publicité")
                                PremiumFeatureRow(icon: "lock.fill", text: "Contenu exclusif")
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
                        
                        // Prix
                        VStack(spacing: 8) {
                            Text("9,99€")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.appGold)
                            Text("par mois")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 20)
                        
                        // Bouton d'abonnement
                        Button(action: {
                            Task {
                                await startSubscription()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Commencer l'abonnement mensuel")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isLoading ? Color.gray.opacity(0.5) : Color.appGold)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Messages d'erreur/succès
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
                    
                    if let successMessage = viewModel.successMessage {
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
        .sheet(isPresented: $showPaymentSheet) {
            if let data = paymentSheetData {
                StripeSubscriptionPaymentSheetView(
                    customerId: data.customerId,
                    ephemeralKeySecret: data.ephemeralKey,
                    paymentIntentClientSecret: data.clientSecret,
                    onPaymentResult: { success, error in
                        showPaymentSheet = false
                        if success {
                            Task {
                                await viewModel.handlePaymentSuccess()
                            }
                        } else {
                            viewModel.errorMessage = error ?? "Paiement échoué ou annulé"
                        }
                    }
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSubscriptionStatus()
            }
        }
    }
    
    private func startSubscription() async {
        do {
            let response = try await viewModel.startSubscription()
            paymentSheetData = (
                customerId: response.customerId,
                ephemeralKey: response.ephemeralKeySecret,
                clientSecret: response.paymentIntentClientSecret
            )
            showPaymentSheet = true
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

struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.appGold)
                .font(.system(size: 18))
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        SubscribeView()
    }
}



