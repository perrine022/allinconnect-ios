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
    @Published var isLoadingOffers: Bool = false
    @Published var offersError: String? = nil
    @Published var offersAPIError: APIError? = nil // Pour détecter les erreurs 500
    
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
        isLoadingOffers = true
        offersError = nil
        offersAPIError = nil // Réinitialiser l'erreur API
            
            do {
                print("═══════════════════════════════════════════════════════════")
                print("[HomeViewModel] 🔥 DÉBUT Chargement des 5 premières offres pour 'À ne pas louper'")
                print("[HomeViewModel] Filtre: type=OFFRE (uniquement les offres, pas les événements)")
                print("═══════════════════════════════════════════════════════════")
                
                // Utiliser la même logique que OffersViewModel : utiliser cityText s'il est rempli
                // Ne pas utiliser getUserMe() qui nécessite une authentification
                var city: String? = nil
                if !cityText.isEmpty {
                    city = cityText
                    print("[HomeViewModel] 📍 Utilisation de la ville depuis cityText: \(cityText)")
                } else {
                    print("[HomeViewModel] 📍 Aucune ville spécifiée, chargement de toutes les offres")
                }
                
                // Utiliser exactement le même appel API que OffersViewModel
                let offersResponse = try await offersAPIService.getAllOffers(
                    city: city,
                    category: nil,
                    professionalId: nil,
                    type: "OFFRE", // Filtrer uniquement les offres (pas les événements)
                    startDate: nil,
                    endDate: nil
                )
                
                print("[HomeViewModel] ✅ \(offersResponse.count) offres récupérées depuis l'API (type=OFFRE)")
                
                // Prendre les 5 premières offres avec leurs vraies images depuis l'API
                let limitedOffers = Array(offersResponse.prefix(5))
                
                print("[HomeViewModel] ✅ \(limitedOffers.count) offres sélectionnées pour affichage")
                for (index, offer) in limitedOffers.enumerated() {
                    print("[HomeViewModel]   \(index + 1). \(offer.title) - Type: \(offer.type ?? "N/A") - Image: \(offer.imageUrl ?? "aucune")")
                }
                
                // Convertir les réponses API en modèles Offer (avec les vraies images)
                offers = limitedOffers.map { $0.toOffer() }
                
                print("[HomeViewModel] ✅ Offres converties et prêtes à afficher avec images réelles")
                print("═══════════════════════════════════════════════════════════")
                isLoadingOffers = false
            } catch {
                isLoadingOffers = false
                let errorMessage = error.localizedDescription
                offersError = errorMessage
                
                // Stocker l'erreur API complète pour détecter les erreurs 500
                if let apiError = error as? APIError {
                    offersAPIError = apiError
                } else {
                    offersAPIError = nil
                }
                
                print("═══════════════════════════════════════════════════════════")
                print("[HomeViewModel] ❌ ERREUR lors du chargement des offres")
                print("[HomeViewModel] Type d'erreur: \(type(of: error))")
                print("[HomeViewModel] Message: \(errorMessage)")
                
                if let apiError = error as? APIError {
                    print("[HomeViewModel] Détails APIError:")
                    switch apiError {
                    case .unauthorized:
                        print("   - Erreur 401: Token expiré ou invalide")
                    case .networkError:
                        print("   - Erreur réseau: Vérifier la connexion")
                    case .invalidResponse:
                        print("   - Réponse invalide du serveur")
                    case .decodingError(let underlyingError):
                        print("   - Erreur de décodage: \(underlyingError.localizedDescription)")
                    case .httpError(let statusCode, _):
                        print("   - Erreur HTTP \(statusCode)")
                        if statusCode >= 500 {
                            print("   - ⚠️ Erreur serveur détectée (500+)")
                        }
                    default:
                        print("   - Autre erreur API")
                    }
                }
                
                print("[HomeViewModel] ⚠️ Utilisation d'un tableau vide")
                offers = []
                print("═══════════════════════════════════════════════════════════")
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
                // Vérifier si c'est une erreur de décodage JSON corrompu
                if let apiError = error as? APIError,
                   case .decodingError(let underlyingError) = apiError,
                   let nsError = underlyingError as NSError?,
                   nsError.domain == NSCocoaErrorDomain,
                   nsError.code == 3840 {
                    // Erreur de décodage JSON corrompu - utiliser données mockées sans afficher d'erreur
                    print("Erreur de décodage JSON lors du chargement des partenaires, utilisation des données mockées")
                    partners = dataService.getPartners()
                    applyFilters()
                } else {
                    // Autre type d'erreur
                    print("Erreur lors du chargement des partenaires: \(error)")
                    // En cas d'erreur, utiliser les données mockées en fallback
                    partners = dataService.getPartners()
                    applyFilters()
                }
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
                    establishmentImageUrl: updatedPartner.establishmentImageUrl,
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
