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
                                Text("Pour accéder à tous les avantages de la plateforme, vous devez souscrire à un abonnement CLUB10.")
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
                            
                            // Carte d'abonnement
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("2,99€")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("par mois")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 32))
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                Text("Pour avoir accès à tout")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(20)
                            .background(Color.appDarkRed1.opacity(0.8))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appGold, lineWidth: 2)
                            )
                            .padding(.horizontal, 20)
                            
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
                                    StripePaymentView()
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
                                        Text(showStripePayment ? "Confirmer le paiement" : "Payer 2,99€ / mois")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appGold)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessingPayment)
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

