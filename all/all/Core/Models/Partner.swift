//
//  Partner.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct Partner: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let subCategory: String? // Sous-catégorie (ex: "Coiffure")
    let address: String
    let city: String
    let postalCode: String
    let phone: String?
    let email: String?
    let website: String?
    let instagram: String?
    let description: String?
    let rating: Double
    let reviewCount: Int
    let discount: Int?
    let imageName: String
    let headerImageName: String
    let establishmentImageUrl: String? // URL absolue de l'image de l'établissement (depuis le backend)
    var isFavorite: Bool
    let apiId: Int? // ID original de l'API pour pouvoir gérer les favoris
    let distanceMeters: Double? // Distance en mètres depuis la position de l'utilisateur (si recherche géolocalisée)
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        subCategory: String? = nil,
        address: String,
        city: String,
        postalCode: String,
        phone: String? = nil,
        email: String? = nil,
        website: String? = nil,
        instagram: String? = nil,
        description: String? = nil,
        rating: Double,
        reviewCount: Int,
        discount: Int? = nil,
        imageName: String,
        headerImageName: String,
        establishmentImageUrl: String? = nil,
        isFavorite: Bool = false,
        apiId: Int? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subCategory = subCategory
        self.address = address
        self.city = city
        self.postalCode = postalCode
        self.phone = phone
        self.email = email
        self.website = website
        self.instagram = instagram
        self.description = description
        self.rating = rating
        self.reviewCount = reviewCount
        self.discount = discount
        self.imageName = imageName
        self.headerImageName = headerImageName
        self.establishmentImageUrl = establishmentImageUrl
        self.isFavorite = isFavorite
        self.apiId = apiId
        self.distanceMeters = distanceMeters
    }
}

