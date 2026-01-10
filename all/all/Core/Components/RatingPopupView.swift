//
//  RatingPopupView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct RatingPopupView: View {
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 0
    let partnerName: String
    let onRatingSubmit: (Int) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 24) {
                Text("Noter \(partnerName)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: {
                            selectedRating = index
                        }) {
                            Image(systemName: index <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundColor(index <= selectedRating ? .appGold : .gray.opacity(0.3))
                        }
                    }
                }
                .padding(.vertical, 8)
                
                HStack(spacing: 16) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if selectedRating > 0 {
                            onRatingSubmit(selectedRating)
                            isPresented = false
                        }
                    }) {
                        Text("Valider")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedRating > 0 ? Color.appGold : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .disabled(selectedRating == 0)
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.appDarkRed2,
                        Color.appDarkRed1,
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    RatingPopupView(
        isPresented: .constant(true),
        partnerName: "GameZone VR",
        onRatingSubmit: { rating in
            print("Rating: \(rating)")
        }
    )
}













