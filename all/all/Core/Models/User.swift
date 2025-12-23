//
//  User.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

struct User: Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let username: String
    let bio: String
    let profileImageName: String
    let publications: Int
    let subscribers: Int
    let subscriptions: Int
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        username: String,
        bio: String,
        profileImageName: String,
        publications: Int = 0,
        subscribers: Int = 0,
        subscriptions: Int = 0
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.bio = bio
        self.profileImageName = profileImageName
        self.publications = publications
        self.subscribers = subscribers
        self.subscriptions = subscriptions
    }
}

