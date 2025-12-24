//
//  PartnersListViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class PartnersListViewModel: ObservableObject {
    @Published var allPartners: [Partner] = []
    @Published var filteredPartners: [Partner] = []
    
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
        loadPartners()
    }
    
    func loadPartners() {
        allPartners = dataService.getPartners()
        applyFilters()
    }
    
    func searchPartners() {
        applyFilters()
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        dataService.togglePartnerFavorite(partnerId: partner.id)
        // Mettre à jour dans la liste
        if let index = allPartners.firstIndex(where: { $0.id == partner.id }) {
            allPartners[index].isFavorite.toggle()
            // Mettre à jour aussi dans la liste filtrée
            if let filteredIndex = filteredPartners.firstIndex(where: { $0.id == partner.id }) {
                filteredPartners[filteredIndex].isFavorite = allPartners[index].isFavorite
            }
        }
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = allPartners
        
        // Filtre par texte (ville, nom, activité)
        if !cityText.isEmpty {
            filtered = filtered.filter { partner in
                partner.name.localizedCaseInsensitiveContains(cityText) ||
                partner.city.localizedCaseInsensitiveContains(cityText) ||
                partner.address.localizedCaseInsensitiveContains(cityText) ||
                partner.category.localizedCaseInsensitiveContains(cityText) ||
                (partner.description?.localizedCaseInsensitiveContains(cityText) ?? false)
            }
        }
        
        // Filtre par secteur avec mapping intelligent
        if !selectedSector.isEmpty {
            filtered = filtered.filter { partner in
                matchesSector(partnerCategory: partner.category, selectedSector: selectedSector)
            }
        }
        
        // Filtre CLUB10
        if onlyClub10 {
            filtered = filtered.filter { partner in
                partner.discount != nil && partner.discount == 10
            }
        }
        
        filteredPartners = filtered
    }
    
    // Fonction pour mapper les secteurs aux catégories des partenaires
    private func matchesSector(partnerCategory: String, selectedSector: String) -> Bool {
        let partnerCat = partnerCategory.lowercased()
        let sector = selectedSector.lowercased()
        
        // Mapping des secteurs aux catégories
        switch sector {
        case "santé & bien être", "sante & bien etre":
            return partnerCat.contains("santé") || partnerCat.contains("sante") || partnerCat.contains("sport")
        case "beauté & esthétique", "beaute & esthetique":
            return partnerCat.contains("beauté") || partnerCat.contains("beaute") || partnerCat.contains("esthétique") || partnerCat.contains("esthetique") || partnerCat.contains("spa")
        case "food & plaisirs gourmands":
            return partnerCat.contains("food") || partnerCat.contains("restaurant") || partnerCat.contains("gourmand")
        case "loisirs & divertissements":
            return partnerCat.contains("divertissement") || partnerCat.contains("loisir") || partnerCat.contains("jeu") || partnerCat.contains("vr")
        case "service & pratiques":
            return partnerCat.contains("service") || partnerCat.contains("pratique")
        case "entre pros":
            return partnerCat.contains("pro") || partnerCat.contains("professionnel")
        default:
            return partnerCategory.localizedCaseInsensitiveContains(selectedSector)
        }
    }
}

