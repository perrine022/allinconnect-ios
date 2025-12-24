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
    private let partnersAPIService: PartnersAPIService
    private let dataService: MockDataService
    
    init(
        partner: Partner,
        favoritesAPIService: FavoritesAPIService? = nil,
        partnersAPIService: PartnersAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        self.partner = partner
        // Créer les services dans un contexte MainActor
        if let favoritesAPIService = favoritesAPIService {
            self.favoritesAPIService = favoritesAPIService
        } else {
            self.favoritesAPIService = FavoritesAPIService()
        }
        
        if let partnersAPIService = partnersAPIService {
            self.partnersAPIService = partnersAPIService
        } else {
            self.partnersAPIService = PartnersAPIService()
        }
        
        self.dataService = dataService
        loadData()
    }
    
    func loadData() {
        // Si on a un apiId, charger les détails depuis le backend
        if let apiId = partner.apiId {
            Task {
                await loadPartnerDetails(apiId: apiId)
            }
        } else {
            // Sinon, utiliser les données mockées
            currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
            let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
            reviews = Array(allReviews.prefix(2))
        }
    }
    
    private func loadPartnerDetails(apiId: Int) async {
        do {
            // Charger les détails du partenaire depuis l'API
            let professionalResponse = try await partnersAPIService.getProfessionalById(id: apiId)
            
            // Mettre à jour le partenaire avec les données du backend
            let updatedPartner = professionalResponse.toPartner()
            
            // Préserver l'état isFavorite actuel (il sera mis à jour via syncFavorites)
            let currentFavoriteState = partner.isFavorite
            
            // Mettre à jour le partenaire
            partner = Partner(
                id: partner.id, // Garder le même UUID local
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
                isFavorite: currentFavoriteState, // Préserver l'état actuel
                apiId: updatedPartner.apiId
            )
            
            // Synchroniser l'état des favoris
            await syncFavoriteStatus()
            
            // Charger les offres et avis (pour l'instant depuis les données mockées, à remplacer par l'API plus tard)
            currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
            let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
            reviews = Array(allReviews.prefix(2))
        } catch {
            print("Erreur lors du chargement des détails du partenaire: \(error)")
            // En cas d'erreur, utiliser les données mockées
            currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
            let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
            reviews = Array(allReviews.prefix(2))
        }
    }
    
    private func syncFavoriteStatus() async {
        guard let apiId = partner.apiId else { return }
        
        do {
            // Charger les favoris depuis l'API
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            let favoriteIds = Set(favoritesResponse.map { $0.id })
            
            // Mettre à jour l'état isFavorite
            if favoriteIds.contains(apiId) {
                partner = Partner(
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
                    isFavorite: true,
                    apiId: partner.apiId
                )
            }
        } catch {
            print("Erreur lors de la synchronisation du statut favori: \(error)")
        }
    }
    
    func toggleFavorite() {
        // Ne pas permettre plusieurs clics simultanés
        guard !isTogglingFavorite else { return }
        
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, utiliser le fallback local
            partner = Partner(
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
                isFavorite: !partner.isFavorite,
                apiId: partner.apiId
            )
            dataService.togglePartnerFavorite(partnerId: partner.id)
            return
        }
        
        isTogglingFavorite = true
        favoriteErrorMessage = nil
        
        // Sauvegarder l'état actuel pour pouvoir le restaurer en cas d'erreur
        let previousFavoriteState = partner.isFavorite
        
        // Mettre à jour l'état immédiatement pour un feedback visuel
        partner = Partner(
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
            isFavorite: !partner.isFavorite,
            apiId: partner.apiId
        )
        
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
                partner = Partner(
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
                    isFavorite: previousFavoriteState,
                    apiId: partner.apiId
                )
                
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

