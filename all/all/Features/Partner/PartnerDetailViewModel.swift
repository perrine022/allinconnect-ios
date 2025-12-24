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
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, utiliser le fallback local
            partner.isFavorite.toggle()
            dataService.togglePartnerFavorite(partnerId: partner.id)
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
                partner.isFavorite.toggle()
            } catch {
                print("Erreur lors de la modification du favori: \(error)")
                // En cas d'erreur, utiliser le fallback local
                partner.isFavorite.toggle()
                dataService.togglePartnerFavorite(partnerId: partner.id)
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
        
        // Essayer d'abord Apple Maps
        if let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(appleMapsURL) { success in
                // Si Apple Maps échoue, essayer Google Maps
                if !success {
                    if let googleMapsURL = URL(string: "comgooglemaps://?q=\(encodedAddress)") {
                        if UIApplication.shared.canOpenURL(googleMapsURL) {
                            UIApplication.shared.open(googleMapsURL)
                        } else {
                            // Fallback vers Google Maps web
                            if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedAddress)") {
                                UIApplication.shared.open(webURL)
                            }
                        }
                    }
                }
            }
        }
    }
}

