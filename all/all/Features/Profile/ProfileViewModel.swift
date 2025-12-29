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
    @Published var cardType: String? // "PROFESSIONAL", "CLIENT_INDIVIDUAL", "CLIENT_FAMILY", "INDIVIDUAL" (ancien), "FAMILY" (ancien)
    @Published var isCardOwner: Bool = false
    @Published var familyCardEmails: [String] = []
    
    // Helper pour formater le type de carte pour l'affichage
    var formattedCardType: String {
        guard let cardType = cardType else { return "N/A" }
        switch cardType {
        case "PROFESSIONAL":
            return "Professionnelle"
        case "CLIENT_INDIVIDUAL", "INDIVIDUAL":
            return "Individuelle"
        case "CLIENT_FAMILY", "FAMILY":
            return "Famille"
        default:
            return cardType
        }
    }
    
    // Abonnement PRO
    @Published var hasActiveProSubscription: Bool = false
    
    // Offres PRO
    @Published var myOffers: [Offer] = []
    @Published var isLoadingFavorites: Bool = false
    @Published var favoritesError: String?
    
    // État de chargement initial
    @Published var isLoadingInitialData: Bool = true
    @Published var hasLoadedOnce: Bool = false // Pour savoir si on a déjà chargé une fois
    
    private let favoritesAPIService: FavoritesAPIService
    private let partnersAPIService: PartnersAPIService
    private let profileAPIService: ProfileAPIService
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let offersAPIService: OffersAPIService
    private let dataService: MockDataService
    private let cacheService = CacheService.shared
    
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
        
        // Initialiser avec des valeurs vides pour éviter d'afficher des données fake
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
        let userType = userTypeString == "PRO" ? UserType.pro : UserType.client
        
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
        
        // Si PRO, commencer en espace PRO
        if user.userType == .pro {
            currentSpace = .pro
        }
        
        // Charger toutes les données depuis l'API
        loadInitialData()
    }
    
    func loadInitialData() {
        isLoadingInitialData = true
        
        Task {
            // Charger les données en parallèle
            async let subscriptionTask: Void = loadSubscriptionData()
            async let favoritesTask: Void = loadFavorites()
            
            // Attendre que les données soient chargées
            await subscriptionTask
            await favoritesTask
            
            // Charger les offres (pas async, donc on l'appelle directement)
            loadMyOffers()
            
            hasLoadedOnce = true
            isLoadingInitialData = false
        }
    }
    
    func loadFavorites() async {
        isLoadingFavorites = true
        favoritesError = nil
        
        do {
            // Charger les favoris depuis l'API
            print("Chargement des favoris depuis l'API...")
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            print("\(favoritesResponse.count) favoris récupérés")
            
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
            
            // Vérifier si c'est une erreur de décodage JSON corrompu
            if let apiError = error as? APIError,
               case .decodingError(let underlyingError) = apiError,
               let nsError = underlyingError as NSError?,
               nsError.domain == NSCocoaErrorDomain,
               nsError.code == 3840 {
                // Erreur de décodage JSON corrompu - utiliser données mockées sans afficher d'erreur
                print("Erreur de décodage JSON lors du chargement des favoris, utilisation des données mockées")
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
                favoritesError = nil // Ne pas afficher d'erreur pour les réponses corrompues
            } else {
                // Autre type d'erreur - afficher le message
                if let apiError = error as? APIError {
                    switch apiError {
                    case .networkError:
                        favoritesError = "Problème de connexion. Vérifiez votre connexion internet."
                    case .unauthorized:
                        favoritesError = "Vous devez être connecté pour voir vos favoris"
                    case .decodingError:
                        // Erreur de décodage - probablement un problème côté backend
                        favoritesError = "Impossible de charger les favoris. Veuillez réessayer plus tard."
                    default:
                        favoritesError = "Erreur lors du chargement des favoris"
                    }
                } else {
                    favoritesError = "Erreur lors du chargement des favoris"
                }
                print("Erreur lors du chargement des favoris: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
            }
        }
    }
    
    func togglePartnerFavorite(for partner: Partner) {
        guard let apiId = partner.apiId else {
            print("⚠️ Erreur: Pas d'ID API pour le partenaire \(partner.name)")
            favoritesError = "Impossible de modifier ce favori (ID manquant)"
            return
        }
        
        isLoadingFavorites = true
        favoritesError = nil
        
        Task {
            do {
                if partner.isFavorite {
                    // Retirer des favoris
                    print("🗑️ Retrait du favori avec ID: \(apiId)")
                    try await favoritesAPIService.removeFavorite(professionalId: apiId)
                } else {
                    // Ajouter aux favoris
                    print("➕ Ajout du favori avec ID: \(apiId)")
                    try await favoritesAPIService.addFavorite(professionalId: apiId)
                }
                
                // Recharger les favoris depuis l'API après un court délai
                print("✅ Favori modifié avec succès, rechargement...")
                // Attendre un peu pour que le backend traite la requête
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                await loadFavorites()
            } catch {
                isLoadingFavorites = false
                print("❌ Erreur lors de la modification du favori: \(error)")
                
                // Afficher un message d'erreur user-friendly
                if let apiError = error as? APIError {
                    switch apiError {
                    case .networkError:
                        favoritesError = "Problème de connexion. Vérifiez votre connexion internet."
                    case .unauthorized:
                        favoritesError = "Vous devez être connecté pour modifier vos favoris"
                    default:
                        favoritesError = "Erreur lors de la modification du favori"
                    }
                } else {
                    favoritesError = "Erreur lors de la modification du favori: \(error.localizedDescription)"
                }
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
        Task {
            await loadFavorites()
        }
    }
    
    func switchToProSpace() {
        // Ne permettre le changement d'espace que pour les professionnels
        guard user.userType == .pro else { return }
        currentSpace = .pro
        // Recharger les offres quand on passe en espace pro
        loadMyOffers()
    }
    
    func loadSubscriptionData(forceRefresh: Bool = false) async {
        // Charger depuis le cache d'abord si disponible et pas de rafraîchissement forcé
        if !forceRefresh, let cachedProfile = cacheService.getProfile() {
            print("[ProfileViewModel] Chargement depuis le cache")
            user = User(
                firstName: cachedProfile.firstName,
                lastName: cachedProfile.lastName,
                username: cachedProfile.firstName.lowercased(),
                bio: (cachedProfile.isMember ?? false) ? "Membre CLUB10" : "",
                profileImageName: user.profileImageName,
                publications: user.publications,
                subscribers: user.subscribers,
                subscriptions: user.subscriptions,
                userType: user.userType
            )
            cardType = cachedProfile.card?.type
            hasActiveClub10Subscription = cachedProfile.isCardActive ?? false
            
            // Mettre à jour les dates d'abonnement depuis le cache
            if let renewalDate = cachedProfile.renewalDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = dateFormatter.date(from: renewalDate) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "dd/MM/yyyy"
                    club10NextPaymentDate = displayFormatter.string(from: date)
                } else {
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    if let date = dateFormatter.date(from: renewalDate) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "dd/MM/yyyy"
                        club10NextPaymentDate = displayFormatter.string(from: date)
                    } else {
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: renewalDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "dd/MM/yyyy"
                            club10NextPaymentDate = displayFormatter.string(from: date)
                        }
                    }
                }
            }
            
            // Rafraîchir en arrière-plan
            Task {
                await refreshProfileData()
            }
            return
        }
        
        do {
            // Charger les données light depuis l'API
            let userLight = try await profileAPIService.getUserLight()
            
            // Sauvegarder en cache
            cacheService.saveProfile(userLight)
            
            // Mettre à jour le prénom et nom depuis le backend
            user = User(
                firstName: userLight.firstName,
                lastName: userLight.lastName,
                username: userLight.firstName.lowercased(),
                bio: (userLight.isMember ?? false) ? "Membre CLUB10" : "",
                profileImageName: user.profileImageName,
                publications: user.publications,
                subscribers: user.subscribers,
                subscriptions: user.subscriptions,
                userType: user.userType
            )
            
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
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    if let date = dateFormatter.date(from: renewalDate) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "dd/MM/yyyy"
                        club10NextPaymentDate = displayFormatter.string(from: date)
                    } else {
                        // Essayer format simple
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: renewalDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "dd/MM/yyyy"
                            club10NextPaymentDate = displayFormatter.string(from: date)
                        }
                    }
                }
            }
            
            if let subscriptionAmount = userLight.subscriptionAmount {
                club10Amount = String(format: "%.2f€", subscriptionAmount)
            }
            
            // Si c'est une carte FAMILY ou CLIENT_FAMILY, charger les emails
            if cardType == "FAMILY" || cardType == "CLIENT_FAMILY" {
                await loadFamilyCardEmails()
            }
        } catch {
            print("Erreur lors du chargement des données d'abonnement: \(error)")
            // En cas d'erreur, utiliser les données UserDefaults comme fallback
            loadSubscriptionDataFromDefaults()
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
    
    private func refreshProfileData() async {
        do {
            let userLight = try await profileAPIService.getUserLight()
            
            // Sauvegarder en cache
            cacheService.saveProfile(userLight)
            
            // Mettre à jour les données en arrière-plan
            await MainActor.run {
                user = User(
                    firstName: userLight.firstName,
                    lastName: userLight.lastName,
                    username: userLight.firstName.lowercased(),
                    bio: (userLight.isMember ?? false) ? "Membre CLUB10" : "",
                    profileImageName: user.profileImageName,
                    publications: user.publications,
                    subscribers: user.subscribers,
                    subscriptions: user.subscriptions,
                    userType: user.userType
                )
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
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                        if let date = dateFormatter.date(from: renewalDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "dd/MM/yyyy"
                            club10NextPaymentDate = displayFormatter.string(from: date)
                        } else {
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            if let date = dateFormatter.date(from: renewalDate) {
                                let displayFormatter = DateFormatter()
                                displayFormatter.dateFormat = "dd/MM/yyyy"
                                club10NextPaymentDate = displayFormatter.string(from: date)
                            }
                        }
                    }
                }
                
                if let subscriptionAmount = userLight.subscriptionAmount {
                    club10Amount = String(format: "%.2f€", subscriptionAmount)
                }
            }
        } catch {
            print("[ProfileViewModel] Erreur lors du rafraîchissement en arrière-plan: \(error)")
        }
    }
    
    private func loadFamilyCardEmails() async {
        do {
            let familyEmails = try await subscriptionsAPIService.getFamilyCardEmails()
            isCardOwner = familyEmails.isOwner
            familyCardEmails = familyEmails.emails
        } catch {
            // Si c'est une erreur unauthorized, c'est probablement que l'utilisateur n'a pas de carte famille
            // ou n'a pas les permissions. On ignore silencieusement.
            if let apiError = error as? APIError,
               case .unauthorized = apiError {
                print("Utilisateur non autorisé pour charger les emails de la carte famille (probablement pas de carte famille)")
                // Réinitialiser les valeurs par défaut
                isCardOwner = false
                familyCardEmails = []
            } else {
                print("Erreur lors du chargement des emails de la carte famille: \(error)")
                // Réinitialiser les valeurs par défaut en cas d'erreur
                isCardOwner = false
                familyCardEmails = []
            }
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
        nextPaymentDate = ""
        commitmentUntil = ""
        club10NextPaymentDate = ""
        club10CommitmentUntil = ""
        club10Amount = ""
        cardType = nil
        isCardOwner = false
        familyCardEmails = []
        subscriptionPlan = nil
        
        // Réinitialiser l'utilisateur avec des valeurs par défaut
        self.user = User(
            firstName: "",
            lastName: "",
            username: "",
            bio: "",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0,
            userType: .client // Par défaut, on remet en client
        )
    }
}

