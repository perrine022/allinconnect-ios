//
//  OffersViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class OffersViewModel: ObservableObject {
    @Published var allOffers: [Offer] = []
    @Published var filteredOffers: [Offer] = []
    
    // Search fields (comme HomeView)
    @Published var cityText: String = ""
    @Published var activityText: String = ""
    @Published var searchRadius: Double = 10.0 // Rayon en km (0 = désactivé)
    @Published var onlyClub10: Bool = false
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        loadOffers()
    }
    
    func loadOffers() {
        allOffers = dataService.getAllOffers()
        applyFilters()
    }
    
    func searchOffers() {
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = allOffers
        
        // Filtre par ville/nom/activité
        if !cityText.isEmpty {
            filtered = filtered.filter { offer in
                offer.businessName.localizedCaseInsensitiveContains(cityText) ||
                offer.title.localizedCaseInsensitiveContains(cityText) ||
                offer.description.localizedCaseInsensitiveContains(cityText)
            }
        }
        
        // Filtre par activité/secteur
        if !activityText.isEmpty {
            filtered = filtered.filter { offer in
                // Vérifier via le partenaire
                if let partnerId = offer.partnerId,
                   let partner = dataService.getPartnerById(id: partnerId) {
                    return partner.category.localizedCaseInsensitiveContains(activityText)
                }
                return false
            }
        }
        
        // Filtre CLUB10
        if onlyClub10 {
            filtered = filtered.filter { $0.isClub10 }
        }
        
        filteredOffers = filtered
    }
    
    func getPartner(for offer: Offer) -> Partner? {
        guard let partnerId = offer.partnerId else { return nil }
        return dataService.getPartners().first { $0.id == partnerId }
    }
}

