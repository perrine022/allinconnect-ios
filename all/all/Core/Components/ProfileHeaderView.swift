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
    let height: CGFloat
    
    init(
        firstName: String,
        lastName: String,
        profession: String,
        category: String,
        profileImageName: String,
        height: CGFloat = 280
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.profession = profession
        self.category = category
        self.profileImageName = profileImageName
        self.height = height
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient rouge en haut
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appRed.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Photo de profil avec bordure rouge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.appRed.opacity(0.8),
                                    Color.appDarkRed.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: profileImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .foregroundColor(.white.opacity(0.9))
                }
                .shadow(color: Color.appRed.opacity(0.5), radius: 20, x: 0, y: 10)
                .padding(.bottom, 20)
            }
        }
        .frame(height: height)
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


