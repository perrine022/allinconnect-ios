//
//  ManageSubscriptionsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ManageSubscriptionsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManageSubscriptionsViewModel()
    @State private var showCancelAlert = false
    
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
                            
                            // Indicateur de chargement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            }
                            
                            // Abonnement actuel
                            if viewModel.currentSubscriptionPlan != nil {
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
                                            
                                            Text(viewModel.currentFormula)
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
                                            
                                            Text(viewModel.currentAmount.isEmpty ? "N/A" : viewModel.currentAmount)
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
                                            
                                            Text(viewModel.nextPaymentDate.isEmpty ? "N/A" : viewModel.nextPaymentDate)
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
                                            
                                            Text(viewModel.commitmentUntil.isEmpty ? "N/A" : viewModel.commitmentUntil)
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
                            }
                            
                            // Message d'erreur
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Changer de formule
                            if !viewModel.availablePlans.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Changer de formule")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.availablePlans) { plan in
                                            Button(action: {
                                                viewModel.selectedPlan = plan
                                            }) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(plan.title)
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(.white)
                                                        
                                                        Text(plan.priceLabel)
                                                            .font(.system(size: 13, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.8))
                                                        
                                                        if plan.isAnnual {
                                                            // Calculer l'économie
                                                            if let monthlyPlan = viewModel.availablePlans.first(where: { $0.isMonthly }) {
                                                                let monthlyPrice = monthlyPlan.price
                                                                let annualMonthlyEquivalent = plan.price / 12.0
                                                                let savings = ((monthlyPrice * 12) - plan.price) / (monthlyPrice * 12) * 100
                                                                
                                                                Text("Économisez \(Int(savings))%")
                                                                    .font(.system(size: 12, weight: .semibold))
                                                                    .foregroundColor(.appGold)
                                                            }
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    ZStack {
                                                        Circle()
                                                            .fill(viewModel.selectedPlan?.id == plan.id ? Color.appGold : Color.clear)
                                                            .frame(width: 24, height: 24)
                                                        
                                                        if viewModel.selectedPlan?.id == plan.id {
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
                                                .background(viewModel.selectedPlan?.id == plan.id ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.4))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(viewModel.selectedPlan?.id == plan.id ? Color.appGold : Color.clear, lineWidth: 2)
                                                )
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Bouton Modifier
                                    Button(action: {
                                        viewModel.updateSubscription()
                                    }) {
                                        HStack {
                                            if viewModel.isLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            } else {
                                                Text("Modifier mon abonnement")
                                                    .font(.system(size: 16, weight: .bold))
                                            }
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background((viewModel.selectedPlan != nil && !viewModel.isLoading) ? Color.appGold : Color.gray.opacity(0.5))
                                        .cornerRadius(12)
                                    }
                                    .disabled(viewModel.selectedPlan == nil || viewModel.isLoading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                }
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
        .task {
            await viewModel.loadSubscriptionData()
        }
        .alert("Résilier l'abonnement", isPresented: $showCancelAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Résilier", role: .destructive) {
                viewModel.cancelSubscription()
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

