//
//  ProCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProCard: View {
    var onLearnMore: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pourquoi adhérer ?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Rejoins la communauté des pros")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                
                Button(action: onLearnMore) {
                    Text("En savoir plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Photo Pro (high-five)
            Image("ProHighFiveImage")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(20)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ProCard()
            .padding()
    }
}


