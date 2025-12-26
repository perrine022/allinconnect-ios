//
//  HomeViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import CoreLocation

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
    @Published var hasSearched: Bool = false // Indique si l'utilisateur a cliqué sur Rechercher
    
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
    
    private let partnersAPIService: PartnersAPIService
    private let favoritesAPIService: FavoritesAPIService
    private let offersAPIService: OffersAPIService
    private let profileAPIService: ProfileAPIService
    private let dataService: MockDataService // Gardé pour les catégories, villes et favoris
    private let locationService: LocationService
    
    init(
        partnersAPIService: PartnersAPIService? = nil,
        favoritesAPIService: FavoritesAPIService? = nil,
        offersAPIService: OffersAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil,
        dataService: MockDataService = MockDataService.shared,
        locationService: LocationService? = nil
    ) {
        // Créer les services dans un contexte MainActor
        if let partnersAPIService = partnersAPIService {
            self.partnersAPIService = partnersAPIService
        } else {
            self.partnersAPIService = PartnersAPIService()
        }
        
        if let favoritesAPIService = favoritesAPIService {
            self.favoritesAPIService = favoritesAPIService
        } else {
            self.favoritesAPIService = FavoritesAPIService()
        }
        
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        self.dataService = dataService
        // Accéder à LocationService.shared dans un contexte MainActor
        self.locationService = locationService ?? LocationService.shared
        self.categories = dataService.getCategories()
        self.cities = dataService.getCities()
        loadData()
    }
    
    func loadData() {
        professionals = dataService.getProfessionals()
        loadOffersByCity()
        loadPartners()
        applyFilters()
    }
    
    func loadOffersByCity() {
        Task { @MainActor in
            do {
                // Récupérer la ville de l'utilisateur depuis son profil
                let userProfile = try await profileAPIService.getUserMe()
                
                guard let userCity = userProfile.city, !userCity.isEmpty else {
                    print("[HomeViewModel] Aucune ville trouvée pour l'utilisateur, chargement des offres sans filtre")
                    // Si pas de ville, charger toutes les offres actives (limitées à 5)
                    let allOffers = try await offersAPIService.getAllOffers()
                    offers = Array(allOffers.prefix(5)).map { $0.toOffer() }
                    return
                }
                
                print("[HomeViewModel] Chargement des offres pour la ville: \(userCity)")
                
                // Charger les offres filtrées par ville depuis l'API
                let offersResponse = try await offersAPIService.getAllOffers(city: userCity)
                
                // Limiter à 5 offres maximum
                let limitedOffers = Array(offersResponse.prefix(5))
                
                print("[HomeViewModel] \(limitedOffers.count) offres chargées pour \(userCity)")
                
                // Convertir les réponses API en modèles Offer
                offers = limitedOffers.map { $0.toOffer() }
            } catch {
                print("[HomeViewModel] Erreur lors du chargement des offres par ville: \(error)")
                // En cas d'erreur, utiliser les données mockées en fallback
                offers = Array(dataService.getOffers().prefix(5))
            }
        }
    }
    
    func loadPartners() {
        Task { @MainActor in
            do {
                var professionalsResponse: [PartnerProfessionalResponse]
                
                // Si le rayon de recherche est activé et qu'on a la localisation
                if searchRadius > 0, let location = locationService.currentLocation {
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    
                    // Convertir le secteur sélectionné en catégorie API
                    let category: OfferCategory? = selectedSector.isEmpty ? nil : mapSectorToCategory(selectedSector)
                    
                    // Recherche par rayon avec filtres optionnels
                    professionalsResponse = try await partnersAPIService.searchProfessionals(
                        city: nil,
                        category: category,
                        name: cityText.isEmpty ? nil : cityText,
                        latitude: latitude,
                        longitude: longitude,
                        radius: searchRadius
                    )
                } else {
                    // Récupérer tous les professionnels depuis l'API
                    professionalsResponse = try await partnersAPIService.getAllProfessionals()
                }
                
                // Convertir en modèles Partner
                partners = professionalsResponse.map { $0.toPartner() }
                
                // Synchroniser les favoris depuis l'API
                await syncFavorites()
                
                // Appliquer les filtres
                applyFilters()
            } catch {
                print("Erreur lors du chargement des partenaires: \(error)")
                // En cas d'erreur, utiliser les données mockées en fallback
                partners = dataService.getPartners()
                applyFilters()
            }
        }
    }
    
    private func syncFavorites() async {
        do {
            // Charger les favoris depuis l'API
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            let favoriteIds = Set(favoritesResponse.map { $0.id })
            
            // Mettre à jour l'état isFavorite pour chaque partenaire
            for index in partners.indices {
                if let apiId = partners[index].apiId {
                    let isFavorite = favoriteIds.contains(apiId)
                    if partners[index].isFavorite != isFavorite {
                        let partner = partners[index]
                        partners[index] = Partner(
                            id: partner.id,
                            name: partner.name,
                            category: partner.category,
                            address: partner.address,
                            city: partner.city,
                            postalCode: partner.postalCode,
                            phone: partner.phone,
                            email: partner.email,
                            website: partner.website,
                            instagram: partner.instagram,
                            description: partner.description,
                            rating: partner.rating,
                            reviewCount: partner.reviewCount,
                            discount: partner.discount,
                            imageName: partner.imageName,
                            headerImageName: partner.headerImageName,
                            isFavorite: isFavorite,
                            apiId: partner.apiId
                        )
                    }
                }
            }
        } catch {
            print("Erreur lors de la synchronisation des favoris: \(error)")
            // En cas d'erreur, on garde l'état actuel
        }
    }
    
    private func mapSectorToCategory(_ sector: String) -> OfferCategory? {
        switch sector.lowercased() {
        case "santé & bien être", "sante & bien etre":
            return .santeBienEtre
        case "beauté & esthétique", "beaute & esthetique":
            return .beauteEsthetique
        case "food & plaisirs gourmands":
            return .foodPlaisirs
        case "loisirs & divertissements":
            return .loisirsDivertissements
        case "service & pratiques":
            return .servicePratiques
        case "entre pros":
            return .entrePros
        default:
            return nil
        }
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, utiliser le fallback local
            if let index = partners.firstIndex(where: { $0.id == partner.id }) {
                let updatedPartner = partners[index]
                partners[index] = Partner(
                    id: updatedPartner.id,
                    name: updatedPartner.name,
                    category: updatedPartner.category,
                    address: updatedPartner.address,
                    city: updatedPartner.city,
                    postalCode: updatedPartner.postalCode,
                    phone: updatedPartner.phone,
                    email: updatedPartner.email,
                    website: updatedPartner.website,
                    instagram: updatedPartner.instagram,
                    description: updatedPartner.description,
                    rating: updatedPartner.rating,
                    reviewCount: updatedPartner.reviewCount,
                    discount: updatedPartner.discount,
                    imageName: updatedPartner.imageName,
                    headerImageName: updatedPartner.headerImageName,
                    isFavorite: !updatedPartner.isFavorite,
                    apiId: updatedPartner.apiId
                )
                if let filteredIndex = filteredPartners.firstIndex(where: { $0.id == partner.id }) {
                    filteredPartners[filteredIndex] = partners[index]
                }
            }
            return
        }
        
        Task {
            do {
                if partner.isFavorite {
                    // Retirer des favoris
                    try await favoritesAPIService.removeFavorite(professionalId: apiId)
                } else {
                    // Ajouter aux favoris
                    try await favoritesAPIService.addFavorite(professionalId: apiId)
                }
                
                // Mettre à jour l'état local
                if let index = partners.firstIndex(where: { $0.id == partner.id }) {
                    let updatedPartner = partners[index]
                    partners[index] = Partner(
                        id: updatedPartner.id,
                        name: updatedPartner.name,
                        category: updatedPartner.category,
                        address: updatedPartner.address,
                        city: updatedPartner.city,
                        postalCode: updatedPartner.postalCode,
                        phone: updatedPartner.phone,
                        email: updatedPartner.email,
                        website: updatedPartner.website,
                        instagram: updatedPartner.instagram,
                        description: updatedPartner.description,
                        rating: updatedPartner.rating,
                        reviewCount: updatedPartner.reviewCount,
                        discount: updatedPartner.discount,
                        imageName: updatedPartner.imageName,
                        headerImageName: updatedPartner.headerImageName,
                        isFavorite: !updatedPartner.isFavorite,
                        apiId: updatedPartner.apiId
                    )
                    if let filteredIndex = filteredPartners.firstIndex(where: { $0.id == partner.id }) {
                        filteredPartners[filteredIndex] = partners[index]
                    }
                }
            } catch {
                print("Erreur lors de la modification du favori: \(error)")
                // En cas d'erreur, utiliser le fallback local
                if let index = partners.firstIndex(where: { $0.id == partner.id }) {
                    let updatedPartner = partners[index]
                    partners[index] = Partner(
                        id: updatedPartner.id,
                        name: updatedPartner.name,
                        category: updatedPartner.category,
                        address: updatedPartner.address,
                        city: updatedPartner.city,
                        postalCode: updatedPartner.postalCode,
                        phone: updatedPartner.phone,
                        email: updatedPartner.email,
                        website: updatedPartner.website,
                        instagram: updatedPartner.instagram,
                        description: updatedPartner.description,
                        rating: updatedPartner.rating,
                        reviewCount: updatedPartner.reviewCount,
                        discount: updatedPartner.discount,
                        imageName: updatedPartner.imageName,
                        headerImageName: updatedPartner.headerImageName,
                        isFavorite: !updatedPartner.isFavorite,
                        apiId: updatedPartner.apiId
                    )
                    if let filteredIndex = filteredPartners.firstIndex(where: { $0.id == partner.id }) {
                        filteredPartners[filteredIndex] = partners[index]
                    }
                }
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
        hasSearched = true
        // Recharger les partenaires depuis l'API avec les nouveaux filtres
        loadPartners()
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
