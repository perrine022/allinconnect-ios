//
//  PartnersListViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class PartnersListViewModel: ObservableObject {
    @Published var allPartners: [Partner] = []
    @Published var filteredPartners: [Partner] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Search fields (comme HomeView)
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    @Published var searchRadius: Double = 10.0 // Rayon en km (0 = désactivé)
    @Published var onlyClub10: Bool = false
    
    // Secteurs disponibles
    let sectors: [String] = [
        "Tous les secteurs",
        "Santé & bien être",
        "Beauté & Esthétique",
        "Food & plaisirs gourmands",
        "Loisirs & Divertissements",
        "Service & pratiques",
        "Entre pros"
    ]
    
    private let partnersAPIService: PartnersAPIService
    private let favoritesAPIService: FavoritesAPIService
    private let dataService: MockDataService // Gardé pour les favoris
    private let locationService: LocationService
    
    init(
        partnersAPIService: PartnersAPIService? = nil,
        favoritesAPIService: FavoritesAPIService? = nil,
        dataService: MockDataService = MockDataService.shared,
        locationService: LocationService? = nil,
        initialCityText: String = "",
        initialSelectedSector: String = "",
        initialSearchRadius: Double = 10.0,
        initialOnlyClub10: Bool = false
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
        
        self.dataService = dataService
        // Accéder à LocationService.shared dans un contexte MainActor
        self.locationService = locationService ?? LocationService.shared
        
        // Initialiser avec les paramètres de recherche si fournis
        self.cityText = initialCityText
        self.selectedSector = initialSelectedSector
        self.searchRadius = initialSearchRadius
        self.onlyClub10 = initialOnlyClub10
        
        loadPartners()
    }
    
    func loadPartners() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // Déterminer les paramètres de recherche
                var city: String? = nil
                var category: OfferCategory? = nil
                var latitude: Double? = nil
                var longitude: Double? = nil
                var radius: Double? = nil
                
                // Si le rayon de recherche est activé et qu'on a la localisation
                if searchRadius > 0, let location = locationService.currentLocation {
                    latitude = location.coordinate.latitude
                    longitude = location.coordinate.longitude
                    radius = searchRadius
                }
                
                // Si une ville est spécifiée dans cityText (seulement si pas de recherche par rayon)
                if !cityText.isEmpty && radius == nil {
                    city = cityText
                }
                
                // Convertir le secteur sélectionné en catégorie API
                if !selectedSector.isEmpty && selectedSector != "Tous les secteurs" {
                    category = mapSectorToCategory(selectedSector)
                }
                
                // Appeler l'API avec les bons paramètres
                let professionalsResponse: [PartnerProfessionalResponse]
                
                // Priorité à la recherche par rayon si activée
                if let lat = latitude, let lon = longitude, let rad = radius {
                    // Recherche par rayon (peut combiner avec catégorie et nom)
                    professionalsResponse = try await partnersAPIService.searchProfessionals(
                        city: nil, // On ignore la ville quand on utilise le rayon
                        category: category,
                        name: cityText.isEmpty ? nil : cityText, // Utiliser cityText comme nom si pas vide
                        latitude: lat,
                        longitude: lon,
                        radius: rad,
                        isClub10: onlyClub10 ? true : nil
                    )
                } else if let city = city, let category = category {
                    // Recherche avec ville et catégorie
                    professionalsResponse = try await partnersAPIService.searchProfessionals(
                        city: city,
                        category: category,
                        isClub10: onlyClub10 ? true : nil
                    )
                } else if let city = city {
                    // Recherche par ville uniquement
                    // Si onlyClub10 est activé, utiliser searchProfessionals pour pouvoir filtrer
                    if onlyClub10 {
                        professionalsResponse = try await partnersAPIService.searchProfessionals(
                            city: city,
                            category: nil,
                            name: nil,
                            latitude: nil,
                            longitude: nil,
                            radius: nil,
                            isClub10: true
                        )
                    } else {
                        professionalsResponse = try await partnersAPIService.getProfessionalsByCity(city: city)
                    }
                } else {
                    // Récupérer tous les professionnels
                    // Si onlyClub10 est activé, utiliser searchProfessionals pour pouvoir filtrer
                    if onlyClub10 {
                        professionalsResponse = try await partnersAPIService.searchProfessionals(
                            city: nil,
                            category: nil,
                            name: nil,
                            latitude: nil,
                            longitude: nil,
                            radius: nil,
                            isClub10: true
                        )
                    } else {
                        professionalsResponse = try await partnersAPIService.getAllProfessionals()
                    }
                }
                
                // Convertir les réponses en modèles Partner
                allPartners = professionalsResponse.map { $0.toPartner() }
                
                print("🔍 [PartnersListViewModel] ✅ \(allPartners.count) partenaires chargés depuis l'API")
                print("🔍 [PartnersListViewModel] Partenaires avec discount (Club 10): \(allPartners.filter { $0.discount != nil && $0.discount == 10 }.count)")
                
                // Charger les favoris pour mettre à jour l'état isFavorite
                await syncFavorites()
                
                // Appliquer les filtres locaux (CLUB10, recherche texte si pas déjà utilisé)
                applyFilters()
                
                isLoading = false
            } catch {
                isLoading = false
                
                // Vérifier si c'est une erreur de décodage JSON corrompu
                if let apiError = error as? APIError,
                   case .decodingError(let underlyingError) = apiError,
                   let nsError = underlyingError as NSError?,
                   nsError.domain == NSCocoaErrorDomain,
                   nsError.code == 3840 {
                    // Erreur de décodage JSON corrompu - ne pas afficher d'erreur, utiliser données mockées
                    print("Erreur de décodage JSON lors du chargement des partenaires, utilisation des données mockées")
                    allPartners = dataService.getPartners()
                    applyFilters()
                    errorMessage = nil // Ne pas afficher d'erreur pour les réponses corrompues
                } else {
                    // Autre type d'erreur - afficher le message
                    errorMessage = error.localizedDescription
                    print("Erreur lors du chargement des partenaires: \(error)")
                    
                    // En cas d'erreur, utiliser les données mockées en fallback
                    allPartners = dataService.getPartners()
                    applyFilters()
                }
            }
        }
    }
    
    func searchPartners() {
        // Recharger depuis l'API avec les nouveaux filtres
        loadPartners()
    }
    
    private func syncFavorites() async {
        do {
            // Charger les favoris depuis l'API
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            let favoriteIds = Set(favoritesResponse.map { $0.id })
            
            // Mettre à jour l'état isFavorite pour chaque partenaire
            for index in allPartners.indices {
                if let apiId = allPartners[index].apiId {
                    let isFavorite = favoriteIds.contains(apiId)
                    if allPartners[index].isFavorite != isFavorite {
                        let partner = allPartners[index]
                        allPartners[index] = Partner(
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
            dataService.togglePartnerFavorite(partnerId: partner.id)
            if let index = allPartners.firstIndex(where: { $0.id == partner.id }) {
                let updatedPartner = allPartners[index]
                allPartners[index] = Partner(
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
                    filteredPartners[filteredIndex] = allPartners[index]
                }
            }
            applyFilters()
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
                if let index = allPartners.firstIndex(where: { $0.id == partner.id }) {
                    let updatedPartner = allPartners[index]
                    allPartners[index] = Partner(
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
                        filteredPartners[filteredIndex] = allPartners[index]
                    }
                }
                applyFilters()
            } catch {
                print("Erreur lors de la modification du favori: \(error)")
                // En cas d'erreur, utiliser le fallback local
                dataService.togglePartnerFavorite(partnerId: partner.id)
                if let index = allPartners.firstIndex(where: { $0.id == partner.id }) {
                    let updatedPartner = allPartners[index]
                    allPartners[index] = Partner(
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
                        filteredPartners[filteredIndex] = allPartners[index]
                    }
                }
                applyFilters()
            }
        }
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
        if !selectedSector.isEmpty && selectedSector != "Tous les secteurs" {
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

