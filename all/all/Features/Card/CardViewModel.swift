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
    private let cacheService = CacheService.shared
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
        isLoading = true
        errorMessage = nil
        
        // Charger depuis le cache d'abord si disponible et pas de rafraîchissement forcé
        if !forceRefresh, let cachedCardData = cacheService.getCardData() {
            print("[CardViewModel] Chargement depuis le cache")
            cardNumber = cachedCardData.cardNumber
            cardType = cachedCardData.cardType
            isCardActive = cachedCardData.isCardActive
            cardExpirationDate = cachedCardData.cardExpirationDate
            isMember = cachedCardData.isMember
            referralCode = cachedCardData.referralCode
            referralLink = cachedCardData.referralLink
            savings = cachedCardData.savings
            referrals = cachedCardData.referrals
            wallet = cachedCardData.wallet
            favoritesCount = cachedCardData.favoritesCount
            
            // Charger les données utilisateur depuis le cache profil
            if let cachedProfile = cacheService.getProfile() {
                user = User(
                    firstName: cachedProfile.firstName,
                    lastName: cachedProfile.lastName,
                    username: cachedProfile.firstName.lowercased(),
                    bio: (cachedProfile.isMember ?? false) ? "Membre CLUB10" : "",
                    profileImageName: "person.circle.fill",
                    publications: 0,
                    subscribers: 0,
                    subscriptions: 0
                )
            }
            
            hasLoadedOnce = true
            isLoading = false
            
            // Charger les savings depuis l'API et rafraîchir en arrière-plan
            Task {
                loadSavings()
                await refreshCardData()
            }
            return
        }
        
        Task {
            do {
                // Charger les données complètes depuis /users/me pour avoir le type de carte
                let userMe = try await profileAPIService.getUserMe()
                
                // Charger aussi les données light pour les autres infos
                let userLight = try await profileAPIService.getUserLight()
                
                // Sauvegarder le profil en cache
                cacheService.saveProfile(userLight)
                
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
                cardNumber = userMe.card?.cardNumber ?? userLight.card?.cardNumber
                cardType = userMe.card?.type ?? userLight.card?.type
                
                // Log pour debug
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
                if cardType == "FAMILY" || cardType == "CLIENT_FAMILY" {
                    await loadCardOwner()
                }
                
                // Sauvegarder les données de carte en cache
                let cardCacheData = CardCacheData(
                    cardNumber: cardNumber,
                    cardType: cardType,
                    isCardActive: isCardActive,
                    cardExpirationDate: cardExpirationDate,
                    isMember: isMember,
                    referralCode: referralCode,
                    referralLink: referralLink,
                    savings: savings,
                    referrals: referrals,
                    wallet: wallet,
                    favoritesCount: favoritesCount
                )
                cacheService.saveCardData(cardCacheData)
                
                // Charger les partenaires favoris depuis l'API
                await loadFavoritePartners()
                
                hasLoadedOnce = true
                isLoading = false
            } catch {
                hasLoadedOnce = true
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des données de la carte: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
                favoritesCount = favoritePartners.count
            }
        }
    }
    
    private func refreshCardData() async {
        do {
            let userMe = try await profileAPIService.getUserMe()
            let userLight = try await profileAPIService.getUserLight()
            
            // Sauvegarder le profil en cache
            cacheService.saveProfile(userLight)
            
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
                let savingsResponse = try await savingsAPIService.getSavings()
                let savingsEntries = savingsResponse.map { $0.toSavingsEntry() }
                currentSavings = savingsEntries.reduce(0) { $0 + $1.amount }
            } catch {
                print("[CardViewModel] Erreur lors du chargement des savings en rafraîchissement: \(error)")
            }
            
            let cardCacheData = CardCacheData(
                cardNumber: cardNumberValue,
                cardType: cardTypeValue,
                isCardActive: isCardActiveValue,
                cardExpirationDate: nil, // Peut être ajouté si nécessaire
                isMember: userLight.isMember ?? false,
                referralCode: referralCodeValue,
                referralLink: referralLinkValue,
                savings: currentSavings,
                referrals: userLight.referralCount ?? 0,
                wallet: userLight.walletBalance ?? 0.0,
                favoritesCount: userLight.favoriteCount ?? 0
            )
            cacheService.saveCardData(cardCacheData)
            
            // Si c'est une carte FAMILY ou CLIENT_FAMILY, vérifier si l'utilisateur est propriétaire
            if cardTypeValue == "FAMILY" || cardTypeValue == "CLIENT_FAMILY" {
                await loadCardOwner()
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
            print("[CardViewModel] Erreur lors du rafraîchissement en arrière-plan: \(error)")
        }
    }
    
    private func loadCardOwner() async {
        do {
            let cardOwnerResponse = try await subscriptionsAPIService.getCardOwner()
            await MainActor.run {
                isCardOwner = cardOwnerResponse.isOwner
                print("[CardViewModel] User is card owner: \(isCardOwner)")
            }
        } catch {
            // Si c'est une erreur unauthorized, c'est probablement que l'utilisateur n'a pas de carte famille
            // ou n'a pas les permissions. On ignore silencieusement.
            if let apiError = error as? APIError,
               case .unauthorized = apiError {
                print("[CardViewModel] Utilisateur non autorisé pour vérifier le propriétaire de la carte (probablement pas de carte famille)")
                await MainActor.run {
                    isCardOwner = false
                }
            } else {
                print("[CardViewModel] Erreur lors de la vérification du propriétaire de la carte: \(error)")
                await MainActor.run {
                    isCardOwner = false
                }
            }
        }
    }
    
    private func loadFavoritePartners() async {
        do {
            // Charger les favoris depuis l'API
            let favoritesResponse = try await favoritesAPIService.getFavorites()
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
        } catch {
            print("Erreur lors du chargement des favoris: \(error)")
            // En cas d'erreur, utiliser les données mockées en fallback
            favoritePartners = dataService.getPartners().filter { $0.isFavorite }
            favoritesCount = favoritePartners.count
        }
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
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Charger depuis l'API
                let savingsResponse = try await savingsAPIService.getSavings()
                savingsEntries = savingsResponse.map { $0.toSavingsEntry() }
                updateSavingsTotal()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des économies: \(error)")
                
                // En cas d'erreur, charger depuis UserDefaults en fallback
                if let data = UserDefaults.standard.data(forKey: "savings_entries"),
                   let decoded = try? JSONDecoder().decode([SavingsEntry].self, from: data) {
                    savingsEntries = decoded
                    updateSavingsTotal()
                } else {
                    savings = 0.0
                }
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

