//
//  CardView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CardView: View {
    @StateObject private var viewModel = CardViewModel()
    @State private var selectedPartner: Partner?
    
    var body: some View {
        ZStack {
            // Background avec gradient
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
                        Text("Ma Carte")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Carte utilisateur principale
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            // Logo ALL IN
                            HStack(spacing: 4) {
                                Text("ALL")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .fill(Color.appRed)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .fill(Color.appRed.opacity(0.6))
                                        .frame(width: 20, height: 20)
                                    
                                    Circle()
                                        .fill(Color.appRed.opacity(0.3))
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text("IN")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Badge ACTIVE
                            Text("ACTIVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        
                        Text("Connect")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appRed.opacity(0.9))
                        
                        // Nom utilisateur
                        Text(viewModel.user.fullName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Code utilisateur
                        Text("Code: \(viewModel.referralCode)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                        
                        // Membre CLUB10
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appGold)
                                .font(.system(size: 16))
                            
                            Text("Membre CLUB10")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.appGold)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appDarkRed1.opacity(0.8))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Grille de statistiques
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "banknote.fill",
                                value: "\(Int(viewModel.savings))€",
                                label: "Économies",
                                iconColor: .appGold
                            )
                            
                            StatCard(
                                icon: "person.2.fill",
                                value: "\(viewModel.referrals)",
                                label: "Parrainages",
                                iconColor: .appGold
                            )
                        }
                        
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "wallet.pass.fill",
                                value: "\(Int(viewModel.wallet))€",
                                label: "Cagnotte",
                                iconColor: .appGold
                            )
                            
                            StatCard(
                                icon: "heart.fill",
                                value: "\(viewModel.favoritesCount)",
                                label: "Favoris",
                                iconColor: .appGold
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Section lien de parrainage
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.appGold)
                                .font(.system(size: 18))
                            
                            Text("Lien de parrainage")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text(viewModel.referralLink)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.copyReferralLink()
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appDarkRed2.opacity(0.6))
                        .cornerRadius(12)
                        
                        Text("Gagnez 50% de la 1ère mensualité de chaque filleul !")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appDarkRed1.opacity(0.8))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Boutons portefeuille
                    HStack(spacing: 12) {
                        Button(action: {
                            // Action Apple Wallet
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18))
                                Text("Apple Wallet")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Action Google Wallet
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 18))
                                Text("Google Wallet")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Section Mes favoris
                    if !viewModel.favoritePartners.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Mes favoris")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.favoritePartners) { partner in
                                    Button(action: {
                                        selectedPartner = partner
                                    }) {
                                        HStack(spacing: 12) {
                                            // Image
                                            Image(systemName: partner.imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .foregroundColor(.gray.opacity(0.3))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(partner.name)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                
                                                Text(partner.category)
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            // Badge réduction
                                            if let discount = partner.discount {
                                                Text("-\(discount)%")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.green)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color.appDarkRed1.opacity(0.6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Espace pour le footer
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

#Preview {
    NavigationStack {
        CardView()
    }
}

