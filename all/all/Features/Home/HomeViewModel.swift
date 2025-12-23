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
    
    // Search fields
    @Published var cityText: String = ""
    @Published var activityText: String = ""
    @Published var searchRadiusEnabled: Bool = false
    @Published var onlyClub10: Bool = false
    
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
        var filtered = professionals
        
        // Filtre par ville
        if !cityText.isEmpty {
            filtered = filtered.filter { professional in
                professional.city.localizedCaseInsensitiveContains(cityText) ||
                professional.address.localizedCaseInsensitiveContains(cityText)
            }
        }
        
        // Filtre par activité
        if !activityText.isEmpty {
            filtered = filtered.filter { professional in
                professional.profession.localizedCaseInsensitiveContains(activityText) ||
                professional.category.localizedCaseInsensitiveContains(activityText)
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
    }
}
