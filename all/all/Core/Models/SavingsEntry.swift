//
//  SavingsEntry.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct SavingsEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let apiId: Int? // ID depuis l'API backend
    let amount: Double
    let date: Date
    let store: String
    let description: String?
    
    init(
        id: UUID = UUID(),
        apiId: Int? = nil,
        amount: Double,
        date: Date = Date(),
        store: String,
        description: String? = nil
    ) {
        self.id = id
        self.apiId = apiId
        self.amount = amount
        self.date = date
        self.store = store
        self.description = description
    }
}

