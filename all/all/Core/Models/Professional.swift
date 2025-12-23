//
//  Professional.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct Professional: Identifiable, Codable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let profession: String
    let category: String
    let address: String
    let city: String
    let postalCode: String
    let phone: String?
    let email: String?
    let profileImageName: String
    let websiteURL: String?
    let instagramURL: String?
    let description: String?
    var isFavorite: Bool
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        profession: String,
        category: String,
        address: String,
        city: String,
        postalCode: String,
        phone: String? = nil,
        email: String? = nil,
        profileImageName: String,
        websiteURL: String? = nil,
        instagramURL: String? = nil,
        description: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.profession = profession
        self.category = category
        self.address = address
        self.city = city
        self.postalCode = postalCode
        self.phone = phone
        self.email = email
        self.profileImageName = profileImageName
        self.websiteURL = websiteURL
        self.instagramURL = instagramURL
        self.description = description
        self.isFavorite = isFavorite
    }
}

