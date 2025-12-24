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
    
    // Offres PRO
    @Published var myOffers: [Offer] = []
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        
        // Pour l'instant, on simule un utilisateur PRO
        // Plus tard, on récupérera depuis UserDefaults ou l'API
        // Par défaut, on met PRO pour voir les boutons (à changer plus tard)
        let userType = UserDefaults.standard.string(forKey: "user_type") == "PRO" ? UserType.pro : UserType.pro
        
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
        loadMyOffers()
    }
    
    func loadFavorites() {
        favoritePartners = dataService.getPartners().filter { $0.isFavorite }
    }
    
    func loadMyOffers() {
        // Pour l'instant, on récupère toutes les offres
        // Plus tard, on filtrera par l'ID du partenaire connecté
        myOffers = dataService.getAllOffers()
    }
    
    func switchToClientSpace() {
        currentSpace = .client
    }
    
    func switchToProSpace() {
        currentSpace = .pro
    }
    
    func reset() {
        // Réinitialiser l'état lors de la déconnexion
        favoritePartners = []
        myOffers = []
        currentSpace = .client
        
        // Réinitialiser l'utilisateur avec des valeurs par défaut
        let userType = UserDefaults.standard.string(forKey: "user_type") == "PRO" ? UserType.pro : UserType.client
        
        self.user = User(
            firstName: "",
            lastName: "",
            username: "",
            bio: "",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0,
            userType: userType
        )
    }
}

