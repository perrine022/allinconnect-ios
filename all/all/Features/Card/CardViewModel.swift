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
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let profileAPIService: ProfileAPIService
    private let favoritesAPIService: FavoritesAPIService
    private let dataService: MockDataService // Gardé pour les favoris en fallback
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        favoritesAPIService: FavoritesAPIService? = nil,
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
        
        // Charger les économies sauvegardées
        loadSavings()
        
        loadData()
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Charger les données light depuis l'API
                let userLight = try await profileAPIService.getUserLight()
                
                // Mettre à jour les données utilisateur
                user = User(
                    firstName: userLight.firstName,
                    lastName: userLight.lastName,
                    username: user.firstName.lowercased(),
                    bio: (userLight.isMember ?? false) ? "Membre CLUB10" : "",
                    profileImageName: "person.circle.fill",
                    publications: 0,
                    subscribers: 0,
                    subscriptions: 0
                )
                
                // Mettre à jour les données de la carte
                isMember = userLight.isMember ?? false
                isCardActive = userLight.isCardActive ?? false
                cardNumber = userLight.card?.cardNumber
                cardType = userLight.card?.type
                
                // Mettre à jour les compteurs
                referrals = userLight.referralCount ?? 0
                favoritesCount = userLight.favoriteCount ?? 0
                
                // Générer le code de parrainage
                referralCode = generateReferralCode(from: userLight.firstName, lastName: userLight.lastName)
                referralLink = "allin.fr/r/\(referralCode)"
                
                // Charger les partenaires favoris depuis l'API
                await loadFavoritePartners()
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des données de la carte: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                favoritePartners = dataService.getPartners().filter { $0.isFavorite }
                favoritesCount = favoritePartners.count
            }
        }
    }
    
    private func loadFavoritePartners() async {
        do {
            // Charger les favoris depuis l'API
            let favoritesResponse = try await favoritesAPIService.getFavorites()
            favoritePartners = favoritesResponse.map { $0.toPartner() }
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
    func addSavings(amount: Double, date: Date, store: String) {
        let entry = SavingsEntry(amount: amount, date: date, store: store)
        savingsEntries.append(entry)
        updateSavingsTotal()
        saveSavings()
    }
    
    private func updateSavingsTotal() {
        savings = savingsEntries.reduce(0) { $0 + $1.amount }
    }
    
    private func loadSavings() {
        // Charger depuis UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savings_entries"),
           let decoded = try? JSONDecoder().decode([SavingsEntry].self, from: data) {
            savingsEntries = decoded
            updateSavingsTotal()
        } else {
            // Si aucune économie sauvegardée, initialiser avec la valeur par défaut
            // mais ne pas créer d'entrée vide
            savings = 128.0
        }
    }
    
    private func saveSavings() {
        // Sauvegarder dans UserDefaults
        if let encoded = try? JSONEncoder().encode(savingsEntries) {
            UserDefaults.standard.set(encoded, forKey: "savings_entries")
        }
    }
}

