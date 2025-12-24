//
//  HomeViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var professionals: [Professional] = []
    @Published var offers: [Offer] = []
    @Published var partners: [Partner] = []
    @Published var filteredProfessionals: [Professional] = []
    @Published var filteredPartners: [Partner] = []
    
    // Search fields
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    @Published var searchRadius: Double = 15.0 // Rayon en km (0 = désactivé)
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
    
    // Filters
    @Published var selectedCategory: String = "Toutes"
    @Published var selectedCity: String = "Toutes"
    @Published var showCategoryFilter: Bool = false
    @Published var showCityFilter: Bool = false
    
    let categories: [String]
    let cities: [String]
    
    private let dataService: MockDataService
    
    init(dataService: MockDataService = MockDataService.shared) {
        self.dataService = dataService
        self.categories = dataService.getCategories()
        self.cities = dataService.getCities()
        loadData()
    }
    
    func loadData() {
        professionals = dataService.getProfessionals()
        offers = dataService.getOffers()
        partners = dataService.getPartners()
        applyFilters()
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        if let index = partners.firstIndex(where: { $0.id == partner.id }) {
            partners[index].isFavorite.toggle()
            // Mettre à jour aussi dans la liste filtrée
            if let filteredIndex = filteredPartners.firstIndex(where: { $0.id == partner.id }) {
                filteredPartners[filteredIndex].isFavorite = partners[index].isFavorite
            }
        }
    }
    
    func toggleFavorite(for professional: Professional) {
        if let index = professionals.firstIndex(where: { $0.id == professional.id }) {
            professionals[index].isFavorite.toggle()
            applyFilters()
        }
    }
    
    func searchProfessionals() {
        applyFilters()
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        showCategoryFilter = false
        applyFilters()
    }
    
    func selectCity(_ city: String) {
        selectedCity = city
        showCityFilter = false
        applyFilters()
    }
    
    func getPartner(for offer: Offer) -> Partner? {
        guard let partnerId = offer.partnerId else { return nil }
        return partners.first { $0.id == partnerId }
    }
    
    private func applyFilters() {
        // Filtrer les professionnels
        var filtered = professionals
        
        // Filtre par ville
        if !cityText.isEmpty {
            filtered = filtered.filter { professional in
                professional.city.localizedCaseInsensitiveContains(cityText) ||
                professional.address.localizedCaseInsensitiveContains(cityText)
            }
        }
        
        // Filtre par secteur
        if !selectedSector.isEmpty {
            filtered = filtered.filter { professional in
                professional.category.localizedCaseInsensitiveContains(selectedSector)
            }
        }
        
        // Filtre par catégorie
        if selectedCategory != "Toutes" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filtre par ville (dropdown)
        if selectedCity != "Toutes" {
            filtered = filtered.filter { $0.city == selectedCity }
        }
        
        // Filtre CLUB10
        if onlyClub10 {
            // Pour l'instant, on garde tous les professionnels
            // À implémenter avec un champ isClub10 dans Professional
        }
        
        filteredProfessionals = filtered
        
        // Filtrer les partenaires
        var filteredPartnersList = partners
        
        // Filtre par texte (ville, nom, activité)
        if !cityText.isEmpty {
            filteredPartnersList = filteredPartnersList.filter { partner in
                partner.name.localizedCaseInsensitiveContains(cityText) ||
                partner.city.localizedCaseInsensitiveContains(cityText) ||
                partner.address.localizedCaseInsensitiveContains(cityText) ||
                partner.category.localizedCaseInsensitiveContains(cityText) ||
                (partner.description?.localizedCaseInsensitiveContains(cityText) ?? false)
            }
        }
        
        // Filtre par secteur avec mapping intelligent
        if !selectedSector.isEmpty {
            filteredPartnersList = filteredPartnersList.filter { partner in
                matchesSector(partnerCategory: partner.category, selectedSector: selectedSector)
            }
        }
        
        // Filtre CLUB10
        if onlyClub10 {
            filteredPartnersList = filteredPartnersList.filter { partner in
                partner.discount != nil && partner.discount == 10
            }
        }
        
        filteredPartners = filteredPartnersList
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
