//
//  ManageSubscriptionsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ManageSubscriptionsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var showCancelAlert = false
    
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
                            HStack {
                                Text("Gérer mes abonnements")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Abonnement actuel
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 18))
                                    
                                    Text("Abonnement actuel")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Formule")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("Mensuel")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.appGold)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        Text("Montant")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("49,90€ / mois")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        Text("Prochain prélèvement")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("15/02/2026")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.appGold)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        Text("Engagement jusqu'au")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                        
                                        Text("15/02/2027")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.appDarkRed1.opacity(0.8))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            
                            // Changer de formule
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Changer de formule")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                                        Button(action: {
                                            selectedPlan = plan
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(plan.rawValue)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.white)
                                                    
                                                    if plan == .yearly {
                                                        Text("\(plan.price)/an - Soit \(plan.monthlyEquivalent)/mois")
                                                            .font(.system(size: 13, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.8))
                                                        
                                                        Text("Économisez 17%")
                                                            .font(.system(size: 12, weight: .semibold))
                                                            .foregroundColor(.appGold)
                                                    } else {
                                                        Text(plan.price + "/mois")
                                                            .font(.system(size: 13, weight: .regular))
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
                                
                                // Bouton Modifier
                                Button(action: {
                                    // Modifier l'abonnement
                                }) {
                                    Text("Modifier mon abonnement")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.appGold)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Bouton Résilier
                            Button(action: {
                                showCancelAlert = true
                            }) {
                                Text("Résilier mon abonnement")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appRed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.appRed, lineWidth: 1.5)
                                    )
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
        .alert("Résilier l'abonnement", isPresented: $showCancelAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Résilier", role: .destructive) {
                // Résilier l'abonnement
            }
        } message: {
            Text("Êtes-vous sûr de vouloir résilier votre abonnement ? Vous perdrez l'accès à toutes les fonctionnalités Pro.")
        }
    }
}

#Preview {
    NavigationStack {
        ManageSubscriptionsView()
            .environmentObject(AppState())
    }
}

