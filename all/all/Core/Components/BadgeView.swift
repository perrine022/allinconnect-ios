//
//  BadgeView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct BadgeView: View {
    let text: String
    let gradientColors: [Color]
    let fontSize: CGFloat
    
    init(
        text: String,
        gradientColors: [Color] = [Color.red, Color.red],
        fontSize: CGFloat = 11
    ) {
        self.text = text
        self.gradientColors = gradientColors
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
    }
}

#Preview {
    HStack {
        BadgeView(text: "Beauté & Bien-être")
        BadgeView(text: "Premium", gradientColors: [Color.blue, Color.purple])
    }
    .padding()
    .background(Color.appBackground)
}



