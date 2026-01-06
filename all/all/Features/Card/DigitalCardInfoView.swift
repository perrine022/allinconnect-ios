//
//  DigitalCardInfoView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct DigitalCardInfoView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var stripePaymentNavigationId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.appDarkRed2, // #421515
                            Color.appDarkRed1, // #1D0809
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Titre et sous-titre
                            VStack(spacing: 8) {
                                Text("Pourquoi ta carte digitale ?")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Des bénéfices qui changent tout")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Cartes des avantages
                            VStack(spacing: 12) {
                                // Carte 1: Au prix d'un café
                                BenefitCard(
                                    icon: "person.2.fill",
                                    iconColor: .blue,
                                    title: "Au prix d'un café",
                                    description: "Seulement 2,99€/mois (engagement 6 mois)"
                                )
                                
                                // Carte 2: Avantage de dingue
                                BenefitCard(
                                    icon: "bolt.fill",
                                    iconColor: .yellow,
                                    title: "Avantage de dingue",
                                    description: "10% chez tous les membres du CLUB10 (coiffeurs, massages, garages, coach, divertissement, food...)"
                                )
                                
                                // Carte 3: Économies maximales
                                BenefitCard(
                                    icon: "dollarsign.circle.fill",
                                    iconColor: .appGold,
                                    title: "Économies maximales",
                                    description: "Plus de 500€ par an garantis"
                                )
                                
                                // Carte 4: Newsletter exclusive
                                BenefitCard(
                                    icon: "envelope.fill",
                                    iconColor: .blue,
                                    title: "Newsletter exclusive",
                                    description: "Offres & évènements en avant-première"
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Bouton OBTENIR MA CARTE
                            Button(action: {
                                // Naviguer vers la page de sélection d'abonnement CLIENT
                                stripePaymentNavigationId = UUID()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 16))
                                    
                                    Text("OBTENIR MA CARTE")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Espace pour le footer
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $stripePaymentNavigationId) { _ in
            StripePaymentView(filterCategory: "CLIENT", showFamilyCardPromotion: true)
        }
    }
}

struct BenefitCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Badge -10% vert (comme sur les fiches pros)
            Text("-10%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            
            // Texte
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed2.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        DigitalCardInfoView()
            .environmentObject(AppState())
    }
}

