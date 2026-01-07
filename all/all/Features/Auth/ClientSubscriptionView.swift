//
//  ClientSubscriptionView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ClientSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Binding var userType: UserType
    let onComplete: () -> Void
    @StateObject private var viewModel = ClientSubscriptionViewModel()
    @State private var showStripePayment = false
    @State private var isProcessingPayment = false
    
    // Récupérer le prénom depuis UserDefaults
    private var firstName: String {
        UserDefaults.standard.string(forKey: "user_first_name") ?? ""
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
                            // Titre de bienvenue
                            VStack(spacing: 12) {
                                Text("Bienvenue sur ALL IN Connect")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if !firstName.isEmpty {
                                    Text(firstName)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                            
                            // Texte explicatif
                            VStack(spacing: 8) {
                                Text("Pour accéder à tous les avantages de la plateforme, tu dois souscrire à un abonnement CLUB10.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            .padding(.horizontal, 20)
                            
                            // Titre de la section abonnement
                            VStack(spacing: 8) {
                                Text("Abonnement CLUB10")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Accédez à tous les avantages")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 8)
                            
                            // Plans d'abonnement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            } else if viewModel.plans.isEmpty {
                                Text("Aucun plan disponible")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.plans) { plan in
                                        Button(action: {
                                            viewModel.selectedPlan = plan
                                        }) {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(plan.formattedPrice)
                                                            .font(.system(size: 32, weight: .bold))
                                                            .foregroundColor(.white)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(plan.isMonthly ? "par mois" : "par an")
                                                                .font(.system(size: 16, weight: .regular))
                                                                .foregroundColor(.white.opacity(0.8))
                                                            
                                                            if plan.isMonthly {
                                                                Text("(engagement 6 mois)")
                                                                    .font(.system(size: 12, weight: .regular))
                                                                    .foregroundColor(.white.opacity(0.6))
                                                            }
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.appGold)
                                                        .font(.system(size: 28))
                                                }
                                                
                                                Divider()
                                                    .background(Color.white.opacity(0.2))
                                                
                                                Text(plan.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.9))
                                                
                                                if let description = plan.description {
                                                    Text(description)
                                                        .font(.system(size: 12, weight: .regular))
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(20)
                                            .background(viewModel.selectedPlan?.id == plan.id ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.8))
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(viewModel.selectedPlan?.id == plan.id ? Color.appGold : Color.clear, lineWidth: 2)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Avantages CLUB10
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Avantages de l'abonnement CLUB10")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Accès à toutes les offres exclusives")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Réductions et avantages chez tous les partenaires")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Notifications en temps réel des nouvelles offres")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Carte de fidélité digitale")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Support client prioritaire")
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Section Stripe Payment (embedded)
                            if showStripePayment {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Paiement sécurisé")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    // WebView Stripe embedded
                                    StripePaymentView(filterCategory: "CLIENT")
                                        .frame(height: 600)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Bouton Payer
                            Button(action: {
                                if showStripePayment {
                                    // Simuler le paiement (mock)
                                    isProcessingPayment = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isProcessingPayment = false
                                        // Sauvegarder l'abonnement actif
                                        UserDefaults.standard.set(true, forKey: "has_active_subscription")
                                        UserDefaults.standard.set("CLUB10", forKey: "subscription_type")
                                        let nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "dd/MM/yyyy"
                                        UserDefaults.standard.set(formatter.string(from: nextPaymentDate), forKey: "subscription_next_payment_date")
                                        
                                        // Rediriger vers le profil
                                        onComplete()
                                    }
                                } else {
                                    // Afficher le formulaire de paiement Stripe
                                    showStripePayment = true
                                }
                            }) {
                                HStack {
                                    if isProcessingPayment {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        if let selectedPlan = viewModel.selectedPlan {
                                            Text(showStripePayment ? "Confirmer le paiement" : "Payer \(selectedPlan.priceLabel)")
                                                .font(.system(size: 18, weight: .bold))
                                        } else {
                                            Text("Sélectionnez un plan")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appGold)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessingPayment || viewModel.selectedPlan == nil)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
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
        .onAppear {
            viewModel.loadPlans()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct AdvantageRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.appGold)
                .font(.system(size: 16))
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    NavigationStack {
        ClientSubscriptionView(userType: .constant(.client), onComplete: {})
            .environmentObject(AppState())
    }
}

