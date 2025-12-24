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
    
    // Données abonnement CLUB10 (client)
    @Published var club10NextPaymentDate: String = "15/02/2026"
    @Published var club10CommitmentUntil: String = "15/08/2026"
    @Published var club10Amount: String = "2,99€"
    @Published var hasActiveClub10Subscription: Bool = false
    
    // Abonnement PRO
    @Published var hasActiveProSubscription: Bool = false
    
    // Offres PRO
    @Published var myOffers: [Offer] = []
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        
        // Récupérer les données utilisateur depuis UserDefaults
        let firstName = UserDefaults.standard.string(forKey: "user_first_name") ?? "Marie"
        let lastName = UserDefaults.standard.string(forKey: "user_last_name") ?? "Dupont"
        let email = UserDefaults.standard.string(forKey: "user_email") ?? "marie@email.fr"
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
        let userType = userTypeString == "PRO" ? UserType.pro : UserType.client
        
        self.user = User(
            firstName: firstName,
            lastName: lastName,
            username: email.components(separatedBy: "@").first ?? "user",
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
        
        loadSubscriptionData()
        loadFavorites()
        loadMyOffers()
    }
    
    func loadFavorites() {
        favoritePartners = dataService.getPartners().filter { $0.isFavorite }
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        dataService.togglePartnerFavorite(partnerId: partner.id)
        loadFavorites()
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
    
    func loadSubscriptionData() {
        // Recharger les données d'abonnement depuis UserDefaults
        hasActiveClub10Subscription = false
        hasActiveProSubscription = false
        
        if let hasActiveSubscription = UserDefaults.standard.object(forKey: "has_active_subscription") as? Bool, hasActiveSubscription {
            if let subscriptionType = UserDefaults.standard.string(forKey: "subscription_type") {
                if subscriptionType == "CLUB10" {
                    hasActiveClub10Subscription = true
                    // Charger les dates d'abonnement CLUB10
                    if let nextPaymentDate = UserDefaults.standard.string(forKey: "subscription_next_payment_date") {
                        club10NextPaymentDate = nextPaymentDate
                        // Calculer la date d'engagement (6 mois après la date de paiement)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        if let date = formatter.date(from: nextPaymentDate) {
                            let commitmentDate = Calendar.current.date(byAdding: .month, value: 6, to: date) ?? date
                            club10CommitmentUntil = formatter.string(from: commitmentDate)
                        }
                    }
                } else if subscriptionType == "PRO" {
                    hasActiveProSubscription = true
                    // Charger les dates d'abonnement PRO
                    if let nextPaymentDateString = UserDefaults.standard.string(forKey: "subscription_next_payment_date") {
                        self.nextPaymentDate = nextPaymentDateString
                        // Calculer la date d'engagement (1 an après la date de paiement)
                        let formatter = DateFormatter()
                        formatter.dateFormat = "dd/MM/yyyy"
                        if let date = formatter.date(from: nextPaymentDateString) {
                            let commitmentDate = Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
                            self.commitmentUntil = formatter.string(from: commitmentDate)
                        }
                    }
                }
            }
        }
    }
    
    func reset() {
        // Réinitialiser l'état lors de la déconnexion
        favoritePartners = []
        myOffers = []
        currentSpace = .client
        hasActiveClub10Subscription = false
        hasActiveProSubscription = false
        
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

