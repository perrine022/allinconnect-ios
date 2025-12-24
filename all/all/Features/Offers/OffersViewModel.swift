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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
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
    
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService // Gardé pour les partenaires
    
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
    
    func loadOffers() {
        isLoading = true
        errorMessage = nil
        
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
                
                // Appeler l'API
                let offersResponse = try await offersAPIService.getAllOffers(
                    city: city,
                    category: category
                )
                
                // Convertir les réponses en modèles Offer
                allOffers = offersResponse.map { $0.toOffer() }
                
                // Appliquer les filtres locaux (CLUB10, recherche texte)
                applyFilters()
                
                isLoading = false
            } catch {
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
        loadOffers()
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
    
    private func applyFilters() {
        var filtered = allOffers
        
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
}

