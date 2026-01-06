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
    private let offersAPIService: OffersAPIService
    private let ratingsAPIService: RatingsAPIService
    private let profileAPIService: ProfileAPIService
    private let dataService: MockDataService
    
    @Published var hasUserRated: Bool = false
    @Published var isLoadingRatings: Bool = false
    
    init(
        partner: Partner,
        favoritesAPIService: FavoritesAPIService? = nil,
        partnersAPIService: PartnersAPIService? = nil,
        offersAPIService: OffersAPIService? = nil,
        ratingsAPIService: RatingsAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil,
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
        
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        
        if let ratingsAPIService = ratingsAPIService {
            self.ratingsAPIService = ratingsAPIService
        } else {
            self.ratingsAPIService = RatingsAPIService()
        }
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
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
            // Si pas d'apiId, on ne peut pas vérifier si l'utilisateur a déjà noté
            hasUserRated = false
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
                establishmentImageUrl: updatedPartner.establishmentImageUrl, // Préserver l'URL de l'image
                isFavorite: currentFavoriteState, // Préserver l'état actuel
                apiId: updatedPartner.apiId
            )
            
            // Synchroniser l'état des favoris
            await syncFavoriteStatus()
            
            // Charger les offres actives depuis l'API
            await loadActiveOffers(professionalId: apiId)
            
            // Charger les avis depuis l'API
            await loadRatings(professionalId: apiId)
        } catch {
            print("Erreur lors du chargement des détails du partenaire: \(error)")
            // En cas d'erreur, utiliser les données mockées
            currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
            let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
            reviews = Array(allReviews.prefix(2))
        }
    }
    
    private func loadRatings(professionalId: Int) async {
        isLoadingRatings = true
        
        do {
            // Charger les avis depuis l'API
            let ratingsResponse = try await ratingsAPIService.getRatingsByUser(userId: professionalId)
            
            // Convertir les réponses en modèles Review
            reviews = ratingsResponse.map { $0.toReview() }
            
            // Vérifier si l'utilisateur connecté a déjà laissé un avis
            await checkIfUserHasRated(ratings: ratingsResponse)
            
            // Mettre à jour la note moyenne et le nombre d'avis du partenaire
            let averageRating = try await ratingsAPIService.getAverageRating(userId: professionalId)
            let reviewCount = reviews.count
            
            // Mettre à jour le partenaire avec la nouvelle note et le nombre d'avis
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
                rating: averageRating,
                reviewCount: reviewCount,
                discount: partner.discount,
                imageName: partner.imageName,
                headerImageName: partner.headerImageName,
                establishmentImageUrl: partner.establishmentImageUrl,
                isFavorite: partner.isFavorite,
                apiId: partner.apiId
            )
            
            isLoadingRatings = false
        } catch {
            print("Erreur lors du chargement des avis: \(error)")
            // En cas d'erreur, utiliser les données mockées
            let allReviews = dataService.getReviewsForPartner(partnerId: partner.id)
            reviews = Array(allReviews.prefix(2))
            isLoadingRatings = false
        }
    }
    
    private func checkIfUserHasRated(ratings: [RatingResponse]) async {
        // Récupérer les informations de l'utilisateur connecté
        do {
            let userLight = try await profileAPIService.getUserLight()
            let currentUserFirstName = userLight.firstName
            let currentUserLastName = userLight.lastName
            
            // Vérifier si l'un des avis a été laissé par l'utilisateur connecté
            hasUserRated = ratings.contains { rating in
                guard let rater = rating.rater else { return false }
                return rater.firstName == currentUserFirstName && rater.lastName == currentUserLastName
            }
        } catch {
            print("Erreur lors de la vérification si l'utilisateur a déjà noté: \(error)")
            // En cas d'erreur, on suppose qu'il n'a pas encore noté
            hasUserRated = false
        }
    }
    
    private func loadActiveOffers(professionalId: Int) async {
        do {
            // Charger les offres actives depuis l'API
            let offersResponse = try await offersAPIService.getActiveOffersByProfessional(professionalId: professionalId)
            
            // Convertir les réponses en modèles Offer
            currentOffers = offersResponse.map { $0.toOffer() }
        } catch {
            print("Erreur lors du chargement des offres actives: \(error)")
            // En cas d'erreur, utiliser les données mockées en fallback
            currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
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
                    establishmentImageUrl: partner.establishmentImageUrl,
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
                establishmentImageUrl: partner.establishmentImageUrl,
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
            establishmentImageUrl: partner.establishmentImageUrl,
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
                    establishmentImageUrl: partner.establishmentImageUrl,
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
        guard let instagram = partner.instagram else {
            return
        }
        
        // Formater l'URL Instagram : si c'est déjà une URL complète, l'utiliser, sinon construire l'URL
        let instagramURL: String
        if instagram.hasPrefix("http://") || instagram.hasPrefix("https://") {
            instagramURL = instagram
        } else if instagram.hasPrefix("@") {
            // Format @username -> https://instagram.com/username
            let username = String(instagram.dropFirst())
            instagramURL = "https://instagram.com/\(username)"
        } else {
            // Format username -> https://instagram.com/username
            instagramURL = "https://instagram.com/\(instagram)"
        }
        
        guard let url = URL(string: instagramURL) else {
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
    
    func submitRating(_ rating: Int, comment: String? = nil) {
        // Vérifier que l'utilisateur est connecté
        guard LoginViewModel.isLoggedIn() else {
            print("[PartnerDetailViewModel] ❌ Impossible de soumettre l'avis : utilisateur non connecté")
            return
        }
        
        // Vérifier que l'utilisateur a un statut CLIENT ou PRO
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? ""
        guard userTypeString == "CLIENT" || userTypeString == "PRO" else {
            print("[PartnerDetailViewModel] ❌ Impossible de soumettre l'avis : utilisateur n'a pas le statut CLIENT ou PRO (statut actuel: \(userTypeString))")
            return
        }
        
        guard let apiId = partner.apiId else {
            print("[PartnerDetailViewModel] ❌ Impossible de soumettre l'avis : pas d'ID API pour le partenaire")
            return
        }
        
        Task {
            do {
                print("[PartnerDetailViewModel] 📝 Création de l'avis pour le professionnel ID: \(apiId), score: \(rating)")
                
                // Soumettre l'avis via l'API POST /api/v1/ratings
                // Le backend renvoie immédiatement l'objet complet de l'avis créé
                let ratingResponse = try await ratingsAPIService.createRating(
                    ratedId: apiId,
                    score: rating,
                    comment: comment
                )
                
                print("[PartnerDetailViewModel] ✅ Avis créé avec succès: ID \(ratingResponse.id)")
                
                // Ajouter directement l'avis à la liste locale (mise à jour instantanée)
                let newReview = ratingResponse.toReview()
                reviews.append(newReview)
                
                // Mettre à jour hasUserRated pour masquer le bouton "Laisser un avis"
                hasUserRated = true
                
                // Mettre à jour la note moyenne depuis l'API
                do {
                    let averageRating = try await ratingsAPIService.getAverageRating(userId: apiId)
                    let reviewCount = reviews.count
                    
                    // Mettre à jour le partenaire avec la nouvelle note moyenne et le nombre d'avis
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
                        rating: averageRating,
                        reviewCount: reviewCount,
                        discount: partner.discount,
                        imageName: partner.imageName,
                        headerImageName: partner.headerImageName,
                        establishmentImageUrl: partner.establishmentImageUrl,
                        isFavorite: partner.isFavorite,
                        apiId: partner.apiId
                    )
                    
                    print("[PartnerDetailViewModel] ✅ Note moyenne mise à jour: \(averageRating), nombre d'avis: \(reviewCount)")
                } catch {
                    print("[PartnerDetailViewModel] ⚠️ Erreur lors de la mise à jour de la note moyenne: \(error)")
                    // On continue quand même, l'avis a été ajouté à la liste
                }
                
                print("[PartnerDetailViewModel] ✅ Avis ajouté à la liste, mise à jour instantanée effectuée")
            } catch {
                print("[PartnerDetailViewModel] ❌ Erreur lors de la soumission de l'avis: \(error)")
            }
        }
    }
}

