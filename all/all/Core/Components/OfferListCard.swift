//
//  OfferListCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OfferListCard: View {
    let offer: Offer
    let onTap: () -> Void
    
    var badgeColor: Color {
        switch offer.offerType {
        case .event:
            return .red
        case .offer:
            return .appGold
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image avec badge
                ZStack(alignment: .topLeading) {
                    Image(systemName: offer.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .foregroundColor(.gray.opacity(0.3))
                    
                    // Badge type
                    Text(offer.offerType.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badgeColor)
                        .cornerRadius(8)
                        .padding(12)
                }
                
                // Contenu
                VStack(alignment: .leading, spacing: 8) {
                    // Titre
                    Text(offer.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    // Nom du studio et badge réduction
                    HStack(spacing: 8) {
                        Text(offer.businessName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.appRed)
                        
                        if offer.isClub10 {
                            Text("-10%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    }
                    
                    // Description
                    Text(offer.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    // Date et bouton
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                            
                            Text("Jusqu'au \(offer.validUntil)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: onTap) {
                            Text("Je profite")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.appGold)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        OfferListCard(
            offer: Offer(
                title: "-50% sur l'abonnement",
                description: "Profitez de 50% de réduction sur votre premier mois d'abonnement ! Accès illimité à la salle, cours collectifs inclus.",
                businessName: "Fit & Forme Studio",
                validUntil: "22/01/2026",
                discount: "-50%",
                imageName: "figure.strengthtraining.traditional",
                offerType: .offer,
                isClub10: true
            ),
            onTap: {}
        )
        .padding()
    }
}

