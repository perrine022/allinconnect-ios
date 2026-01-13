//
//  ProfileMenuRow.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var showBadge: Bool = false // Pastille rouge de notification
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    // Pastille rouge de notification
                    if showBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -2)
                    }
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ProfileMenuRow(
            icon: "person.fill",
            title: "Modifier mon profil",
            action: {}
        )
        .background(Color.appDarkRed1.opacity(0.8))
        .cornerRadius(12)
        .padding()
    }
}

