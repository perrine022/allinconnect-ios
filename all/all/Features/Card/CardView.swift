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
    @State private var paymentResultPlanPrice: String? = nil // Prix du plan choisi pour l'affichage
    @State private var showWalletView: Bool = false
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Titre en haut
                    HStack {
                        Text("Ma Carte")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
                    .padding(.bottom, 16)
        
                    
                    // États de chargement et d'erreur - selon guidelines Apple
                    // Afficher le loader uniquement pendant le chargement initial
                    if viewModel.isLoading && !viewModel.hasLoadedOnce {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
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
                                .foregroundColor(.red)
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
                                    .background(Color.red)
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Image VIP en haut de la carte - plus visible
                            Image("VIPCardImage")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(20, corners: [.topLeft, .topRight])
                                .padding(.horizontal, -16)
                                .padding(.top, -16)
                                .padding(.bottom, 8)
                            
                            HStack(alignment: .top, spacing: 8) {
                                // Logo ALL IN - plus compact
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 3) {
                                        Text("ALL")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(textColor)
                                        
                                        ZStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 16, height: 16)
                                            
                                            Circle()
                                                .fill(Color.red.opacity(0.6))
                                                .frame(width: 13, height: 13)
                                            
                                            Circle()
                                                .fill(Color.red.opacity(0.3))
                                                .frame(width: 10, height: 10)
                                        }
                                        
                                        Text("IN")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(textColor)
                                    }
                                    
                                    Text("Connect")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(viewModel.isCardValid ? Color.red : Color.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                // Badge ACTIVE (seulement si la carte est active)
                                if viewModel.isCardActive {
                                    Text("ACTIVE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .cornerRadius(5)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Badge "Carte familiale" si type FAMILY ou CLIENT_FAMILY - plus compact
                            if viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY" {
                                Text("Carte familiale")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(viewModel.isCardValid ? .red : .white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(viewModel.isCardValid ? Color.red.opacity(0.2) : Color.white.opacity(0.2))
                                    .cornerRadius(6)
                                    .padding(.top, 2)
                            }
                            
                            // Nom utilisateur - plus compact
                            Text(viewModel.user.fullName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(textColor)
                                .padding(.top, 2)
                            
                            // Numéro de carte et date sur la même ligne - plus compact
                            HStack(spacing: 12) {
                                if let cardNumber = viewModel.cardNumber {
                                    Text("Carte: \(cardNumber)")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(secondaryTextColor)
                                }
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(secondaryTextColor)
                                        .font(.system(size: 9))
                                    Text("Valide: \(viewModel.formattedExpirationDate)")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(secondaryTextColor)
                                }
                            }
                            .padding(.top, 1)
                            
                            // Membre CLUB10 (seulement si membre) - plus compact
                            if viewModel.isMember {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(viewModel.isCardValid ? .red : .white)
                                        .font(.system(size: 11))
                                    
                                    Text("Membre CLUB10")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(viewModel.isCardValid ? .red : .white)
                                }
                                .padding(.top, 2)
                            }
                            
                            // Bouton "Gérer ma famille" si carte familiale et si l'utilisateur est propriétaire - plus compact
                            if (viewModel.cardType == "FAMILY" || viewModel.cardType == "CLIENT_FAMILY") && viewModel.isCardOwner {
                                Button(action: {
                                    showFamilyManagement = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(viewModel.isCardValid ? .red : .white)
                                            .font(.system(size: 13))
                                        
                                        Text("Gérer ma famille")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(viewModel.isCardValid ? .red : .white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(viewModel.isCardValid ? Color.red.opacity(0.2) : Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .padding(.top, 6)
                            }
                        }
                        .padding(16)
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
                        .padding(.top, 0)
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
                                                .foregroundColor(.red)
                                                .font(.system(size: 24))
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                showAddSavingsPopup = true
                                            }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.red)
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
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                StatCard(
                                    icon: "person.2.fill",
                                    value: "\(viewModel.referrals)",
                                    label: "Parrainages",
                                    iconColor: .red
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
                                        iconColor: .red
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                StatCard(
                                    icon: "heart.fill",
                                    value: "\(viewModel.favoritesCount)",
                                    label: "Favoris",
                                    iconColor: .red
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Section lien de parrainage
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.red)
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
                                        .foregroundColor(.red)
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
                        .padding(.top, 24)
                        
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentSuccess"))) { notification in
            paymentResultStatus = .success
            // Récupérer le prix du plan depuis userInfo si disponible
            if let userInfo = notification.userInfo,
               let planPrice = userInfo["planPrice"] as? String {
                paymentResultPlanPrice = planPrice
            } else {
                // Essayer de récupérer depuis le plan sélectionné dans StripePaymentView
                // Pour l'instant, on utilise une valeur par défaut ou nil
                paymentResultPlanPrice = nil
            }
            showPaymentResult = true
            // Recharger les données de la carte
            viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentFailed"))) { _ in
            paymentResultStatus = .failed
            paymentResultPlanPrice = nil
            showPaymentResult = true
        }
        .sheet(isPresented: $showPaymentResult) {
            if let status = paymentResultStatus {
                PaymentResultView(status: status, planPrice: paymentResultPlanPrice)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardView()
    }
}

