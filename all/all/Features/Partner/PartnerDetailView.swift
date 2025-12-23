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
                            .frame(height: 250)
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
                        .frame(height: 250)
                        
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
                    .frame(height: 250)
                    
                    // Contenu principal
                    VStack(alignment: .leading, spacing: 24) {
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
                        }
                        
                        // Informations de contact
                        VStack(alignment: .leading, spacing: 12) {
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
                            
                            if let email = viewModel.partner.email {
                                ContactRow(
                                    icon: "envelope.fill",
                                    text: email,
                                    iconColor: .appGold,
                                    action: {
                                        viewModel.openEmail()
                                    }
                                )
                            }
                            
                            if let website = viewModel.partner.website {
                                ContactRow(
                                    icon: "globe",
                                    text: website,
                                    iconColor: .appGold,
                                    action: {
                                        viewModel.openWebsite()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Boutons d'action
                        HStack(spacing: 12) {
                            if let instagram = viewModel.partner.instagram {
                                Button(action: {
                                    viewModel.openInstagram()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                        Text("Instagram")
                                            .font(.system(size: 15, weight: .semibold))
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
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                    Text("Contact")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.appGold)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Action voir fiche
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 16))
                                    Text("Voir fiche")
                                        .font(.system(size: 15, weight: .semibold))
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
                        .padding(.horizontal, 20)
                        
                        // Section "Offres en cours"
                        if !viewModel.currentOffers.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Offres en cours")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(viewModel.currentOffers) { offer in
                                        CurrentOfferCard(offer: offer) {
                                            // Navigation vers le détail de l'offre
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 8)
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
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

