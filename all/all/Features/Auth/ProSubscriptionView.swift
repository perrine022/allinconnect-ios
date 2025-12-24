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
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showPayment = false
    
    enum SubscriptionPlan: String, CaseIterable {
        case monthly = "Mensuel"
        case yearly = "Annuel"
        
        var price: String {
            switch self {
            case .monthly: return "49,90€"
            case .yearly: return "499€"
            }
        }
        
        var monthlyEquivalent: String {
            switch self {
            case .monthly: return "49,90€"
            case .yearly: return "41,58€"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Économisez 17%"
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
                            // Titre
                            VStack(spacing: 8) {
                                Text("Abonnement Pro")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Choisissez votre formule")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 20)
                            
                            // Plans d'abonnement
                            VStack(spacing: 16) {
                                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                                    Button(action: {
                                        selectedPlan = plan
                                    }) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(plan.rawValue)
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(.white)
                                                    
                                                    if plan == .yearly {
                                                        Text("\(plan.price)/an")
                                                            .font(.system(size: 14, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.8))
                                                        
                                                        Text("Soit \(plan.monthlyEquivalent)/mois")
                                                            .font(.system(size: 12, weight: .regular))
                                                            .foregroundColor(.appGold)
                                                    } else {
                                                        Text(plan.price + "/mois")
                                                            .font(.system(size: 14, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.8))
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedPlan == plan ? Color.appGold : Color.clear)
                                                        .frame(width: 24, height: 24)
                                                    
                                                    if selectedPlan == plan {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.black)
                                                            .font(.system(size: 12, weight: .bold))
                                                    } else {
                                                        Circle()
                                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                                            .frame(width: 24, height: 24)
                                                    }
                                                }
                                            }
                                            
                                            if let savings = plan.savings {
                                                Text(savings)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.appGold)
                                            }
                                        }
                                        .padding(16)
                                        .background(selectedPlan == plan ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedPlan == plan ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Avantages Pro
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Avantages de l'abonnement Pro")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Gestion complète de votre établissement")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Création et gestion d'offres illimitées")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Statistiques détaillées de performance")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Visibilité accrue dans l'application")
                                    AdvantageRow(icon: "checkmark.circle.fill", text: "Support prioritaire")
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Bouton S'abonner
                            Button(action: {
                                // Simuler le paiement
                                showPayment = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showPayment = false
                                    onComplete()
                                }
                            }) {
                                HStack {
                                    if showPayment {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text(selectedPlan == .yearly ? "S'abonner - \(selectedPlan.price)/an" : "S'abonner - \(selectedPlan.price)/mois")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appGold)
                                .cornerRadius(12)
                            }
                            .disabled(showPayment)
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
                        appState.navigateToTab(tab, dismiss: {})
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
        ProSubscriptionView(userType: .constant(.pro), onComplete: {})
            .environmentObject(AppState())
    }
}

