//
//  Review.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct Review: Identifiable, Hashable {
    let id: UUID
    let userName: String
    let rating: Double
    let comment: String
    let date: Date
    
    init(
        id: UUID = UUID(),
        userName: String,
        rating: Double,
        comment: String,
        date: Date = Date()
    ) {
        self.id = id
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.date = date
    }
}

















