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
    @State private var stripePaymentNavigationId: UUID?
    
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
                                // Naviguer vers la page de sélection d'abonnement PRO
                                stripePaymentNavigationId = UUID()
                            }) {
                                Text("S'abonner")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
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
        .navigationDestination(item: $stripePaymentNavigationId) { _ in
            StripePaymentView(filterCategory: "PROFESSIONAL")
        }
    }
}

#Preview {
    NavigationStack {
        ProInfoView()
            .environmentObject(AppState())
    }
}

