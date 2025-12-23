//
//  ContactRow.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ContactRow: View {
    let icon: String
    let text: String
    let iconColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        text: String,
        iconColor: Color = .appRed,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.text = text
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack {
            ContactRow(
                icon: "phone.fill",
                text: "+33 1 23 45 67 89",
                action: {}
            )
            
            ContactRow(
                icon: "envelope.fill",
                text: "example@email.com",
                action: {}
            )
        }
        .padding()
    }
}

