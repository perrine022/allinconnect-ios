//
//  ReviewCard.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        HStack {
            // Nom
            Text(review.userName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Étoiles
            StarRatingView(rating: review.rating, starSize: 14)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed2.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appRed.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ReviewCard(
            review: Review(
                userName: "Marie D.",
                rating: 4.5,
                comment: "Excellent établissement ! Service au top et ambiance agréable. Je recommande vivement.",
                date: Date()
            )
        )
        .padding()
    }
}

