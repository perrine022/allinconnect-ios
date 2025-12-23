//
//  ProfileViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    
    init() {
        self.user = User(
            firstName: "Marie",
            lastName: "Dupont",
            username: "marie2024",
            bio: "Membre CLUB10",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0
        )
    }
}

