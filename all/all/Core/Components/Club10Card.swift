//
//  Club10Card.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct Club10Card: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pourquoi ta carte digitale ?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Des bénéfices qui changent tout")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                
                Button(action: {}) {
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
            
            // QR Code pattern
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.3))
                    .frame(width: 80, height: 80)
                
                // Pattern similaire à un QR code
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.black).frame(width: 8, height: 8)
                        Rectangle().fill(Color.white).frame(width: 8, height: 8)
                        Rectangle().fill(Color.black).frame(width: 8, height: 8)
                    }
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.white).frame(width: 8, height: 8)
                        Rectangle().fill(Color.black).frame(width: 8, height: 8)
                        Rectangle().fill(Color.white).frame(width: 8, height: 8)
                    }
                    HStack(spacing: 2) {
                        Rectangle().fill(Color.black).frame(width: 8, height: 8)
                        Rectangle().fill(Color.white).frame(width: 8, height: 8)
                        Rectangle().fill(Color.black).frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .cornerRadius(16)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        Club10Card()
            .padding()
    }
}

