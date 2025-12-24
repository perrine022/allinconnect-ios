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
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showStripePayment = false
    @State private var isProcessingPayment = false
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "Paiement mensuel"
        case yearly = "Paiement annuel"
        
        var price: String {
            switch self {
            case .monthly: return "9,99€"
            case .yearly: return "99€"
            }
        }
        
        var priceLabel: String {
            switch self {
            case .monthly: return "\(price) / mois"
            case .yearly: return "\(price) / an"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Économise 2 mois 🎉"
            }
        }
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
                            VStack(spacing: 16) {
                                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                                    Button(action: {
                                        selectedPlan = plan
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(plan.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Text(plan.priceLabel)
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            if let savings = plan.savings {
                                                Text(savings)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.9))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(20)
                                        .background(selectedPlan == plan ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedPlan == plan ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
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
                                        let nextPaymentDate = Calendar.current.date(byAdding: selectedPlan == .yearly ? .year : .month, value: selectedPlan == .yearly ? 1 : 1, to: Date()) ?? Date()
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "dd/MM/yyyy"
                                        UserDefaults.standard.set(formatter.string(from: nextPaymentDate), forKey: "subscription_next_payment_date")
                                        
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
                                        Text(showStripePayment ? "Confirmer le paiement" : (selectedPlan == .yearly ? "S'abonner - \(selectedPlan.price)/an" : "S'abonner - \(selectedPlan.price)/mois"))
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

#Preview {
    NavigationStack {
        ProInfoView()
            .environmentObject(AppState())
    }
}

