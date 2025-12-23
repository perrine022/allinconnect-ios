//
//  NavigationButton.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct NavigationButton: View {
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        iconColor: Color = .white,
        backgroundColor: Color = Color.black.opacity(0.6),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}

struct FavoriteButton: View {
    @Binding var isFavorite: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isFavorite.toggle()
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .appRed : .white)
                    .font(.system(size: 16, weight: .semibold))
                    .scaleEffect(isFavorite ? 1.2 : 1.0)
            }
        }
    }
}

#Preview {
    HStack {
        NavigationButton(icon: "xmark", action: {})
        FavoriteButton(isFavorite: .constant(false), action: {})
        FavoriteButton(isFavorite: .constant(true), action: {})
    }
    .padding()
    .background(Color.appBackground)
}

