//
//  ProfileHeaderView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfileHeaderView: View {
    let firstName: String
    let lastName: String
    let profession: String
    let category: String
    let profileImageName: String
    let establishmentImageUrl: String?
    let height: CGFloat
    
    init(
        firstName: String,
        lastName: String,
        profession: String,
        category: String,
        profileImageName: String,
        establishmentImageUrl: String? = nil,
        height: CGFloat = 280
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.profession = profession
        self.category = category
        self.profileImageName = profileImageName
        self.establishmentImageUrl = establishmentImageUrl
        self.height = height
    }
    
    @State private var showImageZoom = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer()
                
                // Photo de profil sans filtre rouge
                Button(action: {
                    showImageZoom = true
                }) {
                    ZStack {
                        // Afficher l'image de l'établissement si disponible, sinon l'icône par défaut
                        Group {
                            if let imageUrl = ImageURLHelper.buildImageURL(from: establishmentImageUrl),
                               let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Image(systemName: profileImageName)
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundColor(.white.opacity(0.9))
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: profileImageName)
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundColor(.white.opacity(0.9))
                                    @unknown default:
                                        Image(systemName: profileImageName)
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            } else {
                                // Fallback : icône par défaut
                                Image(systemName: profileImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                    }
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: height)
        .sheet(isPresented: $showImageZoom) {
            ImageZoomView(
                imageUrl: establishmentImageUrl,
                profileImageName: profileImageName
            )
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ProfileHeaderView(
            firstName: "Marc",
            lastName: "Dubois",
            profession: "Coiffeur Expert",
            category: "Beauté",
            profileImageName: "person.circle.fill"
        )
    }
}



