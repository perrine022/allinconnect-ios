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
    
    init(
        offersAPIService: OffersAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        // Créer le service dans un contexte MainActor
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        self.dataService = dataService
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
                
                // Si une ville est spécifiée dans cityText, l'utiliser
                if !cityText.isEmpty {
                    city = cityText
                }
                
                // Convertir le secteur sélectionné en catégorie API
                if !selectedSector.isEmpty {
                    category = mapSectorToCategory(selectedSector)
                }
                
                // Convertir le type sélectionné en type API
                let apiType: String? = selectedOfferType == .event ? "EVENEMENT" : (selectedOfferType == .offer ? "OFFRE" : nil)
                
                // Formater les dates au format ISO 8601
                // Pour startDate, utiliser le début de la journée (00:00:00)
                // Pour endDate, utiliser la fin de la journée (23:59:59)
                let startDateString: String? = startDate != nil ? formatDateToISO8601(startDate!, isStartOfDay: true) : nil
                let endDateString: String? = endDate != nil ? formatDateToISO8601(endDate!, isStartOfDay: false) : nil
                
                // Appeler l'API pour récupérer les offres avec filtres de date
                let offersResponse = try await offersAPIService.getAllOffers(
                    city: city,
                    category: category,
                    professionalId: nil,
                    type: apiType,
                    startDate: startDateString,
                    endDate: endDateString
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
            
            if !cityText.isEmpty {
                city = cityText
            }
            
            if !selectedSector.isEmpty {
                category = mapSectorToCategory(selectedSector)
            }
            
            let apiType: String? = selectedOfferType == .event ? "EVENEMENT" : (selectedOfferType == .offer ? "OFFRE" : nil)
            
            // Formater les dates au format ISO 8601
            // Pour startDate, utiliser le début de la journée (00:00:00)
            // Pour endDate, utiliser la fin de la journée (23:59:59)
            let startDateString: String? = startDate != nil ? formatDateToISO8601(startDate!, isStartOfDay: true) : nil
            let endDateString: String? = endDate != nil ? formatDateToISO8601(endDate!, isStartOfDay: false) : nil
            
            let offersResponse = try await offersAPIService.getAllOffers(
                city: city,
                category: category,
                professionalId: nil,
                type: apiType,
                startDate: startDateString,
                endDate: endDateString
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
        // Format ISO 8601: YYYY-MM-DDTHH:mm:ss
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let dateOnly = calendar.date(from: components) else {
            // Fallback si la création de la date échoue
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: date)
        }
        
        // Ajouter l'heure selon le type (début ou fin de journée)
        let finalDate: Date
        if isStartOfDay {
            finalDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: dateOnly) ?? dateOnly
        } else {
            finalDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: dateOnly) ?? dateOnly
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: finalDate)
    }
    
    // Fonction pour réinitialiser les filtres de date
    func clearDateFilters() {
        startDate = nil
        endDate = nil
        searchOffers()
    }
}

