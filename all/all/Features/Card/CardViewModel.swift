//
//  CardViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class CardViewModel: ObservableObject {
    @Published var user: User
    @Published var savings: Double = 128.0
    @Published var savingsEntries: [SavingsEntry] = []
    @Published var referrals: Int = 0
    @Published var wallet: Double = 15.0
    @Published var favoritesCount: Int = 0
    @Published var favoritePartners: [Partner] = []
    @Published var referralCode: String = ""
    @Published var referralLink: String = ""
    
    // Données depuis l'API
    @Published var isMember: Bool = false
    @Published var cardNumber: String? = nil
    @Published var cardType: String? = nil
    @Published var isCardActive: Bool = false
    @Published var cardExpirationDate: Date? = nil
    @Published var isCardOwner: Bool = false
    
    @Published var isLoading: Bool = true // Commencer en état de chargement
    @Published var hasLoadedOnce: Bool = false // Pour savoir si on a déjà chargé une fois
    @Published var errorMessage: String?
    
    private let profileAPIService: ProfileAPIService
    private let favoritesAPIService: FavoritesAPIService
    private let savingsAPIService: SavingsAPIService
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let dataService: MockDataService // Gardé pour les favoris en fallback
    private var cancellables = Set<AnyCancellable>()
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        favoritesAPIService: FavoritesAPIService? = nil,
        savingsAPIService: SavingsAPIService? = nil,
        subscriptionsAPIService: SubscriptionsAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        // Créer les services dans un contexte MainActor
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        if let favoritesAPIService = favoritesAPIService {
            self.favoritesAPIService = favoritesAPIService
        } else {
            self.favoritesAPIService = FavoritesAPIService()
        }
        
        if let savingsAPIService = savingsAPIService {
            self.savingsAPIService = savingsAPIService
        } else {
            self.savingsAPIService = SavingsAPIService()
        }
        
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
        
        self.dataService = dataService
        
        // Initialiser avec les données UserDefaults
        let firstName = UserDefaults.standard.string(forKey: "user_first_name") ?? "Marie"
        let lastName = UserDefaults.standard.string(forKey: "user_last_name") ?? "Dupont"
        let email = UserDefaults.standard.string(forKey: "user_email") ?? "marie@email.fr"
        
        self.user = User(
            firstName: firstName,
            lastName: lastName,
            username: email.components(separatedBy: "@").first ?? "user",
            bio: "Membre CLUB10",
            profileImageName: "person.circle.fill",
            publications: 0,
            subscribers: 0,
            subscriptions: 0
        )
        
        // Générer le code de parrainage depuis le nom
        self.referralCode = generateReferralCode(from: firstName, lastName: lastName)
        self.referralLink = "allin.fr/r/\(referralCode)"
        
        // Charger les données
        loadData()
        loadSavings()
        
        // Écouter les mises à jour d'abonnement
        NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionUpdated"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadData(forceRefresh: Bool = false) {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [MA CARTE] Début du chargement des données")
        print("═══════════════════════════════════════════════════════════")
        print("💳 [MA CARTE] forceRefresh: \(forceRefresh)")
        
        isLoading = true
        errorMessage = nil
        
        // Toujours charger depuis l'API (pas de cache)
        Task {
            do {
                // Charger les données complètes depuis /users/me pour avoir le type de carte
                print("💳 [MA CARTE] ───────────────────────────────────────────────────")
                print("💳 [MA CARTE] Appel API: GET /api/v1/users/me")
                print("💳 [MA CARTE] Objectif: Récupérer les données complètes de l'utilisateur")
                let startTime = Date()
                
                let userMe = try await profileAPIService.getUserMe()
                
                let duration = Date().timeIntervalSince(startTime)
                print("💳 [MA CARTE] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
                print("💳 [MA CARTE] Données reçues:")
                print("   - userId: \(userMe.id?.description ?? "nil")")
                print("   - firstName: \(userMe.firstName)")
                print("   - lastName: \(userMe.lastName)")
                print("   - city: \(userMe.city ?? "nil")")
                print("   - card: \(userMe.card != nil ? "exists" : "nil")")
                print("   - isCardActive: \(userMe.isCardActive?.description ?? "nil")")
                print("💳 [MA CARTE] ───────────────────────────────────────────────────")
                
                // Charger aussi les données light pour les autres infos
                print("💳 [MA CARTE] Appel API: GET /api/v1/users/me/light")
                print("💳 [MA CARTE] Objectif: Récupérer les données allégées (savings, referrals, etc.)")
                let startTimeLight = Date()
                
                let userLight = try await profileAPIService.getUserLight()
                
                let durationLight = Date().timeIntervalSince(startTimeLight)
                print("💳 [MA CARTE] ✅ Réponse reçue en \(String(format: "%.2f", durationLight))s")
                print("💳 [MA CARTE] Données reçues:")
                print("   - firstName: \(userLight.firstName)")
                print("   - lastName: \(userLight.lastName)")
                print("   - isMember: \(userLight.isMember?.description ?? "nil")")
                print("   - referralCount: \(userLight.referralCount?.description ?? "nil")")
                print("   - favoriteCount: \(userLight.favoriteCount?.description ?? "nil")")
                print("   - walletBalance: \(userLight.walletBalance?.description ?? "nil")")
                print("   - renewalDate: \(userLight.renewalDate ?? "nil")")
                print("   - referralCode: \(userLight.referralCode ?? "nil")")
                print("💳 [MA CARTE] ───────────────────────────────────────────────────")
                
                // Mettre à jour les données utilisateur
                let firstName = userLight.firstName.isEmpty ? (userMe.firstName.isEmpty ? "Utilisateur" : userMe.firstName) : userLight.firstName
                let lastName = userLight.lastName.isEmpty ? (userMe.lastName.isEmpty ? "" : userMe.lastName) : userLight.lastName
                
                user = User(
                    firstName: firstName,
                    lastName: lastName,
                    username: firstName.lowercased(),
                    bio: (userLight.isMember ?? false) ? "Membre CLUB10" : "",
                    profileImageName: "person.circle.fill",
                    publications: 0,
                    subscribers: 0,
                    subscriptions: 0
                )
                
                // Mettre à jour les données de la carte (utiliser userMe pour le type)
                isMember = userLight.isMember ?? false
                
                // Déterminer si la carte est active : priorité à userMe.isCardActive, sinon vérifier si card existe
                // Note: card peut être nil pour un nouvel utilisateur (normal, pas d'erreur)
                if let cardActive = userMe.isCardActive {
                    isCardActive = cardActive
                } else if let card = userMe.card, !card.cardNumber.isEmpty {
                    // Si card existe avec cardNumber, la carte est active
                    isCardActive = true
                } else {
                    // Sinon, utiliser isCardActive de userLight
                    isCardActive = userLight.isCardActive ?? false
                }
                
                // Récupérer cardNumber et cardType depuis userMe en priorité
                // Si card est nil, c'est normal pour un nouvel utilisateur (pas encore de carte générée)
                cardNumber = userMe.card?.cardNumber ?? userLight.card?.cardNumber
                cardType = userMe.card?.type ?? userLight.card?.type
                
                // Log pour debug
                if userMe.card == nil {
                    print("[CardViewModel] ℹ️ card est nil (normal pour un nouvel utilisateur sans carte générée)")
                }
                print("[CardViewModel] Carte chargée - cardNumber: \(cardNumber ?? "nil"), isCardActive: \(isCardActive), cardType: \(cardType ?? "nil")")
                print("[CardViewModel] userMe.card: \(userMe.card != nil ? "exists" : "nil"), userMe.isCardActive: \(userMe.isCardActive?.description ?? "nil")")
                
                // Récupérer la date de validité (renewalDate)
                if let renewalDateString = userLight.renewalDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    if let date = dateFormatter.date(from: renewalDateString) {
                        cardExpirationDate = date
                    } else {
                        // Essayer un autre format
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                        if let date = dateFormatter.date(from: renewalDateString) {
                            cardExpirationDate = date
                        } else {
                            // Essayer format simple
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            cardExpirationDate = dateFormatter.date(from: renewalDateString)
                        }
                    }
                }
                
                // Mettre à jour les compteurs
                referrals = userLight.referralCount ?? 0
                favoritesCount = userLight.favoriteCount ?? 0
                wallet = userLight.walletBalance ?? 0.0
                
                // Utiliser le referralCode du backend s'il existe, sinon générer un code localement
                if let backendReferralCode = userLight.referralCode, !backendReferralCode.isEmpty {
                    referralCode = backendReferralCode
                } else if let backendReferralCode = userMe.referralCode, !backendReferralCode.isEmpty {
                    referralCode = backendReferralCode
                } else {
                    // Fallback : générer le code de parrainage localement
                    let firstNameForCode = userLight.firstName.isEmpty ? (userMe.firstName.isEmpty ? "User" : userMe.firstName) : userLight.firstName
                    let lastNameForCode = userLight.lastName.isEmpty ? (userMe.lastName.isEmpty ? "Name" : userMe.lastName) : userLight.lastName
                    referralCode = generateReferralCode(from: firstNameForCode, lastName: lastNameForCode)
                }
                referralLink = "allin.fr/r/\(referralCode)"
                
                // Si c'est une carte FAMILY ou CLIENT_FAMILY, vérifier si l'utilisateur est propriétaire
                // Selon le backend : comparer userMe.id avec card.ownerId
                if cardType == "FAMILY" || cardType == "CLIENT_FAMILY" {
                    print("💳 [MA CARTE] Carte FAMILY détectée, vérification du propriétaire...")
                    if let userCard = userMe.card, let ownerId = userCard.ownerId, let userId = userMe.id {
                        // Comparer l'ID utilisateur avec ownerId de la carte
                        isCardOwner = (userId == ownerId)
                        print("💳 [MA CARTE] Comparaison ownerId:")
                        print("   - userId: \(userId)")
                        print("   - card.ownerId: \(ownerId)")
                        print("   - ownerName: \(userCard.ownerName ?? "nil")")
                        print("   - isCardOwner: \(isCardOwner)")
                    } else if let userCard = userLight.card, let ownerId = userCard.ownerId, let userId = userMe.id {
                        // Fallback avec userLight.card
                        isCardOwner = (userId == ownerId)
                        print("💳 [MA CARTE] Comparaison ownerId (via userLight):")
                        print("   - userId: \(userId)")
                        print("   - card.ownerId: \(ownerId)")
                        print("   - ownerName: \(userCard.ownerName ?? "nil")")
                        print("   - isCardOwner: \(isCardOwner)")
                    } else {
                        // Si ownerId n'est pas disponible, utiliser l'ancienne méthode en fallback
                        print("💳 [MA CARTE] ⚠️ ownerId non disponible, utilisation de l'ancienne méthode getCardOwner()")
                        await loadCardOwner()
                    }
                }
                
                // Charger les savings
                print("💳 [MA CARTE] Chargement des savings...")
                await loadSavings()
                
                // Charger les partenaires favoris depuis l'API
                print("💳 [MA CARTE] Chargement des partenaires favoris...")
                await loadFavoritePartners()
                
                print("═══════════════════════════════════════════════════════════")
                print("💳 [MA CARTE] ✅ Chargement terminé avec succès")
                print("═══════════════════════════════════════════════════════════")
                
                hasLoadedOnce = true
                isLoading = false
            } catch {
                print("═══════════════════════════════════════════════════════════")
                print("💳 [MA CARTE] ❌ ERREUR lors du chargement des données")
                print("═══════════════════════════════════════════════════════════")
                print("💳 [MA CARTE] Type d'erreur: \(type(of: error))")
                print("💳 [MA CARTE] Message: \(error.localizedDescription)")
                
                if let apiError = error as? APIError {
                    print("💳 [MA CARTE] Détails APIError:")
                    switch apiError {
                    case .unauthorized(let reason):
                        print("   - Type: unauthorized")
                        print("   - Raison: \(reason ?? "non spécifiée")")
                    case .networkError(let underlyingError):
                        print("   - Type: networkError")
                        print("   - Erreur sous-jacente: \(underlyingError.localizedDescription)")
                    case .httpError(let statusCode, let message):
                        print("   - Type: httpError")
                        print("   - Status code: \(statusCode)")
                        print("   - Message: \(message ?? "nil")")
                    case .invalidResponse:
                        print("   - Type: invalidResponse")
                    case .decodingError(let underlyingError):
                        print("   - Type: decodingError")
                        print("   - Erreur: \(underlyingError.localizedDescription)")
                    default:
                        print("   - Type: autre")
                    }
                }
                print("═══════════════════════════════════════════════════════════")
                
                hasLoadedOnce = true
                isLoading = false
                
                // Si c'est une erreur 500 ou 404, c'est probablement que l'utilisateur n'a pas de carte
                // On n'affiche pas d'erreur, on laisse afficher l'écran d'abonnement
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let statusCode, _):
                        if statusCode == 500 || statusCode == 404 {
                            print("💳 [MA CARTE] ⚠️ Erreur \(statusCode) - Pas de carte, affichage de l'écran d'abonnement")
                            // Ne pas définir errorMessage pour afficher CardSubscriptionView
                            errorMessage = nil
                            // Réinitialiser les données de carte
                            cardNumber = nil
                            isCardActive = false
                            cardType = nil
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    default:
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                // En cas d'erreur, utiliser les données mockées en fallback
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
                favoritesCount = favoritePartners.count
            }
        }
    }
    
    private func refreshCardData() async {
        print("💳 [MA CARTE] 🔄 Rafraîchissement des données en arrière-plan")
        do {
            print("💳 [MA CARTE] Appel API: GET /api/v1/users/me (refresh)")
            let startTime = Date()
            let userMe = try await profileAPIService.getUserMe()
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [MA CARTE] ✅ getUserMe() réussi en \(String(format: "%.2f", duration))s")
            
            print("💳 [MA CARTE] Appel API: GET /api/v1/users/me/light (refresh)")
            let startTimeLight = Date()
            let userLight = try await profileAPIService.getUserLight()
            let durationLight = Date().timeIntervalSince(startTimeLight)
            print("💳 [MA CARTE] ✅ getUserLight() réussi en \(String(format: "%.2f", durationLight))s")
            
            let firstName = userLight.firstName.isEmpty ? (userMe.firstName.isEmpty ? "Utilisateur" : userMe.firstName) : userLight.firstName
            let lastName = userLight.lastName.isEmpty ? (userMe.lastName.isEmpty ? "" : userMe.lastName) : userLight.lastName
            
            let isCardActiveValue: Bool
            if let cardActive = userMe.isCardActive {
                isCardActiveValue = cardActive
            } else if let card = userMe.card, !card.cardNumber.isEmpty {
                isCardActiveValue = true
            } else {
                isCardActiveValue = userLight.isCardActive ?? false
            }
            
            let cardNumberValue = userMe.card?.cardNumber ?? userLight.card?.cardNumber
            let cardTypeValue = userMe.card?.type ?? userLight.card?.type
            
            // Utiliser le referralCode du backend s'il existe, sinon générer un code localement
            let referralCodeValue: String
            if let backendReferralCode = userLight.referralCode, !backendReferralCode.isEmpty {
                referralCodeValue = backendReferralCode
            } else if let backendReferralCode = userMe.referralCode, !backendReferralCode.isEmpty {
                referralCodeValue = backendReferralCode
            } else {
                // Fallback : générer le code de parrainage localement
                let firstNameForCode = userLight.firstName.isEmpty ? (userMe.firstName.isEmpty ? "User" : userMe.firstName) : userLight.firstName
                let lastNameForCode = userLight.lastName.isEmpty ? (userMe.lastName.isEmpty ? "Name" : userMe.lastName) : userLight.lastName
                referralCodeValue = generateReferralCode(from: firstNameForCode, lastName: lastNameForCode)
            }
            let referralLinkValue = "allin.fr/r/\(referralCodeValue)"
            
            // Charger les savings pour avoir la valeur à jour
            var currentSavings = savings
            do {
                print("💳 [MA CARTE] Appel API: GET /api/v1/savings (refresh)")
                let startTimeSavings = Date()
                let savingsResponse = try await savingsAPIService.getSavings()
                let durationSavings = Date().timeIntervalSince(startTimeSavings)
                print("💳 [MA CARTE] ✅ getSavings() réussi en \(String(format: "%.2f", durationSavings))s")
                print("💳 [MA CARTE] Nombre d'entrées: \(savingsResponse.count)")
                
                let savingsEntries = savingsResponse.map { $0.toSavingsEntry() }
                currentSavings = savingsEntries.reduce(0) { $0 + $1.amount }
                print("💳 [MA CARTE] Total savings calculé: \(currentSavings)€")
            } catch {
                print("💳 [MA CARTE] ❌ Erreur lors du chargement des savings en rafraîchissement")
                print("💳 [MA CARTE] Type: \(type(of: error))")
                print("💳 [MA CARTE] Message: \(error.localizedDescription)")
            }
            
            
            // Si c'est une carte FAMILY ou CLIENT_FAMILY, vérifier si l'utilisateur est propriétaire
            // Selon le backend : comparer userMe.id avec card.ownerId
            if cardTypeValue == "FAMILY" || cardTypeValue == "CLIENT_FAMILY" {
                print("💳 [MA CARTE] Carte FAMILY détectée (refresh), vérification du propriétaire...")
                if let userCard = userMe.card, let ownerId = userCard.ownerId, let userId = userMe.id {
                    // Comparer l'ID utilisateur avec ownerId de la carte
                    let isOwner = (userId == ownerId)
                    print("💳 [MA CARTE] Comparaison ownerId (refresh):")
                    print("   - userId: \(userId)")
                    print("   - card.ownerId: \(ownerId)")
                    print("   - ownerName: \(userCard.ownerName ?? "nil")")
                    print("   - isCardOwner: \(isOwner)")
                    await MainActor.run {
                        isCardOwner = isOwner
                    }
                } else if let userCard = userLight.card, let ownerId = userCard.ownerId, let userId = userMe.id {
                    // Fallback avec userLight.card
                    let isOwner = (userId == ownerId)
                    print("💳 [MA CARTE] Comparaison ownerId (refresh via userLight):")
                    print("   - userId: \(userId)")
                    print("   - card.ownerId: \(ownerId)")
                    print("   - ownerName: \(userCard.ownerName ?? "nil")")
                    print("   - isCardOwner: \(isOwner)")
                    await MainActor.run {
                        isCardOwner = isOwner
                    }
                } else {
                    // Si ownerId n'est pas disponible, utiliser l'ancienne méthode en fallback
                    print("💳 [MA CARTE] ⚠️ ownerId non disponible (refresh), utilisation de l'ancienne méthode getCardOwner()")
                    await loadCardOwner()
                }
            }
            
            // Mettre à jour les données en arrière-plan
            await MainActor.run {
                user = User(
                    firstName: firstName,
                    lastName: lastName,
                    username: firstName.lowercased(),
                    bio: (userLight.isMember ?? false) ? "Membre CLUB10" : "",
                    profileImageName: "person.circle.fill",
                    publications: 0,
                    subscribers: 0,
                    subscriptions: 0
                )
                cardNumber = cardNumberValue
                cardType = cardTypeValue
                isCardActive = isCardActiveValue
                isMember = userLight.isMember ?? false
                referralCode = referralCodeValue
                referralLink = referralLinkValue
                referrals = userLight.referralCount ?? 0
                wallet = userLight.walletBalance ?? 0.0
                favoritesCount = userLight.favoriteCount ?? 0
                savings = currentSavings
            }
        } catch {
            print("💳 [MA CARTE] ❌ Erreur lors du rafraîchissement en arrière-plan")
            print("💳 [MA CARTE] Type: \(type(of: error))")
            print("💳 [MA CARTE] Message: \(error.localizedDescription)")
            
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized(let reason):
                    print("💳 [MA CARTE] ⚠️ Erreur 401 - Non autorisé")
                    print("💳 [MA CARTE] Raison: \(reason ?? "non spécifiée")")
                case .networkError(let underlyingError):
                    print("💳 [MA CARTE] ⚠️ Erreur réseau")
                    print("💳 [MA CARTE] Erreur sous-jacente: \(underlyingError.localizedDescription)")
                default:
                    print("💳 [MA CARTE] ⚠️ Autre erreur API")
                }
            }
        }
    }
    
    private func loadCardOwner() async {
        print("💳 [MA CARTE] ───────────────────────────────────────────────────")
        print("💳 [MA CARTE] Appel API: GET /api/v1/cards/owner")
        print("💳 [MA CARTE] Objectif: Vérifier si l'utilisateur est propriétaire de la carte famille")
        let startTime = Date()
        
        do {
            let cardOwnerResponse = try await subscriptionsAPIService.getCardOwner()
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [MA CARTE] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
            print("💳 [MA CARTE] isOwner: \(cardOwnerResponse.isOwner)")
            
            await MainActor.run {
                isCardOwner = cardOwnerResponse.isOwner
                print("💳 [MA CARTE] ✅ Propriétaire de la carte: \(isCardOwner)")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [MA CARTE] ❌ Erreur après \(String(format: "%.2f", duration))s")
            print("💳 [MA CARTE] Type: \(type(of: error))")
            print("💳 [MA CARTE] Message: \(error.localizedDescription)")
            
            // Si c'est une erreur unauthorized, c'est probablement que l'utilisateur n'a pas de carte famille
            // ou n'a pas les permissions. On ignore silencieusement.
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized(let reason):
                    print("💳 [MA CARTE] ⚠️ Erreur 401 - Non autorisé")
                    print("💳 [MA CARTE] Raison: \(reason ?? "non spécifiée")")
                    print("💳 [MA CARTE] → Probablement pas de carte famille ou pas les permissions")
                case .notFound:
                    print("💳 [MA CARTE] ⚠️ Erreur 404 - Carte non trouvée")
                default:
                    print("💳 [MA CARTE] ⚠️ Autre erreur API")
                }
            }
            
            await MainActor.run {
                isCardOwner = false
            }
        }
        print("💳 [MA CARTE] ───────────────────────────────────────────────────")
    }
    
    private func loadFavoritePartners() async {
        print("💳 [MA CARTE] ───────────────────────────────────────────────────")
        print("💳 [MA CARTE] Appel API: GET /api/v1/favorites")
        print("💳 [MA CARTE] Objectif: Récupérer les partenaires favoris")
        let startTime = Date()
        
        do {
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [MA CARTE] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
            print("💳 [MA CARTE] Nombre de favoris: \(favoritesResponse.count)")
            
            // Marquer tous les favoris comme favoris
            favoritePartners = favoritesResponse.map { response in
                let basePartner = response.toPartner()
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
            // Mettre à jour le compteur
            favoritesCount = favoritePartners.count
            print("💳 [MA CARTE] ✅ \(favoritesCount) partenaires favoris chargés")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("💳 [MA CARTE] ❌ Erreur après \(String(format: "%.2f", duration))s")
            print("💳 [MA CARTE] Type: \(type(of: error))")
            print("💳 [MA CARTE] Message: \(error.localizedDescription)")
            
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized(let reason):
                    print("💳 [MA CARTE] ⚠️ Erreur 401 - Non autorisé")
                    print("💳 [MA CARTE] Raison: \(reason ?? "non spécifiée")")
                case .notFound:
                    print("💳 [MA CARTE] ⚠️ Erreur 404 - Favoris non trouvés")
                default:
                    print("💳 [MA CARTE] ⚠️ Autre erreur API")
                }
            }
            
            // En cas d'erreur, utiliser les données mockées en fallback
            favoritePartners = dataService.getPartners().filter { $0.isFavorite }
            favoritesCount = favoritePartners.count
            print("💳 [MA CARTE] ⚠️ Utilisation de données mockées en fallback: \(favoritesCount) favoris")
        }
        print("💳 [MA CARTE] ───────────────────────────────────────────────────")
    }
    
    func removeFavorite(partner: Partner) {
        guard let apiId = partner.apiId else {
            // Si pas d'ID API, retirer localement seulement
            favoritePartners.removeAll { $0.id == partner.id }
            favoritesCount = favoritePartners.count
            return
        }
        
        Task {
            do {
                // Appeler l'API pour retirer des favoris
                try await favoritesAPIService.removeFavorite(professionalId: apiId)
                
                // Retirer de la liste locale
                favoritePartners.removeAll { $0.id == partner.id }
                favoritesCount = favoritePartners.count
            } catch {
                print("Erreur lors de la suppression du favori: \(error)")
                errorMessage = "Erreur lors de la suppression du favori"
                
                // En cas d'erreur, retirer localement quand même
                favoritePartners.removeAll { $0.id == partner.id }
                favoritesCount = favoritePartners.count
            }
        }
    }
    
    private func generateReferralCode(from firstName: String, lastName: String) -> String {
        let firstPart = firstName.prefix(3).uppercased()
        let secondPart = lastName.prefix(3).uppercased()
        let year = Calendar.current.component(.year, from: Date())
        return "\(firstPart)\(secondPart)\(year)"
    }
    
    func copyReferralLink() {
        UIPasteboard.general.string = referralLink
    }
    
    // MARK: - Savings Management
    func loadSavings() {
        print("💳 [MA CARTE] ───────────────────────────────────────────────────")
        print("💳 [MA CARTE] Appel API: GET /api/v1/savings")
        print("💳 [MA CARTE] Objectif: Récupérer les économies de l'utilisateur")
        let startTime = Date()
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let savingsResponse = try await savingsAPIService.getSavings()
                let duration = Date().timeIntervalSince(startTime)
                print("💳 [MA CARTE] ✅ Réponse reçue en \(String(format: "%.2f", duration))s")
                print("💳 [MA CARTE] Nombre d'entrées: \(savingsResponse.count)")
                
                savingsEntries = savingsResponse.map { $0.toSavingsEntry() }
                updateSavingsTotal()
                
                print("💳 [MA CARTE] ✅ Total savings: \(savings)€")
                print("💳 [MA CARTE] ───────────────────────────────────────────────────")
                
                isLoading = false
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                print("💳 [MA CARTE] ❌ Erreur après \(String(format: "%.2f", duration))s")
                print("💳 [MA CARTE] Type: \(type(of: error))")
                print("💳 [MA CARTE] Message: \(error.localizedDescription)")
                
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized(let reason):
                        print("💳 [MA CARTE] ⚠️ Erreur 401 - Non autorisé")
                        print("💳 [MA CARTE] Raison: \(reason ?? "non spécifiée")")
                    case .notFound:
                        print("💳 [MA CARTE] ⚠️ Erreur 404 - Savings non trouvés")
                    default:
                        print("💳 [MA CARTE] ⚠️ Autre erreur API")
                    }
                }
                
                isLoading = false
                errorMessage = error.localizedDescription
                
                // En cas d'erreur, charger depuis UserDefaults en fallback
                if let data = UserDefaults.standard.data(forKey: "savings_entries"),
                   let decoded = try? JSONDecoder().decode([SavingsEntry].self, from: data) {
                    savingsEntries = decoded
                    updateSavingsTotal()
                    print("💳 [MA CARTE] ⚠️ Utilisation de UserDefaults en fallback: \(savingsEntries.count) entrées")
                } else {
                    savings = 0.0
                    print("💳 [MA CARTE] ⚠️ Aucune donnée en fallback, savings = 0€")
                }
                print("💳 [MA CARTE] ───────────────────────────────────────────────────")
            }
        }
    }
    
    func addSavings(amount: Double, date: Date, store: String, description: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Formater la date en ISO 8601
                let isoDateFormatter = ISO8601DateFormatter()
                isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let dateString = isoDateFormatter.string(from: date)
                
                // Créer la requête
                let request = SavingsRequest(
                    shopName: store,
                    description: description,
                    amount: amount,
                    date: dateString
                )
                
                // Appeler l'API
                let response = try await savingsAPIService.createSavings(request)
                
                // Ajouter à la liste locale
                let newEntry = response.toSavingsEntry()
                savingsEntries.append(newEntry)
                updateSavingsTotal()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de l'ajout de l'économie: \(error.localizedDescription)"
                print("Erreur lors de l'ajout de l'économie: \(error)")
            }
        }
    }
    
    func updateSavings(entry: SavingsEntry, amount: Double, date: Date, store: String, description: String? = nil) {
        guard let apiId = entry.apiId else {
            errorMessage = "Impossible de modifier cette économie"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Formater la date en ISO 8601
                let isoDateFormatter = ISO8601DateFormatter()
                isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let dateString = isoDateFormatter.string(from: date)
                
                // Créer la requête
                let request = SavingsRequest(
                    shopName: store,
                    description: description,
                    amount: amount,
                    date: dateString
                )
                
                // Appeler l'API
                let response = try await savingsAPIService.updateSavings(id: apiId, request: request)
                
                // Mettre à jour dans la liste locale
                if let index = savingsEntries.firstIndex(where: { $0.id == entry.id }) {
                    savingsEntries[index] = response.toSavingsEntry()
                    updateSavingsTotal()
                }
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de la modification de l'économie: \(error.localizedDescription)"
                print("Erreur lors de la modification de l'économie: \(error)")
            }
        }
    }
    
    func deleteSavings(entry: SavingsEntry) {
        guard let apiId = entry.apiId else {
            // Si pas d'ID API, supprimer localement seulement
            savingsEntries.removeAll { $0.id == entry.id }
            updateSavingsTotal()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Appeler l'API pour supprimer
                try await savingsAPIService.deleteSavings(id: apiId)
                
                // Retirer de la liste locale
                savingsEntries.removeAll { $0.id == entry.id }
                updateSavingsTotal()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de la suppression de l'économie: \(error.localizedDescription)"
                print("Erreur lors de la suppression de l'économie: \(error)")
            }
        }
    }
    
    private func updateSavingsTotal() {
        savings = savingsEntries.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Card Validity
    var isCardValid: Bool {
        guard let expirationDate = cardExpirationDate else {
            // Si pas de date, considérer comme valide si isCardActive
            return isCardActive
        }
        // La carte est valide si la date d'expiration est dans le futur
        return expirationDate > Date()
    }
    
    var formattedExpirationDate: String {
        guard let expirationDate = cardExpirationDate else {
            return "N/A"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: expirationDate)
    }
}

