//
//  ProfileViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

enum ProfileSpace {
    case client
    case pro
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var favoritePartners: [Partner] = []
    @Published var currentSpace: ProfileSpace = .client
    
    // Données abonnement PRO
    @Published var nextPaymentDate: String = "15/02/2026"
    @Published var commitmentUntil: String = "15/02/2027"
    
    // Données abonnement CLUB10 (client)
    @Published var club10NextPaymentDate: String = ""
    @Published var club10CommitmentUntil: String = ""
    @Published var club10Amount: String = ""
    @Published var hasActiveClub10Subscription: Bool = false
    @Published var subscriptionPlan: SubscriptionPlanResponse?
    @Published var cardType: String? // "INDIVIDUAL" ou "FAMILY"
    @Published var isCardOwner: Bool = false
    @Published var familyCardEmails: [String] = []
    
    // Abonnement PRO
    @Published var hasActiveProSubscription: Bool = false
    
    // Offres PRO
    @Published var myOffers: [Offer] = []
    @Published var isLoadingFavorites: Bool = false
    @Published var favoritesError: String?
    
    private let favoritesAPIService: FavoritesAPIService
    private let partnersAPIService: PartnersAPIService
    private let profileAPIService: ProfileAPIService
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService
    
    init(
        favoritesAPIService: FavoritesAPIService? = nil,
        partnersAPIService: PartnersAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil,
        subscriptionsAPIService: SubscriptionsAPIService? = nil,
        offersAPIService: OffersAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
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
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
        
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        
        self.dataService = dataService
        
        // Récupérer les données utilisateur depuis UserDefaults
        let firstName = UserDefaults.standard.string(forKey: "user_first_name") ?? "Marie"
        let lastName = UserDefaults.standard.string(forKey: "user_last_name") ?? "Dupont"
        let email = UserDefaults.standard.string(forKey: "user_email") ?? "marie@email.fr"
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
        let userType = userTypeString == "PRO" ? UserType.pro : UserType.client
        
        self.user = User(
            firstName: firstName,
            lastName: lastName,
            username: email.components(separatedBy: "@").first ?? "user",
            bio: "Membre CLUB10",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0,
            userType: userType
        )
        
        // Si PRO, commencer en espace PRO
        if user.userType == .pro {
            currentSpace = .pro
        }
        
        loadSubscriptionData()
        loadFavorites()
        loadMyOffers()
    }
    
    func loadFavorites() {
        isLoadingFavorites = true
        favoritesError = nil
        
        Task {
            do {
                // Charger les favoris depuis l'API
                let favoritesResponse = try await favoritesAPIService.getFavorites()
                
                // Convertir en modèles Partner et marquer comme favoris
                favoritePartners = favoritesResponse.map { response in
                    let basePartner = response.toPartner()
                    // Créer une nouvelle instance avec isFavorite = true
                    return Partner(
                        id: basePartner.id,
                        name: basePartner.name,
                        category: basePartner.category,
                        address: basePartner.address,
                        city: basePartner.city,
                        postalCode: basePartner.postalCode,
                        phone: basePartner.phone,
                        email: basePartner.email,
                        website: basePartner.website,
                        instagram: basePartner.instagram,
                        description: basePartner.description,
                        rating: basePartner.rating,
                        reviewCount: basePartner.reviewCount,
                        discount: basePartner.discount,
                        imageName: basePartner.imageName,
                        headerImageName: basePartner.headerImageName,
                        isFavorite: true, // Les favoris récupérés depuis l'API sont forcément favoris
                        apiId: basePartner.apiId
                    )
                }
                
                isLoadingFavorites = false
            } catch {
                isLoadingFavorites = false
                favoritesError = error.localizedDescription
                print("Erreur lors du chargement des favoris: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
            }
        }
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, utiliser le fallback local
            dataService.togglePartnerFavorite(partnerId: partner.id)
            loadFavorites()
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
                
                // Recharger les favoris depuis l'API
                loadFavorites()
            } catch {
                print("Erreur lors de la modification du favori: \(error)")
                // En cas d'erreur, utiliser le fallback local
                dataService.togglePartnerFavorite(partnerId: partner.id)
                loadFavorites()
            }
        }
    }
    
    func loadMyOffers() {
        Task { @MainActor in
            do {
                // Appeler l'API pour récupérer les offres du professionnel connecté
                let offersResponse = try await offersAPIService.getMyOffers()
                
                // Convertir les réponses en modèles Offer
                myOffers = offersResponse.map { $0.toOffer() }
            } catch {
                print("Erreur lors du chargement de mes offres: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                myOffers = dataService.getAllOffers()
            }
        }
    }
    
    func switchToClientSpace() {
        // Ne permettre le changement d'espace que pour les professionnels
        guard user.userType == .pro else { return }
        currentSpace = .client
        // Recharger les favoris quand on passe en espace client
        loadFavorites()
    }
    
    func switchToProSpace() {
        // Ne permettre le changement d'espace que pour les professionnels
        guard user.userType == .pro else { return }
        currentSpace = .pro
        // Recharger les offres quand on passe en espace pro
        loadMyOffers()
    }
    
    func loadSubscriptionData() {
        Task {
            do {
                // Charger les données light depuis l'API
                let userLight = try await profileAPIService.getUserLight()
                
                // Mettre à jour les informations de la carte
                cardType = userLight.card?.type
                hasActiveClub10Subscription = userLight.isCardActive ?? false
                
                // Mettre à jour les dates d'abonnement
                if let renewalDate = userLight.renewalDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    if let date = dateFormatter.date(from: renewalDate) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "dd/MM/yyyy"
                        club10NextPaymentDate = displayFormatter.string(from: date)
                    } else {
                        // Essayer un autre format
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: renewalDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "dd/MM/yyyy"
                            club10NextPaymentDate = displayFormatter.string(from: date)
                        }
                    }
                }
                
                if let subscriptionAmount = userLight.subscriptionAmount {
                    club10Amount = String(format: "%.2f€", subscriptionAmount)
                }
                
                // Si c'est une carte FAMILY, charger les emails
                if cardType == "FAMILY" {
                    await loadFamilyCardEmails()
                }
            } catch {
                print("Erreur lors du chargement des données d'abonnement: \(error)")
                // En cas d'erreur, utiliser les données UserDefaults comme fallback
                loadSubscriptionDataFromDefaults()
            }
        }
    }
    
    private func loadSubscriptionDataFromDefaults() {
        hasActiveClub10Subscription = false
        hasActiveProSubscription = false
        
        if let hasActiveSubscription = UserDefaults.standard.object(forKey: "has_active_subscription") as? Bool, hasActiveSubscription {
            if let subscriptionType = UserDefaults.standard.string(forKey: "subscription_type") {
                if subscriptionType == "CLUB10" {
                    hasActiveClub10Subscription = true
                    if let nextPaymentDate = UserDefaults.standard.string(forKey: "subscription_next_payment_date") {
                        club10NextPaymentDate = nextPaymentDate
                    }
                } else if subscriptionType == "PRO" {
                    hasActiveProSubscription = true
                    if let nextPaymentDateString = UserDefaults.standard.string(forKey: "subscription_next_payment_date") {
                        self.nextPaymentDate = nextPaymentDateString
                    }
                }
            }
        }
    }
    
    private func loadFamilyCardEmails() async {
        do {
            let familyEmails = try await subscriptionsAPIService.getFamilyCardEmails()
            isCardOwner = familyEmails.isOwner
            familyCardEmails = familyEmails.emails
        } catch {
            print("Erreur lors du chargement des emails de la carte famille: \(error)")
        }
    }
    
    func updateFamilyCardEmails(_ emails: [String]) async throws {
        let request = UpdateFamilyCardEmailsRequest(emails: emails)
        try await subscriptionsAPIService.updateFamilyCardEmails(request)
        // Recharger les emails après mise à jour
        await loadFamilyCardEmails()
    }
    
    func reset() {
        // Réinitialiser l'état lors de la déconnexion
        favoritePartners = []
        myOffers = []
        currentSpace = .client
        hasActiveClub10Subscription = false
        hasActiveProSubscription = false
        
        // Réinitialiser l'utilisateur avec des valeurs par défaut
        let userType = UserDefaults.standard.string(forKey: "user_type") == "PRO" ? UserType.pro : UserType.client
        
        self.user = User(
            firstName: "",
            lastName: "",
            username: "",
            bio: "",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0,
            userType: userType
        )
    }
}

