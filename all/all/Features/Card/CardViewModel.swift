//
//  CardViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class CardViewModel: ObservableObject {
    @Published var user: User
    @Published var savings: Double = 128.0
    @Published var referrals: Int = 2
    @Published var wallet: Double = 15.0
    @Published var favoritesCount: Int = 2
    @Published var favoritePartners: [Partner] = []
    @Published var referralCode: String = "MARIE2024"
    @Published var referralLink: String = "allin.fr/r/MARIE2024"
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
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
        loadData()
    }
    
    func loadData() {
        // Charger les partenaires favoris
        favoritePartners = dataService.getPartners().filter { $0.isFavorite }
        favoritesCount = favoritePartners.count
    }
    
    func copyReferralLink() {
        UIPasteboard.general.string = referralLink
    }
}

