//
//  ProOffersViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ProOffersViewModel: ObservableObject {
    @Published var myOffers: [Offer] = []
    @Published var isLoading: Bool = false
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        loadMyOffers()
    }
    
    func loadMyOffers() {
        // Pour l'instant, on récupère toutes les offres
        // Plus tard, on filtrera par l'ID du partenaire connecté
        myOffers = dataService.getAllOffers()
    }
    
    func addOffer(_ offer: Offer) {
        myOffers.append(offer)
        // Plus tard, appeler l'API pour créer l'offre
    }
    
    func deleteOffer(_ offer: Offer) {
        myOffers.removeAll { $0.id == offer.id }
        // Plus tard, appeler l'API pour supprimer
    }
}

