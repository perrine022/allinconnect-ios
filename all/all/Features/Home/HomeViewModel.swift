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
    @Published var featuredPartners: [Partner] = [] // Les 5 premiers partenaires pour la page d'accueil
    @Published var filteredProfessionals: [Professional] = []
    @Published var filteredPartners: [Partner] = []
    @Published var isLoadingOffers: Bool = false
    @Published var isLoadingPartners: Bool = false
    @Published var offersError: String? = nil
    @Published var offersAPIError: APIError? = nil // Pour détecter les erreurs 500
    @Published var isUserUnknown: Bool = false // Statut utilisateur UNKNOWN
    
    // Search fields
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    @Published var searchRadius: Double = 15.0 // Rayon en km (0 = désactivé)
    @Published var onlyClub10: Bool = false
    @Published var hasSearched: Bool = false // Indique si l'utilisateur a cliqué sur Rechercher
    
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
        checkUserStatus()
    }
    
    // Vérifier le statut utilisateur (UNKNOWN ou non)
    func checkUserStatus() {
        Task { @MainActor in
            do {
                let userLight = try await profileAPIService.getUserLight()
                let userTypeString = userLight.userType ?? ""
                isUserUnknown = userTypeString == "UNKNOWN" || userTypeString.isEmpty
            } catch {
                print("Erreur lors de la vérification du statut utilisateur: \(error.localizedDescription)")
                // En cas d'erreur, considérer comme UNKNOWN pour afficher les cartes
                isUserUnknown = true
            }
        }
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
                print("[HomeViewModel] 🔥 DÉBUT Chargement des 5 offres les plus proches pour 'À ne pas louper'")
                print("[HomeViewModel] Filtre: type=OFFRE (uniquement les offres, pas les événements)")
                print("═══════════════════════════════════════════════════════════")
                
                // Déterminer les paramètres de recherche
                var city: String? = nil
                var latitude: Double? = nil
                var longitude: Double? = nil
                var radius: Double? = nil
                
                // TOUJOURS utiliser la géolocalisation si disponible pour les offres les plus proches
                if let location = locationService.currentLocation {
                    latitude = location.coordinate.latitude
                    longitude = location.coordinate.longitude
                    // Utiliser un rayon par défaut de 50km si searchRadius est à 0
                    radius = searchRadius > 0 ? searchRadius : 50.0
                    print("[HomeViewModel] 📍 Utilisation de la géolocalisation: lat=\(latitude!), lon=\(longitude!), radius=\(radius!) km")
                } else if !cityText.isEmpty {
                    // Sinon, utiliser la ville si spécifiée
                    city = cityText
                    print("[HomeViewModel] 📍 Utilisation de la ville depuis cityText: \(cityText)")
                } else {
                    print("[HomeViewModel] 📍 Aucune localisation disponible, chargement de toutes les offres")
                }
                
                // Utiliser exactement le même appel API que OffersViewModel
                let offersResponse = try await offersAPIService.getAllOffers(
                    city: city,
                    category: nil,
                    professionalId: nil,
                    type: "OFFRE", // Filtrer uniquement les offres (pas les événements)
                    startDate: nil,
                    endDate: nil,
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius,
                    isClub10: onlyClub10 ? true : nil
                )
                
                print("[HomeViewModel] ✅ \(offersResponse.count) offres récupérées depuis l'API (type=OFFRE)")
                
                // Trier les offres par distance (les plus proches en premier)
                // Les offres avec distanceMeters sont triées en premier, puis par distance croissante
                let sortedOffers = offersResponse.sorted { offer1, offer2 in
                    let dist1 = offer1.distanceMeters ?? Double.infinity
                    let dist2 = offer2.distanceMeters ?? Double.infinity
                    return dist1 < dist2
                }
                
                // Prendre les 5 offres les plus proches
                let limitedOffers = Array(sortedOffers.prefix(5))
                
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
                    let category: OfferCategory? = (selectedSector.isEmpty || selectedSector == "Tous les secteurs") ? nil : mapSectorToCategory(selectedSector)
                    
                    print("═══════════════════════════════════════════════════════════")
                    print("🔍 [HomeViewModel] searchProfessionals() - Début")
                    print("🔍 [HomeViewModel] onlyClub10: \(onlyClub10)")
                    print("🔍 [HomeViewModel] isClub10 qui sera envoyé: \(onlyClub10 ? "true" : "nil")")
                    print("═══════════════════════════════════════════════════════════")
                    
                    // Recherche par rayon avec filtres optionnels
                    professionalsResponse = try await partnersAPIService.searchProfessionals(
                        city: nil,
                        category: category,
                        name: cityText.isEmpty ? nil : cityText,
                        latitude: latitude,
                        longitude: longitude,
                        radius: searchRadius,
                        isClub10: onlyClub10 ? true : nil
                    )
                } else {
                    // Récupérer tous les professionnels depuis l'API
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
                
                // Convertir en modèles Partner
                partners = professionalsResponse.map { $0.toPartner() }
                
                print("🔍 [HomeViewModel] ✅ \(partners.count) partenaires chargés depuis l'API")
                print("🔍 [HomeViewModel] Partenaires avec discount (Club 10): \(partners.filter { $0.discount != nil && $0.discount == 10 }.count)")
                
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
                    print("Erreur lors du chargement des partenaires: \(error.localizedDescription)")
                    partners = []
                }
            }
        }
    }
    
    // Charger les 4 partenaires les plus proches pour la page d'accueil
    func loadFeaturedPartners() {
        Task { @MainActor in
            isLoadingPartners = true
            do {
                var professionalsResponse: [PartnerProfessionalResponse]
                
                // TOUJOURS utiliser la géolocalisation si disponible pour les partenaires les plus proches
                if let location = locationService.currentLocation {
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    // Utiliser un rayon par défaut de 50km si searchRadius est à 0
                    let radius = searchRadius > 0 ? searchRadius : 50.0
                    
                    print("🔍 [HomeViewModel] loadFeaturedPartners() - Utilisation de la géolocalisation")
                    print("   - Latitude: \(latitude), Longitude: \(longitude), Rayon: \(radius) km")
                    
                    // Recherche par rayon pour obtenir les distances
                    professionalsResponse = try await partnersAPIService.searchProfessionals(
                        city: nil,
                        category: nil,
                        name: nil,
                        latitude: latitude,
                        longitude: longitude,
                        radius: radius,
                        isClub10: nil
                    )
                } else {
                    // Si pas de localisation, récupérer tous les professionnels
                    print("🔍 [HomeViewModel] loadFeaturedPartners() - Pas de localisation, chargement de tous les partenaires")
                    professionalsResponse = try await partnersAPIService.getAllProfessionals()
                }
                
                // Convertir en modèles Partner
                var allPartners = professionalsResponse.map { $0.toPartner() }
                
                // Trier les partenaires par distance (les plus proches en premier)
                // Les partenaires avec distanceMeters sont triés en premier, puis par distance croissante
                allPartners.sort { partner1, partner2 in
                    let dist1 = partner1.distanceMeters ?? Double.infinity
                    let dist2 = partner2.distanceMeters ?? Double.infinity
                    return dist1 < dist2
                }
                
                // Prendre les 4 partenaires les plus proches
                featuredPartners = Array(allPartners.prefix(4))
                
                print("🔍 [HomeViewModel] ✅ \(featuredPartners.count) partenaires les plus proches chargés pour l'accueil")
                
                // Synchroniser les favoris depuis l'API pour les partenaires affichés
                await syncFavorites()
                
                isLoadingPartners = false
            } catch {
                isLoadingPartners = false
                print("Erreur lors du chargement des partenaires: \(error.localizedDescription)")
                featuredPartners = []
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
            
            // Mettre à jour aussi les featuredPartners
            for index in featuredPartners.indices {
                if let apiId = featuredPartners[index].apiId {
                    let isFavorite = favoriteIds.contains(apiId)
                    if featuredPartners[index].isFavorite != isFavorite {
                        let partner = featuredPartners[index]
                        featuredPartners[index] = Partner(
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
            
            // Mettre à jour aussi les featuredPartners (pour la page d'accueil)
            if let featuredIndex = featuredPartners.firstIndex(where: { $0.id == partner.id }) {
                let updatedFeaturedPartner = featuredPartners[featuredIndex]
                featuredPartners[featuredIndex] = Partner(
                    id: updatedFeaturedPartner.id,
                    name: updatedFeaturedPartner.name,
                    category: updatedFeaturedPartner.category,
                    address: updatedFeaturedPartner.address,
                    city: updatedFeaturedPartner.city,
                    postalCode: updatedFeaturedPartner.postalCode,
                    phone: updatedFeaturedPartner.phone,
                    email: updatedFeaturedPartner.email,
                    website: updatedFeaturedPartner.website,
                    instagram: updatedFeaturedPartner.instagram,
                    description: updatedFeaturedPartner.description,
                    rating: updatedFeaturedPartner.rating,
                    reviewCount: updatedFeaturedPartner.reviewCount,
                    discount: updatedFeaturedPartner.discount,
                    imageName: updatedFeaturedPartner.imageName,
                    headerImageName: updatedFeaturedPartner.headerImageName,
                    establishmentImageUrl: updatedFeaturedPartner.establishmentImageUrl,
                    isFavorite: !updatedFeaturedPartner.isFavorite,
                    apiId: updatedFeaturedPartner.apiId
                )
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
                
                // Mettre à jour l'état local pour partners et filteredPartners
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
                
                // Mettre à jour aussi les featuredPartners (pour la page d'accueil)
                if let featuredIndex = featuredPartners.firstIndex(where: { $0.id == partner.id }) {
                    let updatedFeaturedPartner = featuredPartners[featuredIndex]
                    featuredPartners[featuredIndex] = Partner(
                        id: updatedFeaturedPartner.id,
                        name: updatedFeaturedPartner.name,
                        category: updatedFeaturedPartner.category,
                        address: updatedFeaturedPartner.address,
                        city: updatedFeaturedPartner.city,
                        postalCode: updatedFeaturedPartner.postalCode,
                        phone: updatedFeaturedPartner.phone,
                        email: updatedFeaturedPartner.email,
                        website: updatedFeaturedPartner.website,
                        instagram: updatedFeaturedPartner.instagram,
                        description: updatedFeaturedPartner.description,
                        rating: updatedFeaturedPartner.rating,
                        reviewCount: updatedFeaturedPartner.reviewCount,
                        discount: updatedFeaturedPartner.discount,
                        imageName: updatedFeaturedPartner.imageName,
                        headerImageName: updatedFeaturedPartner.headerImageName,
                        establishmentImageUrl: updatedFeaturedPartner.establishmentImageUrl,
                        isFavorite: !updatedFeaturedPartner.isFavorite,
                        apiId: updatedFeaturedPartner.apiId
                    )
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
        if !selectedSector.isEmpty && selectedSector != "Tous les secteurs" {
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
        if !selectedSector.isEmpty && selectedSector != "Tous les secteurs" {
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
