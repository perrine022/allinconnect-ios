//
//  OfferCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OfferCard: View {
    let offer: Offer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    OfferImage(offer: offer, contentMode: .fill)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Overlay gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Badge CLUB10 en haut à droite
                    if offer.isClub10 {
                        Text("CLUB10")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                            .padding(8)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(offer.discount)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(offer.businessName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Jusqu'au \(offer.validUntil)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.appDarkRed2, // #421515
                            Color.appDarkRed1  // #1D0809
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Button
                Button(action: onTap) {
                    Text("Je profite")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appGold)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.appDarkRed2, // #421515
                            Color.appDarkRed1  // #1D0809
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.appDarkRed2, // #421515
                        Color.appDarkRed1  // #1D0809
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 280)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        OfferCard(
            offer: Offer(
                title: "-50% sur l'abonnement",
                description: "Réduction sur l'abonnement",
                businessName: "Fit & Forme Studio",
                validUntil: "22/01",
                discount: "-50% sur l'abonnement",
                imageName: "figure.strengthtraining.traditional"
            ),
            onTap: {}
        )
    }
}

