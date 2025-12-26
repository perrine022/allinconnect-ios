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
            HStack(alignment: .top, spacing: 12) {
                // Image à gauche
                ZStack(alignment: .topLeading) {
                    Image(systemName: offer.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.gray.opacity(0.3))
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.appDarkRed1.opacity(0.3), Color.appDarkRed2.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Badge type en haut à gauche
                    Text(offer.offerType.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(badgeColor)
                        .cornerRadius(4)
                        .padding(6)
                }
                
                // Contenu à droite
                VStack(alignment: .leading, spacing: 6) {
                    // Titre et badge
                    HStack(alignment: .top, spacing: 8) {
                        Text(offer.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if offer.isClub10 {
                            Text("CLUB10")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    // Nom du studio
                    Text(offer.businessName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appRed)
                        .lineLimit(1)
                    
                    // Description
                    Text(offer.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .padding(.top, 2)
                    
                    Spacer()
                    
                    // Date et bouton
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.system(size: 10))
                            
                            Text("Jusqu'au \(offer.validUntil)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: onTap) {
                            Text("Je profite")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.appGold)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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

