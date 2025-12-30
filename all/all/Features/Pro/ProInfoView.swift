//
//  ProInfoView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProInfoView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProSubscriptionViewModel()
    @State private var showStripePayment = false
    @State private var isProcessingPayment = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Titre principal
                            VStack(spacing: 12) {
                                Text("Le bouche-à-oreille, enfin digitalisé ! 🚀")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("ALL IN Connect, c'est la plateforme locale qui connecte les indépendants et commerçants aux habitants de leur secteur.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                            .padding(.top, 20)
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
                                VStack(spacing: 16) {
                                    ForEach(viewModel.plans) { plan in
                                        Button(action: {
                                            viewModel.selectedPlan = plan
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(plan.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.9))
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(plan.priceLabel)
                                                        .font(.system(size: 24, weight: .bold))
                                                        .foregroundColor(.white)
                                                    
                                                    if plan.isMonthly {
                                                        Text("(engagement 6 mois)")
                                                            .font(.system(size: 12, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                }
                                                
                                                if plan.isAnnual {
                                                    Text("Économisez avec l'abonnement annuel 🎉")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.9))
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(20)
                                            .background(viewModel.selectedPlan?.id == plan.id ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.5))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(viewModel.selectedPlan?.id == plan.id ? Color.red : Color.clear, lineWidth: 2)
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Section "Ce que tu obtiens"
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(spacing: 8) {
                                    Text("🎁")
                                        .font(.system(size: 24))
                                    Text("Ce que tu obtiens")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 16) {
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
                                        iconColor: .white,
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
                                    StripePaymentView(filterCategory: "PROFESSIONAL")
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
                                        appState.selectedTab = .profile
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
                                                .font(.system(size: 18, weight: .bold))
                                        } else {
                                            Text("Sélectionnez un plan")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
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

#Preview {
    NavigationStack {
        ProInfoView()
            .environmentObject(AppState())
    }
}

