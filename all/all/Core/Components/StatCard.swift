//
//  StatCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct StatCard: View {
    let icon: String?
    let value: String
    let label: String
    let iconColor: Color
    let valueColor: Color
    let labelColor: Color
    
    init(
        icon: String? = nil,
        value: String,
        label: String,
        iconColor: Color = .appGold,
        valueColor: Color = .white,
        labelColor: Color = .white
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.iconColor = iconColor
        self.valueColor = valueColor
        self.labelColor = labelColor
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 24))
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(valueColor)
            
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(labelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appDarkRed1.opacity(0.8))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(icon: "banknote.fill", value: "128€", label: "Économies")
                StatCard(icon: "person.2.fill", value: "2", label: "Parrainages")
            }
            
            HStack(spacing: 12) {
                StatCard(icon: "wallet.pass.fill", value: "15€", label: "Cagnotte")
                StatCard(icon: "heart.fill", value: "2", label: "Favoris")
            }
        }
        .padding()
    }
}

