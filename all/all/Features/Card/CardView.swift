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
    @State private var paymentResultPlanCategory: String? = nil // Catégorie du plan pour la redirection
    @State private var showWalletView: Bool = false
    @State private var showReferralsView: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Fonction pour calculer le padding horizontal responsive
    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        // Padding réduit de 16 points pour que les blocs soient plus larges
        return 16
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background avec gradient : sombre en haut vers rouge en bas
                AppGradient.main
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Titre en haut - ID pour scroll vers le haut
                            HStack {
                                Spacer()
                                Text("Ma Carte")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            .padding(.top, 2)
                            .padding(.bottom, 16)
                            .id("top")
        
                    
                    // États de chargement et d'erreur - selon guidelines Apple
                    // Afficher le loader uniquement pendant le chargement initial
                    if viewModel.isLoading && !viewModel.hasLoadedOnce {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(1.5)
                            
                            Text("Chargement de ta carte...")
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
                                .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            
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
                        // Afficher la carte si elle existe et est active - Format carte de crédit avec image en plein écran
                        // DEBUG: Log complet avec toutes les données du backend
                        let _ = viewModel.logAllBackendData()
                        ZStack {
                            // Image "MEMBRE DU CLUB10" en plein écran de la carte
                            Image("VIPCardImage")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                            
                            // Overlay avec texte organisé selon le design
                            VStack(alignment: .leading, spacing: 0) {
                                Spacer()
                                    .frame(height: 60) // Descendu de 3 lignes (20 + 40)
                                
                                // Au milieu : Type de carte + Titulaire + Nom
                                VStack(alignment: .leading, spacing: 8) {
                                    // Type de carte en jaune
                                    if let cardType = viewModel.cardType {
                                        Text(cardTypeDisplayName(cardType).uppercased())
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.appGold)
                                    }
                                    
                                    // Titulaire + Nom
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("TITULAIRE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text(viewModel.user.fullName)
                                            .font(.system(size: 24, weight: .heavy))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Spacer()
                                
                                // En bas : Date + Badge Actif (en bas à gauche)
                                HStack(alignment: .bottom, spacing: 12) {
                                    // Badge "Actif" en bas à gauche en vert
                                    if viewModel.isCardActive {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14))
                                            
                                            Text("Actif")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                    }
                                    
                                    Spacer()
                                    
                                    // Date d'expiration
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("VALIDE JUSQU'AU")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        if let expirationDate = viewModel.cardExpirationDate {
                                            Text(formatDateToFrenchLong(expirationDate))
                                                .font(.system(size: 18, weight: .heavy))
                                                .foregroundColor(.white)
                                        } else if !viewModel.formattedCardValidityDate.isEmpty {
                                            Text(viewModel.formattedCardValidityDate)
                                                .font(.system(size: 18, weight: .heavy))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        }
                        .frame(height: 220) // Format carte de crédit (ratio ~2:1)
                        .frame(maxWidth: geometry.size.width - (horizontalPadding(for: geometry.size.width) * 2))
                        .background(Color.clear) // Fond transparent pour éviter les bords blancs
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.clear, lineWidth: 0) // Pas de bordure
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, horizontalPadding(for: geometry.size.width))
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
                                        
                                        VStack(alignment: .center, spacing: 4) {
                                            Text("\(Int(viewModel.savings))€")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("Économies")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.9))
                                        }
                                        .frame(maxWidth: .infinity)
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
                                
                                Button(action: {
                                    showReferralsView = true
                                }) {
                                    StatCard(
                                        icon: "person.2.fill",
                                        value: "\(viewModel.referrals)",
                                        label: "Parrainages",
                                        iconColor: .red
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
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
                        .frame(maxWidth: geometry.size.width - (horizontalPadding(for: geometry.size.width) * 2))
                        .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                        .padding(.top, 24)
                        
                        // Section QR code de parrainage
                        VStack(alignment: .center, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                
                                Text("Code de parrainage")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // QR Code centré - taille réduite pour ne pas dépasser
                            QRCodeView(urlString: viewModel.referralQRCodeURL, size: 180)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            Text("Gagnez 50% de la 1ère mensualité de chaque filleul !")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray.opacity(0.9))
                                .lineSpacing(2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(18)
                        .frame(maxWidth: geometry.size.width - (horizontalPadding(for: geometry.size.width) * 2), alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.appDarkRed1.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                        .padding(.top, 24)
                        
                        // Lien URL en dehors de la carte, juste en dessous
                        ReferralLinkView(urlString: viewModel.referralQRCodeURL, referralCode: viewModel.referralCode)
                            .frame(maxWidth: geometry.size.width - (horizontalPadding(for: geometry.size.width) * 2))
                            .padding(.horizontal, horizontalPadding(for: geometry.size.width))
                            .padding(.top, 16)
                        
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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToTop"))) { notification in
                    if let tab = notification.userInfo?["tab"] as? TabItem, tab == .card {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
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
        .navigationDestination(isPresented: $showReferralsView) {
            ReferralsView()
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
            // Récupérer le prix et la catégorie du plan depuis userInfo si disponible
            if let userInfo = notification.userInfo {
                if let planPrice = userInfo["planPrice"] as? String {
                    paymentResultPlanPrice = planPrice
                }
                if let planCategory = userInfo["planCategory"] as? String {
                    paymentResultPlanCategory = planCategory
                }
            } else {
                paymentResultPlanPrice = nil
                paymentResultPlanCategory = nil
            }
            showPaymentResult = true
            // Forcer le rechargement complet des données de la carte depuis le backend
            viewModel.loadData(forceRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PaymentFailed"))) { _ in
            paymentResultStatus = .failed
            paymentResultPlanPrice = nil
            paymentResultPlanCategory = nil
            showPaymentResult = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadCardData"))) { _ in
            // Recharger les données de la carte quand on reçoit cette notification
            viewModel.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ForceReloadCardData"))) { _ in
            // Forcer le rechargement complet des données de la carte depuis le backend
            print("💳 [MA CARTE] ForceReloadCardData reçu - Rechargement forcé des données")
            viewModel.loadData(forceRefresh: true)
        }
        .onAppear {
            // Forcer le rechargement des données de la carte quand la vue apparaît
            // pour s'assurer que isCardActive et cardType sont à jour
            print("💳 [CARDVIEW] onAppear - Rechargement des données de la carte")
            viewModel.loadData(forceRefresh: true)
        }
        .sheet(isPresented: $showPaymentResult) {
            if let status = paymentResultStatus {
                PaymentResultView(
                    status: status,
                    planPrice: paymentResultPlanPrice,
                    planCategory: paymentResultPlanCategory,
                    onDismiss: {
                        // La navigation est gérée dans PaymentResultView selon le type d'utilisateur
                        // (pro -> ManageEstablishmentView, client -> accueil)
                        // Recharger les données de la carte en arrière-plan
                        viewModel.loadData()
                    }
                )
                .environmentObject(appState)
            }
        }
    }
    
    // Fonction helper pour afficher le nom du type de carte
    private func cardTypeDisplayName(_ cardType: String) -> String {
        switch cardType {
        case "FAMILY", "CLIENT_FAMILY":
            return "Carte familiale"
        case "PROFESSIONAL":
            return "Carte professionnelle"
        case "CLIENT", "CLIENT_INDIVIDUAL":
            return "Carte individuelle"
        default:
            return cardType
        }
    }
    
    // Fonction helper pour formater la date en français long (ex: "15 Juillet 2026")
    private func formatDateToFrenchLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

// Composant pour afficher le lien de parrainage avec bouton de copie
struct ReferralLinkView: View {
    let urlString: String
    let referralCode: String
    @State private var showCopiedMessage = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                // Zone scrollable pour le code (permet de faire défiler si trop long)
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(referralCode)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(minWidth: geometry.size.width - 80) // Largeur minimale pour permettre le scroll
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .frame(height: 40) // Hauteur fixe
                
                // Bouton de copie (toujours visible, taille fixe)
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedMessage ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                        if showCopiedMessage {
                            Text("Copié")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, showCopiedMessage ? 12 : 10)
                    .padding(.vertical, 10)
                    .frame(height: 40) // Même hauteur que le champ URL
                    .background(showCopiedMessage ? Color.green : Color.red)
                    .cornerRadius(8)
                }
                .fixedSize(horizontal: true, vertical: false) // Taille fixe horizontalement
                .animation(.easeInOut(duration: 0.2), value: showCopiedMessage)
            }
        }
        .frame(height: 40) // Hauteur fixe pour le GeometryReader
    }
    
    private func copyToClipboard() {
        // Copier uniquement le code de parrainage, sans l'URI
        UIPasteboard.general.string = referralCode
        showCopiedMessage = true
        
        // Réinitialiser le message après 2 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardView()
    }
}

