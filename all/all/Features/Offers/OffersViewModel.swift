//
//  OffersViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class OffersViewModel: ObservableObject {
    @Published var allOffers: [Offer] = []
    @Published var filteredOffers: [Offer] = []
    @Published var isLoading: Bool = true // Commencer en état de chargement
    @Published var hasLoadedOnce: Bool = false // Pour savoir si on a déjà chargé une fois
    @Published var errorMessage: String?
    
    // Search fields (comme HomeView)
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    @Published var searchRadius: Double = 10.0 // Rayon en km (0 = désactivé)
    @Published var onlyClub10: Bool = false
    @Published var selectedOfferType: OfferType? = nil // nil = tous, .offer = offres, .event = événements
    
    // Filtres de date
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil
    @Published var showDatePicker: Bool = false
    
    // Mode d'affichage : actuelles ou à venir
    @Published var offerTimeMode: OfferTimeMode = .current
    
    enum OfferTimeMode {
        case current // Offres actuelles
        case upcoming // Offres à venir
    }
    
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
    
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService // Gardé pour les partenaires
    private let cacheService = CacheService.shared
    private let locationService: LocationService
    
    init(
        offersAPIService: OffersAPIService? = nil,
        dataService: MockDataService = MockDataService.shared,
        locationService: LocationService? = nil
    ) {
        // Créer le service dans un contexte MainActor
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        self.dataService = dataService
        // Accéder à LocationService.shared dans un contexte MainActor
        self.locationService = locationService ?? LocationService.shared
        loadOffers()
    }
    
    func loadOffers(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        // Charger depuis le cache d'abord si disponible et pas de rafraîchissement forcé
        if !forceRefresh, let cachedOffers = cacheService.getOffers() {
            print("[OffersViewModel] Chargement depuis le cache")
            allOffers = cachedOffers
            applyFilters()
            hasLoadedOnce = true
            isLoading = false
            
            // Charger en arrière-plan pour mettre à jour le cache
            Task {
                await refreshOffers()
            }
            return
        }
        
        Task {
            do {
                // Déterminer les paramètres de filtrage
                var city: String? = nil
                var category: OfferCategory? = nil
                var latitude: Double? = nil
                var longitude: Double? = nil
                var radius: Double? = nil
                
                // Si le rayon de recherche est activé et qu'on a la localisation, utiliser la géolocalisation
                if searchRadius > 0, let location = locationService.currentLocation {
                    latitude = location.coordinate.latitude
                    longitude = location.coordinate.longitude
                    radius = searchRadius
                    print("[OffersViewModel] 📍 Utilisation de la géolocalisation: lat=\(latitude!), lon=\(longitude!), radius=\(radius!) km")
                } else if !cityText.isEmpty {
                    // Sinon, utiliser la ville si spécifiée (seulement si pas de recherche par rayon)
                    city = cityText
                    print("[OffersViewModel] 📍 Utilisation de la ville: \(cityText)")
                }
                
                // Convertir le secteur sélectionné en catégorie API
                if !selectedSector.isEmpty {
                    category = mapSectorToCategory(selectedSector)
                }
                
                // Convertir le type sélectionné en type API
                let apiType: String? = selectedOfferType == .event ? "EVENEMENT" : (selectedOfferType == .offer ? "OFFRE" : nil)
                
                // Formater les dates au format ISO 8601 (seulement pour le mode "à venir")
                let startDateString: String?
                let endDateString: String?
                
                if offerTimeMode == .upcoming {
                    // Pour "à venir", utiliser les dates sélectionnées
                    startDateString = startDate != nil ? formatDateToISO8601(startDate!, isStartOfDay: true) : nil
                    endDateString = endDate != nil ? formatDateToISO8601(endDate!, isStartOfDay: false) : nil
                } else {
                    // Pour "actuelles", ne pas envoyer de dates (récupérer toutes les offres actives)
                    startDateString = nil
                    endDateString = nil
                }
                
                // Appeler l'API pour récupérer les offres
                let offersResponse = try await offersAPIService.getAllOffers(
                    city: city,
                    category: category,
                    professionalId: nil,
                    type: apiType,
                    startDate: startDateString,
                    endDate: endDateString,
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius
                )
                
                // Convertir les réponses en modèles Offer
                allOffers = offersResponse.map { $0.toOffer() }
                
                // Sauvegarder en cache
                cacheService.saveOffers(allOffers)
                
                // Appliquer les filtres locaux (CLUB10, recherche texte)
                applyFilters()
                
                hasLoadedOnce = true
                isLoading = false
            } catch {
                hasLoadedOnce = true
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des offres: \(error)")
                
                // En cas d'erreur, on peut utiliser les données mockées en fallback
                allOffers = dataService.getAllOffers()
                applyFilters()
            }
        }
    }
    
    func searchOffers() {
        // Recharger depuis l'API avec les nouveaux filtres
        loadOffers(forceRefresh: true)
    }
    
    private func refreshOffers() async {
        do {
            // Déterminer les paramètres de filtrage
            var city: String? = nil
            var category: OfferCategory? = nil
            var latitude: Double? = nil
            var longitude: Double? = nil
            var radius: Double? = nil
            
            // Si le rayon de recherche est activé et qu'on a la localisation, utiliser la géolocalisation
            if searchRadius > 0, let location = locationService.currentLocation {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                radius = searchRadius
            } else if !cityText.isEmpty {
                // Sinon, utiliser la ville si spécifiée
                city = cityText
            }
            
            if !selectedSector.isEmpty {
                category = mapSectorToCategory(selectedSector)
            }
            
            let apiType: String? = selectedOfferType == .event ? "EVENEMENT" : (selectedOfferType == .offer ? "OFFRE" : nil)
            
            // Formater les dates au format ISO 8601 (seulement pour le mode "à venir")
            let startDateString: String?
            let endDateString: String?
            
            if offerTimeMode == .upcoming {
                // Pour "à venir", utiliser les dates sélectionnées
                startDateString = startDate != nil ? formatDateToISO8601(startDate!, isStartOfDay: true) : nil
                endDateString = endDate != nil ? formatDateToISO8601(endDate!, isStartOfDay: false) : nil
            } else {
                // Pour "actuelles", ne pas envoyer de dates
                startDateString = nil
                endDateString = nil
            }
            
            let offersResponse = try await offersAPIService.getAllOffers(
                city: city,
                category: category,
                professionalId: nil,
                type: apiType,
                startDate: startDateString,
                endDate: endDateString,
                latitude: latitude,
                longitude: longitude,
                radius: radius
            )
            
            let refreshedOffers = offersResponse.map { $0.toOffer() }
            
            // Mettre à jour les données et le cache
            await MainActor.run {
                allOffers = refreshedOffers
                cacheService.saveOffers(refreshedOffers)
                applyFilters()
            }
        } catch {
            print("[OffersViewModel] Erreur lors du rafraîchissement en arrière-plan: \(error)")
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
    
    func applyFilters() {
        var filtered = allOffers
        
        // Filtre par type (Offres ou Événements)
        if let selectedType = selectedOfferType {
            filtered = filtered.filter { $0.offerType == selectedType }
        }
        
        // Filtre par texte de recherche (recherche locale)
        if !cityText.isEmpty {
            filtered = filtered.filter { offer in
                offer.businessName.localizedCaseInsensitiveContains(cityText) ||
                offer.title.localizedCaseInsensitiveContains(cityText) ||
                offer.description.localizedCaseInsensitiveContains(cityText)
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
    
    // MARK: - Date Formatting
    private func formatDateToISO8601(_ date: Date, isStartOfDay: Bool) -> String {
        // Format ISO 8601: YYYY-MM-DDTHH:mm:ssZ (avec Z pour UTC)
        // Utiliser un calendrier UTC pour éviter les problèmes de timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current // UTC
        
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let dateOnly = calendar.date(from: components) else {
            // Fallback si la création de la date échoue
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            return formatter.string(from: date)
        }
        
        // Ajouter l'heure selon le type (début ou fin de journée) en UTC
        let finalDate: Date
        if isStartOfDay {
            finalDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: dateOnly) ?? dateOnly
        } else {
            finalDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateOnly) ?? dateOnly
        }
        
        // Formater en UTC avec le Z à la fin
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        return formatter.string(from: finalDate)
    }
    
    // Fonction pour réinitialiser les filtres de date
    func clearDateFilters() {
        startDate = nil
        endDate = nil
        searchOffers()
    }
}

