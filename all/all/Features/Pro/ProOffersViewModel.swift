//
//  ProOffersViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ProOffersViewModel: ObservableObject {
    @Published var myOffers: [Offer] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService // Gardé en fallback
    
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
        loadMyOffers()
    }
    
    func loadMyOffers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Appeler l'API pour récupérer les offres du professionnel connecté
                let offersResponse = try await offersAPIService.getMyOffers()
                
                // Convertir les réponses en modèles Offer
                myOffers = offersResponse.map { $0.toOffer() }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement de mes offres: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                myOffers = dataService.getAllOffers()
            }
        }
    }
    
    func addOffer(_ offer: Offer) {
        myOffers.append(offer)
        // Plus tard, appeler l'API pour créer l'offre
    }
    
    func deleteOffer(_ offer: Offer) {
        myOffers.removeAll { $0.id == offer.id }
        // Plus tard, appeler l'API pour supprimer
    }
}

