//
//  OfferDetailViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class OfferDetailViewModel: ObservableObject {
    @Published var offer: Offer?
    @Published var partner: Partner?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService // Gardé pour le fallback
    
    init(
        offerId: Int? = nil,
        offer: Offer? = nil, // Pour les offres mockées ou déjà chargées
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
        
        // Si on a déjà une offre (mockée), l'utiliser directement
        if let offer = offer {
            self.offer = offer
            // Essayer de charger le partenaire depuis les données mockées
            if let partnerId = offer.partnerId {
                self.partner = dataService.getPartnerById(id: partnerId)
            }
        } else if let offerId = offerId {
            // Sinon, charger depuis l'API
            loadOfferDetail(id: offerId)
        }
    }
    
    func loadOfferDetail(id: Int) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Charger les détails de l'offre depuis l'API
                let offerResponse = try await offersAPIService.getOfferDetail(id: id)
                
                // Convertir en modèle Offer
                let loadedOffer = offerResponse.toOffer()
                self.offer = loadedOffer
                
                // Si l'offre a un professionnel, convertir en Partner
                if let professional = offerResponse.professional {
                    // Créer un PartnerProfessionalResponse temporaire pour le mapping
                    let partnerProfessional = PartnerProfessionalResponse(
                        id: professional.id,
                        email: professional.email,
                        firstName: professional.firstName,
                        lastName: professional.lastName,
                        address: nil,
                        city: professional.city,
                        latitude: nil,
                        longitude: nil,
                        birthDate: nil,
                        userType: "PROFESSIONAL",
                        subscriptionType: nil,
                        profession: professional.profession,
                        category: professional.category,
                        hasConnectedBefore: nil,
                        referralCode: nil,
                        subscriptionPlan: nil
                    )
                    
                    self.partner = partnerProfessional.toPartner()
                }
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des détails de l'offre: \(error)")
            }
        }
    }
}

