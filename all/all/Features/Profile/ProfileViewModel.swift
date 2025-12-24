//
//  ProfileViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

enum ProfileSpace {
    case client
    case pro
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var favoritePartners: [Partner] = []
    @Published var currentSpace: ProfileSpace = .client
    
    // Données abonnement PRO
    @Published var nextPaymentDate: String = "15/02/2026"
    @Published var commitmentUntil: String = "15/02/2027"
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        
        // Pour l'instant, on simule un utilisateur PRO
        // Plus tard, on récupérera depuis UserDefaults ou l'API
        let userType = UserDefaults.standard.string(forKey: "user_type") == "PRO" ? UserType.pro : UserType.client
        
        self.user = User(
            firstName: "Marie",
            lastName: "Dupont",
            username: "marie2024",
            bio: "Membre CLUB10",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0,
            userType: userType
        )
        
        // Si PRO, commencer en espace PRO
        if user.userType == .pro {
            currentSpace = .pro
        }
        
        loadFavorites()
    }
    
    func loadFavorites() {
        favoritePartners = dataService.getPartners().filter { $0.isFavorite }
    }
    
    func switchToClientSpace() {
        currentSpace = .client
    }
    
    func switchToProSpace() {
        currentSpace = .pro
    }
}

