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
    @State private var isFavorite: Bool
    
    init(partner: Partner) {
        _viewModel = StateObject(wrappedValue: PartnerDetailViewModel(partner: partner))
        _isFavorite = State(initialValue: partner.isFavorite)
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
                                                isFavorite.toggle()
                                                viewModel.toggleFavorite()
                                            }
                                        }) {
                                            NavigationButton(
                                                icon: isFavorite ? "heart.fill" : "heart",
                                                iconColor: isFavorite ? .red : .white,
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
                                            // Ouvrir la carte
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
                                    
                                    // Email et Website sur la même ligne
                                    if viewModel.partner.email != nil || viewModel.partner.website != nil {
                                        HStack(spacing: 16) {
                                            if let email = viewModel.partner.email {
                                                Button(action: {
                                                    viewModel.openEmail()
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Text(email)
                                                            .font(.system(size: 13, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.9))
                                                        
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.gray.opacity(0.6))
                                                            .font(.system(size: 10, weight: .semibold))
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            
                                            if let website = viewModel.partner.website {
                                                Button(action: {
                                                    viewModel.openWebsite()
                                                }) {
                                                    HStack(spacing: 6) {
                                                        Text(website)
                                                            .font(.system(size: 13, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.9))
                                                        
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.gray.opacity(0.6))
                                                            .font(.system(size: 10, weight: .semibold))
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.leading, 50)
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Boutons d'action
                                HStack(spacing: 12) {
                                    if viewModel.partner.instagram != nil {
                                        Button(action: {
                                            viewModel.openInstagram()
                                        }) {
                                            // Logo Instagram
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 5)
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
                                                    .frame(width: 24, height: 24)
                                                
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                    
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
                                        
                                        VStack(spacing: 10) {
                                            ForEach(viewModel.currentOffers) { offer in
                                                CurrentOfferCard(offer: offer) {
                                                    // Navigation vers le détail de l'offre
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
                                        // Liste des avis
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.reviews) { review in
                                                // Card d'avis
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
                
                // Footer Bar - toujours visible (affichage uniquement)
                VStack {
                    Spacer()
                    FooterBar(selectedTab: .constant(.home)) { tab in
                        // Ne fait rien dans cette vue, juste pour l'affichage
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
    }
}

