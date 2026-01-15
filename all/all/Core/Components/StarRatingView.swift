//
//  StarRatingView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct StarRatingView: View {
    let rating: Double
    let starSize: CGFloat
    
    init(rating: Double, starSize: CGFloat = 16) {
        self.rating = rating
        self.starSize = starSize
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: starName(for: index))
                    .font(.system(size: starSize))
                    .foregroundColor(starColor(for: index))
            }
        }
    }
    
    private func starName(for index: Int) -> String {
        let filledStars = Int(rating)
        let hasHalfStar = rating - Double(filledStars) >= 0.5
        
        if index < filledStars {
            return "star.fill"
        } else if index == filledStars && hasHalfStar {
            return "star.lefthalf.fill"
        } else {
            return "star"
        }
    }
    
    private func starColor(for index: Int) -> Color {
        let filledStars = Int(rating)
        let hasHalfStar = rating - Double(filledStars) >= 0.5
        
        if index < filledStars || (index == filledStars && hasHalfStar) {
            return .appGold
        } else {
            return .gray.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 5.0)
        StarRatingView(rating: 4.5)
        StarRatingView(rating: 3.0)
        StarRatingView(rating: 2.5)
        StarRatingView(rating: 1.0)
    }
    .padding()
    .background(Color.black)
}

















