//
//  OfferDetailView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OfferDetailView: View {
    let offer: Offer
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedPartner: Partner?
    
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
                            // Image header
                            ZStack(alignment: .topLeading) {
                                Image(systemName: offer.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
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
                                .frame(height: 200)
                                
                                // Bouton retour
                                HStack {
                                    NavigationButton(
                                        icon: "arrow.left",
                                        iconColor: Color.white,
                                        backgroundColor: Color.black.opacity(0.5),
                                        action: {
                                            dismiss()
                                        }
                                    )
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            .frame(height: 200)
                            
                            // Contenu
                            VStack(alignment: .leading, spacing: 20) {
                                // Badge type et titre
                                VStack(alignment: .leading, spacing: 12) {
                                    BadgeView(
                                        text: offer.offerType.rawValue,
                                        gradientColors: offer.offerType == .event ? [Color.appRed, Color.appDarkRed] : [Color.appGold, Color.appGold.opacity(0.8)]
                                    )
                                    
                                    Text(offer.title)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(offer.businessName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(offer.description)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(6)
                                }
                                .padding(.horizontal, 20)
                                
                                // Informations
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.appGold)
                                            .font(.system(size: 16))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Valable jusqu'au")
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(.gray)
                                            
                                            Text(offer.validUntil)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    if offer.isClub10 {
                                        HStack(spacing: 12) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.appGold)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Membre CLUB10")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.gray)
                                                
                                                Text("Réduction de 10%")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    if !offer.discount.isEmpty {
                                        HStack(spacing: 12) {
                                            Image(systemName: "tag.fill")
                                                .foregroundColor(.appGold)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Réduction")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.gray)
                                                
                                                Text(offer.discount)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                
                                // Bouton voir le partenaire
                                if let partnerId = offer.partnerId,
                                   let partner = MockDataService.shared.getPartnerById(id: partnerId) {
                                    Button(action: {
                                        selectedPartner = partner
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 18))
                                            
                                            Text("Voir le partenaire")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.appGold)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                    }
                }
                
                // Footer Bar
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
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

#Preview {
    NavigationStack {
        OfferDetailView(offer: Offer(
            title: "-50% sur l'abonnement",
            description: "Profitez de 50% de réduction sur votre premier mois d'abonnement ! Accès illimité à la salle, cours collectifs inclus.",
            businessName: "Fit & Forme Studio",
            validUntil: "22/01/2026",
            discount: "-50%",
            imageName: "figure.strengthtraining.traditional",
            offerType: .offer,
            isClub10: true
        ))
        .environmentObject(AppState())
    }
}

