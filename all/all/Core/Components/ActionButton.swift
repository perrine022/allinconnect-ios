//
//  ActionButton.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        gradientColors: [Color],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradientColors = gradientColors
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: gradientColors[0].opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            ActionButton(
                title: "VISITER LE SITE WEB",
                icon: "globe",
                gradientColors: [Color.appRed, Color.appDarkRed],
                action: {}
            )
            
            ActionButton(
                title: "SUIVRE SUR INSTAGRAM",
                icon: "camera.fill",
                gradientColors: [Color(red: 0.8, green: 0.2, blue: 0.5), Color(red: 0.6, green: 0.1, blue: 0.3)],
                action: {}
            )
        }
        .padding()
    }
}


