//
//  CardSubscriptionView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CardSubscriptionView: View {
    @State private var showPayment = false
    @State private var showWhyCard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Icône de la carte
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 45))
                    .foregroundColor(.appGold)
                    .padding(.top, 10)
                
                // Titre
                Text("Ta carte digitale ALL IN")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                // Sous-titre
                Text("Rejoins la communauté et profite d'avantages exclusifs")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Liste des avantages
                VStack(spacing: 10) {
                    CardBenefitCard(
                        icon: "percent",
                        iconColor: .green,
                        title: "-10% partout",
                        description: "Chez tous les membres CLUB10"
                    )
                    
                    CardBenefitCard(
                        icon: "tag.fill",
                        iconColor: .green,
                        title: "Offres exclusives",
                        description: "Accès aux promos réservées aux abonnés"
                    )
                    
                    CardBenefitCard(
                        icon: "eurosign.circle.fill",
                        iconColor: .green,
                        title: "Programme parrainage",
                        description: "50% du 1er mois de chaque filleul"
                    )
                    
                    CardBenefitCard(
                        icon: "wallet.pass.fill",
                        iconColor: .green,
                        title: "Wallet intégré",
                        description: "Apple Wallet & Google Pay"
                    )
                    
                    CardBenefitCard(
                        icon: "bell.fill",
                        iconColor: .green,
                        title: "Alertes personnalisées",
                        description: "Ne rate plus aucune offre"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // Bouton S'abonner
                Button(action: {
                    showPayment = true
                }) {
                    Text("S'abonner")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appGold)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Lien "Pourquoi ma carte digitale"
                Button(action: {
                    showWhyCard = true
                }) {
                    Text("Pourquoi ma carte digitale ?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appGold)
                        .underline()
                }
                .padding(.top, 8)
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .sheet(isPresented: $showPayment) {
            NavigationStack {
                StripePaymentView()
            }
        }
        .sheet(isPresented: $showWhyCard) {
            NavigationStack {
                WhyCardDigitalView()
            }
        }
    }
}

struct CardBenefitCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appDarkRed1.opacity(0.6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 20))
            }
            
            // Texte
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct WhyCardDigitalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Titre
                    Text("Pourquoi ma carte digitale ?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Contenu
                    VStack(alignment: .leading, spacing: 16) {
                        CardInfoSection(
                            icon: "creditcard.fill",
                            title: "Carte digitale sécurisée",
                            description: "Votre carte est stockée de manière sécurisée dans votre téléphone. Plus besoin de transporter une carte physique."
                        )
                        
                        CardInfoSection(
                            icon: "star.fill",
                            title: "Avantages exclusifs",
                            description: "Accédez à des réductions et offres spéciales réservées aux membres CLUB10."
                        )
                        
                        CardInfoSection(
                            icon: "bell.fill",
                            title: "Notifications personnalisées",
                            description: "Recevez des alertes sur les nouvelles offres et promotions près de chez vous."
                        )
                        
                        CardInfoSection(
                            icon: "wallet.pass.fill",
                            title: "Intégration Wallet",
                            description: "Ajoutez votre carte à Apple Wallet ou Google Pay pour un accès rapide."
                        )
                        
                        CardInfoSection(
                            icon: "person.2.fill",
                            title: "Programme de parrainage",
                            description: "Gagnez 50% du premier mois de chaque personne que vous parrainez."
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
    }
}

struct CardInfoSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.appGold)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        CardSubscriptionView()
    }
}

