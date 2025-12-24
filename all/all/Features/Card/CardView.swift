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
                VStack(spacing: 20) {
                    // Titre
                    HStack {
                        Text("Ma Carte")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // États de chargement et d'erreur
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                            .scaleEffect(1.5)
                            .padding(.vertical, 50)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.appGold)
                            Text("Erreur")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                viewModel.loadData()
                            }) {
                                Text("Réessayer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appGold)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 50)
                    } else {
                        // Carte utilisateur principale
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                // Logo ALL IN
                                VStack(alignment: .leading, spacing: 4) {
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
                                    
                                    Text("Connect")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.appRed.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                // Badge ACTIVE (seulement si la carte est active)
                                if viewModel.isCardActive {
                                    Text("ACTIVE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green)
                                        .cornerRadius(6)
                                }
                            }
                            
                            // Nom utilisateur
                            Text(viewModel.user.fullName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 4)
                            
                            // Numéro de carte si disponible
                            if let cardNumber = viewModel.cardNumber {
                                Text("Carte: \(cardNumber)")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                            
                            // Code utilisateur
                            Text("Code: \(viewModel.referralCode)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                            
                            // Membre CLUB10 (seulement si membre)
                            if viewModel.isMember {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 14))
                                    
                                    Text("Membre CLUB10")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.appDarkRed1.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Grille de statistiques
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
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
                            
                            HStack(spacing: 10) {
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
                                .font(.system(size: 16))
                            
                            Text("Lien de parrainage")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 12) {
                            Text(viewModel.referralLink)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.copyReferralLink()
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(Color.appDarkRed2.opacity(0.7))
                        .cornerRadius(10)
                        
                        Text("Gagnez 50% de la 1ère mensualité de chaque filleul !")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.9))
                            .lineSpacing(2)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.appDarkRed1.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Section Mes favoris
                    if !viewModel.favoritePartners.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Mes favoris")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                ForEach(viewModel.favoritePartners) { partner in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedPartner = partner
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            // Image
                                            Image(systemName: partner.imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 56, height: 56)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .foregroundColor(.gray.opacity(0.3))
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(partner.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(.white)
                                                
                                                Text(partner.category)
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.gray.opacity(0.9))
                                            }
                                            
                                            Spacer()
                                            
                                            // Badge réduction
                                            if let discount = partner.discount {
                                                Text("-\(discount)%")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 9)
                                                    .padding(.vertical, 5)
                                                    .background(Color.green)
                                                    .cornerRadius(6)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.appDarkRed1.opacity(0.7))
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        )
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
                        .padding(.top, 4)
                    }
                    
                        // Espace pour le footer
                        Spacer()
                            .frame(height: 100)
                    }
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

