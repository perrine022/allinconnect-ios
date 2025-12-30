//
//  ProSubscriptionView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Binding var userType: UserType
    let onComplete: () -> Void
    @StateObject private var viewModel = ProSubscriptionViewModel()
    @State private var showPayment = false
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
                        VStack(spacing: 16) {
                            // Titre de bienvenue
                            VStack(spacing: 8) {
                                Text("Bienvenue sur ALL IN Connect")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                if !firstName.isEmpty {
                                    Text(firstName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            
                            // Texte explicatif
                            Text("Pour accéder à tous les avantages de la plateforme, vous devez souscrire à un abonnement Pro.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 20)
                            
                            // Titre principal
                            VStack(spacing: 8) {
                                Text("Le bouche-à-oreille, enfin digitalisé ! 🚀")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("ALL IN Connect, c'est la plateforme locale qui connecte les indépendants et commerçants aux habitants de leur secteur.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                            .padding(.horizontal, 20)
                            
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
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(plan.title)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.black.opacity(0.7))
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(plan.priceLabel)
                                                        .font(.system(size: 22, weight: .bold))
                                                        .foregroundColor(.black)
                                                    
                                                    if plan.isMonthly {
                                                        Text("(engagement 6 mois)")
                                                            .font(.system(size: 11, weight: .regular))
                                                            .foregroundColor(.black.opacity(0.6))
                                                    }
                                                }
                                                
                                                if plan.isAnnual {
                                                    Text("Économisez avec l'abonnement annuel 🎉")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.black.opacity(0.7))
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(viewModel.selectedPlan?.id == plan.id ? Color.red : Color.gray.opacity(0.3), lineWidth: viewModel.selectedPlan?.id == plan.id ? 2 : 1)
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Section "Ce que tu obtiens"
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Text("🎁")
                                        .font(.system(size: 20))
                                    Text("Ce que tu obtiens")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 12) {
                                    // Visibilité locale
                                    ProBenefitCard(
                                        icon: "mappin.circle.fill",
                                        iconColor: .red,
                                        title: "Visibilité locale",
                                        description: "Apparais auprès des habitants de ta zone"
                                    )
                                    
                                    // Tes offres diffusées
                                    ProBenefitCard(
                                        icon: "megaphone.fill",
                                        iconColor: .red,
                                        title: "Tes offres diffusées",
                                        description: "À toute la communauté ALL IN Connect"
                                    )
                                    
                                    // Accès au CLUB10
                                    ProBenefitCard(
                                        icon: "star.fill",
                                        iconColor: .appGold,
                                        title: "Accès au CLUB10",
                                        description: "Mis en avant toute l'année"
                                    )
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
                            
                            // Bouton S'abonner
                            Button(action: {
                                if showStripePayment {
                                    // Simuler le paiement (mock)
                                    isProcessingPayment = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isProcessingPayment = false
                                        // Sauvegarder l'abonnement actif
                                        UserDefaults.standard.set(true, forKey: "has_active_subscription")
                                        UserDefaults.standard.set("PRO", forKey: "subscription_type")
                                        if let selectedPlan = viewModel.selectedPlan {
                                            let nextPaymentDate = Calendar.current.date(byAdding: selectedPlan.isAnnual ? .year : .month, value: 1, to: Date()) ?? Date()
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "dd/MM/yyyy"
                                            UserDefaults.standard.set(formatter.string(from: nextPaymentDate), forKey: "subscription_next_payment_date")
                                        }
                                        
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
                                            Text(showStripePayment ? "Confirmer le paiement" : "S'abonner - \(selectedPlan.priceLabel)")
                                                .font(.system(size: 16, weight: .bold))
                                        } else {
                                            Text("Sélectionnez un plan")
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .disabled(isProcessingPayment || viewModel.selectedPlan == nil)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            
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

struct ProBenefitCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            ZStack {
                Circle()
                    .fill(Color.appDarkRed1.opacity(0.8))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 20))
            }
            
            // Texte
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            ZStack {
                // Fond avec effet de blur simulé
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appDarkRed1.opacity(0.6))
                
                // Overlay sombre pour la lisibilité
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ProSubscriptionView(userType: .constant(.pro), onComplete: {})
            .environmentObject(AppState())
    }
}

