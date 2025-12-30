//
//  OfferImage.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

/// Composant réutilisable pour afficher l'image d'une offre
/// Affiche l'image depuis l'URL si disponible, sinon l'icône par défaut
struct OfferImage: View {
    let offer: Offer
    let contentMode: ContentMode
    
    init(offer: Offer, contentMode: ContentMode = .fill) {
        self.offer = offer
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let imageUrl = offer.fullImageUrl(), let url = URL(string: imageUrl) {
                // Afficher l'image depuis l'URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Pendant le chargement, afficher l'icône par défaut
                        Image(systemName: offer.imageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        // En cas d'erreur, afficher l'icône par défaut
                        Image(systemName: offer.imageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.3))
                    @unknown default:
                        Image(systemName: offer.imageName)
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
            } else {
                // Pas d'URL d'image, afficher l'icône par défaut
                Image(systemName: offer.imageName)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.gray.opacity(0.3))
            }
        }
    }
}

