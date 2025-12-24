//
//  SavingsEntry.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct SavingsEntry: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let date: Date
    let store: String
    
    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        store: String
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.store = store
    }
}

