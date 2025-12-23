//
//  OffersViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

enum OfferFilterType: String, CaseIterable {
    case all = "Tous"
    case offer = "Offres"
    case event = "Événements"
}

@MainActor
class OffersViewModel: ObservableObject {
    @Published var allOffers: [Offer] = []
    @Published var filteredOffers: [Offer] = []
    @Published var selectedFilter: OfferFilterType = .all
    @Published var selectedSector: String = "Tous les secteurs"
    @Published var showSectorFilter: Bool = false
    
    let sectors: [String]
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        self.sectors = ["Tous les secteurs", "Sport & Santé", "Esthétique", "Food", "Divertissement"]
        loadOffers()
    }
    
    func loadOffers() {
        allOffers = dataService.getAllOffers()
        applyFilters()
    }
    
    func selectFilter(_ filter: OfferFilterType) {
        selectedFilter = filter
        applyFilters()
    }
    
    func selectSector(_ sector: String) {
        selectedSector = sector
        showSectorFilter = false
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = allOffers
        
        // Filtre par type
        switch selectedFilter {
        case .all:
            break // Pas de filtre
        case .offer:
            filtered = filtered.filter { $0.offerType == .offer }
        case .event:
            filtered = filtered.filter { $0.offerType == .event }
        }
        
        // Filtre par secteur (si implémenté avec catégorie du partenaire)
        if selectedSector != "Tous les secteurs" {
            // À implémenter avec la catégorie du partenaire
        }
        
        filteredOffers = filtered
    }
    
    func getPartner(for offer: Offer) -> Partner? {
        guard let partnerId = offer.partnerId else { return nil }
        return dataService.getPartners().first { $0.id == partnerId }
    }
}

