//
//  CardView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CardView: View {
    @StateObject private var viewModel = CardViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showAddSavingsPopup: Bool = false
    @State private var showSavingsList: Bool = false
    @State private var showFamilyManagement: Bool = false
    @State private var showPaymentResult: Bool = false
    @State private var paymentResultStatus: PaymentResultView.PaymentResultStatus? = nil
    @State private var showWalletView: Bool = false
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Bannière VIP en haut
                    Image("VIPMemberBanner")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Titre
                    HStack {
                        Text("Ma Carte")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // États de chargement et d'erreur - selon guidelines Apple
                    // Afficher le loader uniquement pendant le chargement initial
                    if viewModel.isLoading && !viewModel.hasLoadedOnce {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appDarkRedButton))
                                .scaleEffect(1.5)
                            
                            Text("Chargement de votre carte...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 100)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.appDarkRedButton)
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
                                    .background(Color.appDarkRedButton)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 50)
                    } else if viewModel.hasLoadedOnce && viewModel.cardNumber != nil && viewModel.isCardActive {
                        // Afficher la carte si elle existe et est active - avec transition fluide
                        // Carte utilisateur principale
                        let cardBackgroundColor = viewModel.isCardValid ? Color.white : Color.red
                        let textColor = viewModel.isCardValid ? Color.black : Color.white
                        let secondaryTextColor = viewModel.isCardValid ? Color.gray : Color.white.opacity(0.8)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            // Image VIP en haut de la carte
                            Image("VIPCardImage")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(12)
                                .padding(.bottom, 8)
                            
                            HStack(alignment: .top) {
                                // Logo ALL IN
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text("ALL")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(textColor)
                                        
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
                                            .foregroundColor(textColor)
                                    }
                                    
                                    Text("Connect")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(viewModel.isCardValid ? Color.appRed : Color.white.opacity(0.9))
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
                            
                            // Badge "Carte familiale" si type FAMILY ou CLIENT_FAMILY
                            if viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY" {
                                Text("Carte familiale")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.isCardValid ? .appRed : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.isCardValid ? Color.appRed.opacity(0.2) : Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                    .padding(.top, 4)
                            }
                            
                            // Nom utilisateur
                            Text(viewModel.user.fullName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(textColor)
                                .padding(.top, 4)
                            
                            // Numéro de carte si disponible
                            if let cardNumber = viewModel.cardNumber {
                                Text("Carte: \(cardNumber)")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(secondaryTextColor)
                                    .padding(.top, 2)
                            }
                            
                            // Date de validité
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(secondaryTextColor)
                                    .font(.system(size: 12))
                                Text("Valide jusqu'au: \(viewModel.formattedExpirationDate)")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(secondaryTextColor)
                            }
                            .padding(.top, 2)
                            
                            // Membre CLUB10 (seulement si membre)
                            if viewModel.isMember {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(viewModel.isCardValid ? .appRed : .white)
                                        .font(.system(size: 14))
                                    
                                    Text("Membre CLUB10")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(viewModel.isCardValid ? .appRed : .white)
                                }
                                .padding(.top, 4)
                            }
                            
                            // Bouton "Gérer ma famille" si carte familiale
                            if viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY" {
                                Button(action: {
                                    showFamilyManagement = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(viewModel.isCardValid ? .appRed : .white)
                                            .font(.system(size: 16))
                                        
                                        Text("Gérer ma famille")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(viewModel.isCardValid ? .appRed : .white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.isCardValid ? Color.appRed.opacity(0.2) : Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                }
                                .padding(.top, 12)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(cardBackgroundColor)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(viewModel.isCardValid ? Color.gray.opacity(0.2) : Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.hasLoadedOnce)
                        
                        // Grille de statistiques
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                // Carte des économies avec bouton d'ajout (cliquable pour voir la liste)
                                Button(action: {
                                    showSavingsList = true
                                }) {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "banknote.fill")
                                                .foregroundColor(.appDarkRedButton)
                                                .font(.system(size: 24))
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                showAddSavingsPopup = true
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.appDarkRedButton)
                                                    .font(.system(size: 20))
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(Int(viewModel.savings))€")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("Économies")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.9))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.appDarkRed1.opacity(0.85))
                                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.appDarkRedButton.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                StatCard(
                                    icon: "person.2.fill",
                                    value: "\(viewModel.referrals)",
                                    label: "Parrainages",
                                    iconColor: .appDarkRedButton
                                )
                            }
                            
                            HStack(spacing: 10) {
                                Button(action: {
                                    showWalletView = true
                                }) {
                                    StatCard(
                                        icon: "wallet.pass.fill",
                                        value: "\(Int(viewModel.wallet))€",
                                        label: "Cagnotte",
                                        iconColor: .appDarkRedButton
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                StatCard(
                                    icon: "heart.fill",
                                    value: "\(viewModel.favoritesCount)",
                                    label: "Favoris",
                                    iconColor: .appDarkRedButton
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Section lien de parrainage
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.appDarkRedButton)
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
                                        .foregroundColor(.appDarkRedButton)
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
                        
                        // Espace pour le footer
                        Spacer()
                            .frame(height: 100)
                    } else if viewModel.hasLoadedOnce {
                        // Vue d'abonnement si pas de carte ou carte inactive (seulement après chargement)
                        CardSubscriptionView()
                            .padding(.top, 20)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showSavingsList) {
            SavingsListView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showFamilyManagement) {
            FamilyCardManagementView()
        }
        .navigationDestination(isPresented: $showWalletView) {
            WalletView()
        }
        .overlay {
            if showAddSavingsPopup {
                AddSavingsPopupView(
                    isPresented: $showAddSavingsPopup,
                    onSave: { amount, date, store, description in
                        viewModel.addSavings(amount: amount, date: date, store: store, description: description)
                    }
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentSuccess"))) { _ in
            paymentResultStatus = .success
            showPaymentResult = true
            // Recharger les données de la carte
            viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentFailed"))) { _ in
            paymentResultStatus = .failed
            showPaymentResult = true
        }
        .sheet(isPresented: $showPaymentResult) {
            if let status = paymentResultStatus {
                PaymentResultView(status: status)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardView()
    }
}

