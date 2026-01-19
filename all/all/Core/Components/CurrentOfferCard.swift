//
//  CurrentOfferCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CurrentOfferCard: View {
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
            HStack(spacing: 12) {
                // Image
                OfferImage(offer: offer, contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Titre
                    Text(offer.title.capitalized)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Date
                    Text("Jusqu'au \(offer.validUntil)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Badge
                Text(offer.offerType.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badgeColor)
                    .cornerRadius(12)
            }
            .padding(12)
            .background(Color.appDarkRed1.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        CurrentOfferCard(
            offer: Offer(
                title: "Tournoi VR Battle Royale",
                description: "Tournoi",
                businessName: "GameZone VR",
                validUntil: "13/1",
                discount: "",
                imageName: "gamecontroller.fill",
                offerType: .event
            ),
            onTap: {}
        )
        .padding()
    }
}

