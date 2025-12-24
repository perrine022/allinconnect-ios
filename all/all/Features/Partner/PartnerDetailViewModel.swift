//
//  PartnerDetailViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class PartnerDetailViewModel: ObservableObject {
    @Published var partner: Partner
    @Published var currentOffers: [Offer] = []
    @Published var reviews: [Review] = []
    @Published var isTogglingFavorite: Bool = false
    @Published var favoriteErrorMessage: String?
    
    private let favoritesAPIService: FavoritesAPIService
    private let dataService: MockDataService
    
    init(
        partner: Partner,
        favoritesAPIService: FavoritesAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        self.partner = partner
        // Créer le service dans un contexte MainActor
        if let favoritesAPIService = favoritesAPIService {
            self.favoritesAPIService = favoritesAPIService
        } else {
            self.favoritesAPIService = FavoritesAPIService()
        }
        self.dataService = dataService
        loadData()
    }
    
    func loadData() {
        // Charger les offres en cours pour ce partenaire
        currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
        
        // Charger les avis (limité à 2)
        let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
        reviews = Array(allReviews.prefix(2))
    }
    
    func toggleFavorite() {
        // Ne pas permettre plusieurs clics simultanés
        guard !isTogglingFavorite else { return }
        
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, utiliser le fallback local
            partner.isFavorite.toggle()
            dataService.togglePartnerFavorite(partnerId: partner.id)
            return
        }
        
        isTogglingFavorite = true
        favoriteErrorMessage = nil
        
        // Sauvegarder l'état actuel pour pouvoir le restaurer en cas d'erreur
        let previousFavoriteState = partner.isFavorite
        
        // Mettre à jour l'état immédiatement pour un feedback visuel
        partner.isFavorite.toggle()
        
        Task {
            do {
                if previousFavoriteState {
                    // Retirer des favoris
                    try await favoritesAPIService.removeFavorite(professionalId: apiId)
                } else {
                    // Ajouter aux favoris
                    try await favoritesAPIService.addFavorite(professionalId: apiId)
                }
                
                // Succès - l'état est déjà mis à jour
                isTogglingFavorite = false
            } catch {
                print("Erreur lors de la modification du favori: \(error)")
                
                // Restaurer l'état précédent en cas d'erreur
                partner.isFavorite = previousFavoriteState
                
                // Afficher un message d'erreur
                if let apiError = error as? APIError {
                    switch apiError {
                    case .networkError:
                        favoriteErrorMessage = "Problème de connexion. Vérifiez votre connexion internet."
                    case .unauthorized:
                        favoriteErrorMessage = "Vous devez être connecté pour ajouter aux favoris"
                    default:
                        favoriteErrorMessage = "Une erreur s'est produite lors de la modification"
                    }
                } else {
                    favoriteErrorMessage = "Une erreur s'est produite lors de la modification"
                }
                
                // Effacer le message d'erreur après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.favoriteErrorMessage = nil
                }
                
                isTogglingFavorite = false
            }
        }
    }
    
    func callPartner() {
        guard let phone = partner.phone,
              let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openEmail() {
        guard let email = partner.email,
              let url = URL(string: "mailto:\(email)") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openWebsite() {
        guard let website = partner.website,
              let url = URL(string: website) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openInstagram() {
        guard let instagram = partner.instagram,
              let url = URL(string: instagram) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openMaps() {
        let address = "\(partner.address), \(partner.postalCode) \(partner.city)"
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(appleMapsURL) { success in
                if !success {
                    if let googleMapsURL = URL(string: "comgooglemaps://?q=\(encodedAddress)") {
                        if UIApplication.shared.canOpenURL(googleMapsURL) {
                            UIApplication.shared.open(googleMapsURL)
                        } else {
                            if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedAddress)") {
                                UIApplication.shared.open(webURL)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func submitRating(_ rating: Int) {
        // TODO: Intégrer avec l'API backend pour soumettre la note
        print("Note soumise: \(rating) étoiles pour \(partner.name)")
    }
}

