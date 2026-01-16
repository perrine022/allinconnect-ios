//
//  PartnerCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct PartnerCard: View {
    let partner: Partner
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Image de l'établissement ou icône par défaut
                Group {
                    // L'URL est déjà construite dans le mapping, on l'utilise directement
                    if let imageUrl = partner.establishmentImageUrl, !imageUrl.isEmpty,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .frame(width: 70, height: 70)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: partner.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.3))
                                    .task {
                                        print("🖼️ [PartnerCard] Failed to load image for \(partner.name):")
                                        print("   URL: \(imageUrl)")
                                    }
                            @unknown default:
                                Image(systemName: partner.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                    } else {
                        // Pas d'URL d'image disponible
                        Image(systemName: partner.imageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.3))
                            .task {
                                if partner.establishmentImageUrl == nil || partner.establishmentImageUrl!.isEmpty {
                                    print("🖼️ [PartnerCard] No image URL for partner: \(partner.name)")
                                } else {
                                    print("🖼️ [PartnerCard] Invalid URL for partner \(partner.name): \(partner.establishmentImageUrl ?? "nil")")
                                }
                            }
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Nom
                    Text(partner.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    // Catégorie et sous-catégorie
                    VStack(alignment: .leading, spacing: 2) {
                        Text(partner.category)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                        
                        // Afficher la sous-catégorie si disponible
                        if let subCategory = partner.subCategory, !subCategory.isEmpty {
                            Text(subCategory)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    
                    // Localisation avec distance si disponible
                    HStack(spacing: 4) {
                        Text("\(partner.city)\(partner.postalCode.isEmpty ? "" : " (\(partner.postalCode))")")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                        
                        // Distance si disponible
                        if let distance = partner.distanceMeters,
                           let formattedDistance = DistanceFormatter.formatDistanceShort(distance) {
                            Text("• \(formattedDistance)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    
                    // Note
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        
                        Text(String(format: "%.1f", partner.rating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("(\(partner.reviewCount) avis)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    // Badge de réduction
                    if let discount = partner.discount {
                        Text("-\(discount)%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                    
                    // Bouton favori
                    Button(action: onFavoriteToggle) {
                        Image(systemName: partner.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(partner.isFavorite ? .red : .gray)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appDarkRed1.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        PartnerCard(
            partner: Partner(
                name: "Fit & Forme Studio",
                category: "Sport & Santé",
                address: "28 Avenue Victor Hugo",
                city: "Lyon",
                postalCode: "69001",
                rating: 4.7,
                reviewCount: 48,
                discount: 10,
                imageName: "figure.strengthtraining.traditional",
                headerImageName: "figure.strengthtraining.traditional",
                isFavorite: true
            ),
            onFavoriteToggle: {},
            onTap: {}
        )
        .padding()
    }
}

