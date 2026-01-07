//
//  InfoSection.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.appTextSecondary)
                    .tracking(2)
            }
            .padding(.horizontal, 24)
            
            content
                .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        InfoSection(
            title: "LOCALISATION",
            icon: "mappin.circle.fill",
            iconColor: .appRed
        ) {
            Text("15 Rue de la République")
                .foregroundColor(.white)
        }
    }
}











