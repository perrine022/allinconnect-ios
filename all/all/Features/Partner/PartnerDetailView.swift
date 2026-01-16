//
//  PartnerDetailView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct PartnerDetailView: View {
    @StateObject private var viewModel: PartnerDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedOffer: Offer?
    @State private var showRatingPopup = false
    @State private var isLoggedIn = LoginViewModel.isLoggedIn()
    @State private var showImageZoom = false
    
    // Vérifier si l'utilisateur peut laisser un avis (connecté avec statut CLIENT ou PRO)
    private var canLeaveRating: Bool {
        guard isLoggedIn else { return false }
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? ""
        return userTypeString == "CLIENT" || userTypeString == "PRO"
    }
    
    init(partner: Partner) {
        _viewModel = StateObject(wrappedValue: PartnerDetailViewModel(partner: partner))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header avec fond rouge foncé et image d'établissement
                            ZStack {
                                // Fond rouge foncé
                                Color.appDarkRed2
                                    .frame(height: 200)
                                
                                // Image de l'établissement ou logo stylisé "A" en arrière-plan
                                // Dimensions fixes pour un affichage cohérent (ratio 16:9)
                                Button(action: {
                                    if viewModel.partner.establishmentImageUrl != nil {
                                        showImageZoom = true
                                    }
                                }) {
                                    Group {
                                        if let imageUrl = ImageURLHelper.buildImageURL(from: viewModel.partner.establishmentImageUrl),
                                           let url = URL(string: imageUrl) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    Text("A")
                                                        .font(.system(size: 120, weight: .ultraLight))
                                                        .foregroundColor(Color.appDarkRed1.opacity(0.3))
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .opacity(0.3)
                                                case .failure:
                                                    Text("A")
                                                        .font(.system(size: 120, weight: .ultraLight))
                                                        .foregroundColor(Color.appDarkRed1.opacity(0.3))
                                                @unknown default:
                                                    Text("A")
                                                        .font(.system(size: 120, weight: .ultraLight))
                                                        .foregroundColor(Color.appDarkRed1.opacity(0.3))
                                                }
                                            }
                                        } else {
                                            // Logo stylisé "A" en arrière-plan
                                            Text("A")
                                                .font(.system(size: 120, weight: .ultraLight))
                                                .foregroundColor(Color.appDarkRed1.opacity(0.3))
                                        }
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(viewModel.partner.establishmentImageUrl == nil)
                                
                                // Boutons de navigation - positionnés en haut, proches des bords
                                VStack {
                                    HStack {
                                        Button(action: {
                                            dismiss()
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.black.opacity(0.8))
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(systemName: "arrow.left")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.toggleFavorite()
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.black.opacity(0.8))
                                                    .frame(width: 44, height: 44)
                                                
                                                if viewModel.isTogglingFavorite {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        .scaleEffect(0.7)
                                                } else {
                                                    Image(systemName: viewModel.partner.isFavorite ? "heart.fill" : "heart")
                                                        .foregroundColor(viewModel.partner.isFavorite ? .red : .white)
                                                        .font(.system(size: 18, weight: .semibold))
                                                }
                                            }
                                        }
                                        .disabled(viewModel.isTogglingFavorite)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, max(geometry.safeAreaInsets.top, 8) + 100)
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 200)
                            
                            // Contenu principal
                            VStack(alignment: .leading, spacing: 18) {
                                // Nom du studio
                                Text(viewModel.partner.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                
                                // Badge catégorie, sous-catégorie et note sur la même ligne
                                HStack(spacing: 12) {
                                    // Afficher la catégorie
                                    BadgeView(
                                        text: viewModel.partner.category,
                                        gradientColors: [Color.appDarkRed2, Color.appDarkRed1],
                                        fontSize: 12
                                    )
                                    
                                    // Afficher la sous-catégorie si disponible
                                    if let subCategory = viewModel.partner.subCategory, !subCategory.isEmpty {
                                        BadgeView(
                                            text: subCategory,
                                            gradientColors: [Color.appDarkRed1.opacity(0.8), Color.appDarkRed2.opacity(0.8)],
                                            fontSize: 12
                                        )
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.appGold)
                                            .font(.system(size: 14))
                                        
                                        Text(String(format: "%.1f", viewModel.partner.rating))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("(\(viewModel.partner.reviewCount) avis)")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // Description
                                if let description = viewModel.partner.description {
                                    Text(description)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(4)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 4)
                                }
                                
                                // Message d'erreur favoris
                                if let errorMessage = viewModel.favoriteErrorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.red.opacity(0.9))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                }
                                
                                // Informations de contact avec icônes circulaires rouges
                                VStack(alignment: .leading, spacing: 12) {
                                    Button(action: {
                                        viewModel.openMaps()
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: "info.circle.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 18))
                                            }
                                            
                                            Text("\(viewModel.partner.address), \(viewModel.partner.postalCode) \(viewModel.partner.city)")
                                                .font(.system(size: 15, weight: .regular))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    
                                    if viewModel.partner.phone != nil {
                                        Button(action: {
                                            viewModel.callPartner()
                                        }) {
                                            HStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Image(systemName: "phone.fill")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18))
                                                }
                                                
                                                Text(viewModel.partner.phone ?? "")
                                                    .font(.system(size: 15, weight: .regular))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                    }
                                    
                                    if viewModel.partner.email != nil {
                                        Button(action: {
                                            viewModel.openEmail()
                                        }) {
                                            HStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.red)
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Image(systemName: "envelope.fill")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18))
                                                }
                                                
                                                Text(viewModel.partner.email ?? "")
                                                    .font(.system(size: 15, weight: .regular))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // Boutons d'action - tous affichés si les données existent
                                HStack(spacing: 12) {
                                    // Instagram
                                    if let instagram = viewModel.partner.instagram, !instagram.isEmpty {
                                        Button(action: {
                                            viewModel.openInstagram()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 0.9, green: 0.4, blue: 0.5),
                                                                Color(red: 0.95, green: 0.6, blue: 0.3)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    // Email
                                    if let email = viewModel.partner.email, !email.isEmpty {
                                        Button(action: {
                                            viewModel.openEmail()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.red)
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "envelope.fill")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    // Website
                                    if let website = viewModel.partner.website, !website.isEmpty {
                                        Button(action: {
                                            viewModel.openWebsite()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.red)
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "globe")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    // Appeler
                                    if let phone = viewModel.partner.phone, !phone.isEmpty {
                                        Button(action: {
                                            viewModel.callPartner()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "phone.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                
                                                Text("Appeler")
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                            .background(Color.red)
                                            .cornerRadius(10)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                // Section "Offres en cours"
                                if !viewModel.currentOffers.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Offres en cours")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.currentOffers) { offer in
                                                OfferListCard(offer: offer) {
                                                    selectedOffer = offer
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    .padding(.top, 4)
                                }
                                
                                // Section "Avis All In Connect"
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Avis All In Connect")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        // Afficher le bouton si l'utilisateur est connecté avec statut CLIENT ou PRO
                                        if canLeaveRating {
                                            Button(action: {
                                                showRatingPopup = true
                                            }) {
                                                Text("Laisser un avis")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.red)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    if viewModel.reviews.isEmpty {
                                        Text("Aucun avis pour le moment")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 20)
                                    } else {
                                        // Liste des avis (2 avis max)
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.reviews) { review in
                                                ReviewCard(review: review)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.top, 24)
                                .padding(.bottom, 100) // Espace pour le footer
                            }
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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe vers la droite (translation.width > 0) pour revenir en arrière
                    if value.translation.width > 50 && abs(value.translation.width) > abs(value.translation.height) {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showImageZoom) {
            ImageZoomView(
                imageUrl: viewModel.partner.establishmentImageUrl,
                profileImageName: "camera.fill"
            )
        }
        .navigationDestination(item: $selectedOffer) { offer in
            OfferDetailView(offer: offer)
        }
        .overlay {
            if showRatingPopup {
                RatingPopupView(
                    isPresented: $showRatingPopup,
                    partnerName: viewModel.partner.name,
                    onRatingSubmit: { rating in
                        // Vérifier à nouveau avant de soumettre
                        if canLeaveRating {
                            viewModel.submitRating(rating, comment: nil)
                        }
                    }
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogin"))) { _ in
            isLoggedIn = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogout"))) { _ in
            isLoggedIn = false
        }
    }
}

#Preview {
    NavigationStack {
        PartnerDetailView(partner: Partner(
            name: "GameZone VR",
            category: "Divertissement",
            subCategory: "Jeux vidéo",
            address: "120 Cours Lafayette",
            city: "Lyon",
            postalCode: "69003",
            phone: "04 78 00 00 04",
            email: "info@gamezonevr.fr",
            website: "https://gamezonevr.fr",
            instagram: "https://instagram.com/gamezonevr",
            description: "Centre de réalité virtuelle avec plus de 50 jeux et expériences. Escape games VR, simulateurs et anniversaires.",
            rating: 4.8,
            reviewCount: 89,
            discount: nil,
            imageName: "gamecontroller.fill",
            headerImageName: "gamecontroller.fill",
            isFavorite: false
        ))
        .environmentObject(AppState())
    }
}

