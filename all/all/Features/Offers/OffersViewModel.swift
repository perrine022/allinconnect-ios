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
    @Published var selectedSector: String = ""
    @Published var searchRadius: Double = 10.0 // Rayon en km (0 = désactivé)
    @Published var onlyClub10: Bool = false
    
    // Secteurs disponibles
    let sectors: [String] = [
        "",
        "Santé & bien être",
        "Beauté & Esthétique",
        "Food & plaisirs gourmands",
        "Loisirs & Divertissements",
        "Service & pratiques",
        "Entre pros"
    ]
    
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
        
        // Filtre par secteur
        if !selectedSector.isEmpty {
            filtered = filtered.filter { offer in
                // Vérifier via le partenaire
                if let partnerId = offer.partnerId,
                   let partner = dataService.getPartnerById(id: partnerId) {
                    return partner.category.localizedCaseInsensitiveContains(selectedSector)
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

