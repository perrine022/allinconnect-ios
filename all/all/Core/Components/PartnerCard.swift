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
                    // Reconstruire l'URL pour s'assurer qu'elle est correcte
                    // (gère les cas où l'URL pourrait être relative ou absolue)
                    if let builtImageUrl = ImageURLHelper.buildImageURL(from: partner.establishmentImageUrl),
                       !builtImageUrl.isEmpty,
                       let url = URL(string: builtImageUrl) {
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
                                        print("   Raw URL: \(partner.establishmentImageUrl ?? "nil")")
                                        print("   Built URL: \(builtImageUrl)")
                                    }
                            @unknown default:
                                Image(systemName: partner.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                    } else {
                        // Pas d'URL d'image disponible ou URL invalide
                        Image(systemName: partner.imageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.3))
                            .task {
                                if partner.establishmentImageUrl == nil || partner.establishmentImageUrl!.isEmpty {
                                    print("🖼️ [PartnerCard] No image URL for partner: \(partner.name)")
                                } else {
                                    print("🖼️ [PartnerCard] Invalid URL for partner \(partner.name):")
                                    print("   Raw URL: \(partner.establishmentImageUrl ?? "nil")")
                                    if let builtUrl = ImageURLHelper.buildImageURL(from: partner.establishmentImageUrl) {
                                        print("   Built URL: \(builtUrl)")
                                    }
                                }
                            }
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Nom avec note à droite
                    HStack(alignment: .center, spacing: 8) {
                        Text(partner.name.capitalized)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Note à droite du titre (afficher si rating > 0)
                        if partner.rating > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                                
                                Text(String(format: "%.1f", partner.rating))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.black)
                                
                                // Afficher le nombre d'avis seulement si disponible et > 0
                                if partner.reviewCount > 0 {
                                    Text("(\(partner.reviewCount))")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
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
                        Text("\(partner.city.capitalized)\(partner.postalCode.isEmpty ? "" : " (\(partner.postalCode))")")
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

