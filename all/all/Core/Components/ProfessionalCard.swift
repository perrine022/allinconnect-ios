//
//  ProfessionalCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfessionalCard: View {
    let professional: Professional
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Photo de l'établissement ou icône par défaut
                Group {
                    if let imageUrl = ImageURLHelper.buildImageURL(from: professional.establishmentImageUrl),
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Image(systemName: professional.profileImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.6))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: professional.profileImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.6))
                            @unknown default:
                                Image(systemName: professional.profileImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                    } else {
                        // Fallback : icône par défaut
                        Image(systemName: professional.profileImageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    // Nom complet
                    Text(professional.fullName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Profession
                    Text(professional.profession)
                        .font(.system(size: 14))
                        .foregroundColor(.appCoral)
                    
                    // Localisation
                    Button(action: {
                        let address = "\(professional.address), \(professional.postalCode) \(professional.city)"
                        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        
                        // Essayer d'abord Apple Maps
                        if let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
                            UIApplication.shared.open(appleMapsURL) { success in
                                // Si Apple Maps échoue, essayer Google Maps
                                if !success {
                                    if let googleMapsURL = URL(string: "comgooglemaps://?q=\(encodedAddress)") {
                                        if UIApplication.shared.canOpenURL(googleMapsURL) {
                                            UIApplication.shared.open(googleMapsURL)
                                        } else {
                                            // Fallback vers Google Maps web
                                            if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedAddress)") {
                                                UIApplication.shared.open(webURL)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                                .font(.system(size: 11))
                            Text("\(professional.address), \(professional.city)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Bouton favori
                Button(action: onFavoriteToggle) {
                    Image(systemName: professional.isFavorite ? "star.fill" : "star")
                        .foregroundColor(professional.isFavorite ? .yellow : .white.opacity(0.6))
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appDarkGray.opacity(0.4))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ProfessionalCard(
            professional: Professional(
                firstName: "Marc",
                lastName: "Dubois",
                profession: "Coiffeur Expert",
                category: "Beauté",
                address: "15 Rue de la République",
                city: "Paris",
                postalCode: "75001",
                profileImageName: "person.circle.fill"
            ),
            onFavoriteToggle: {},
            onTap: {}
        )
        .padding()
    }
}

