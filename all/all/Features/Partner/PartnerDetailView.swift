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
    
    init(partner: Partner) {
        _viewModel = StateObject(wrappedValue: PartnerDetailViewModel(partner: partner))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 0) {
                            // Header avec image
                            ZStack(alignment: .topLeading) {
                                Image(systemName: viewModel.partner.headerImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                // Overlay gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.black.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 150)
                                
                                // Boutons de navigation
                                HStack {
                                    NavigationButton(
                                        icon: "arrow.left",
                                        iconColor: .white,
                                        backgroundColor: Color.black.opacity(0.5),
                                        action: {
                                            dismiss()
                                        }
                                    )
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.toggleFavorite()
                                            }
                                        }) {
                                            NavigationButton(
                                                icon: viewModel.partner.isFavorite ? "heart.fill" : "heart",
                                                iconColor: viewModel.partner.isFavorite ? .red : .white,
                                                backgroundColor: Color.black.opacity(0.5),
                                                action: {}
                                            )
                                        }
                                        
                                        Button(action: {
                                            // Action de partage
                                        }) {
                                            NavigationButton(
                                                icon: "square.and.arrow.up",
                                                iconColor: .white,
                                                backgroundColor: Color.black.opacity(0.5),
                                                action: {}
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            .frame(height: 150)
                            
                            // Contenu principal
                            VStack(alignment: .leading, spacing: 18) {
                                // Nom et catégorie
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(viewModel.partner.name)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            BadgeView(
                                                text: viewModel.partner.category,
                                                gradientColors: [Color.appDarkRed2, Color.appDarkRed1],
                                                fontSize: 12
                                            )
                                            
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
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                
                                // Description
                                if let description = viewModel.partner.description {
                                    Text(description)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(4)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 4)
                                }
                                
                                // Informations de contact
                                VStack(alignment: .leading, spacing: 6) {
                                    ContactRow(
                                        icon: "mappin.circle.fill",
                                        text: "\(viewModel.partner.address), \(viewModel.partner.postalCode) \(viewModel.partner.city)",
                                        iconColor: .appGold,
                                        action: {
                                            viewModel.openMaps()
                                        }
                                    )
                                    
                                    if let phone = viewModel.partner.phone {
                                        ContactRow(
                                            icon: "phone.fill",
                                            text: phone,
                                            iconColor: .appGold,
                                            action: {
                                                viewModel.callPartner()
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Boutons d'action - Instagram, Email, Website sur la même ligne
                                HStack(spacing: 12) {
                                    if viewModel.partner.instagram != nil {
                                        Button(action: {
                                            viewModel.openInstagram()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 0.8, green: 0.3, blue: 0.6),
                                                                Color(red: 0.9, green: 0.5, blue: 0.3),
                                                                Color(red: 0.95, green: 0.7, blue: 0.2)
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
                                    
                                    if viewModel.partner.email != nil {
                                        Button(action: {
                                            viewModel.openEmail()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appGold)
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "envelope.fill")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                        }
                                    }
                                    
                                    if viewModel.partner.website != nil {
                                        Button(action: {
                                            viewModel.openWebsite()
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appGold)
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "globe")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.callPartner()
                                    }) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.appGold)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
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
                                        
                                        Button(action: {
                                            // Action laisser un avis
                                        }) {
                                            Text("Laisser un avis")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
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
        .navigationDestination(item: $selectedOffer) { offer in
            OfferDetailView(offer: offer)
        }
    }
}

#Preview {
    NavigationStack {
        PartnerDetailView(partner: Partner(
            name: "GameZone VR",
            category: "Divertissement",
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

