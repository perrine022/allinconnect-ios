//
//  WalletViewModel.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Wallet History Entry
struct WalletHistoryEntry: Identifiable {
    let id: Int
    let amount: Double
    let description: String
    let date: Date
    let userName: String?
    
    var formattedAmount: String {
        String(format: "%.2f", amount)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    var isPositive: Bool {
        amount > 0
    }
}

// MARK: - Wallet Request Entry
struct WalletRequestEntry: Identifiable {
    let id: Int
    let totalAmount: Double
    let status: String
    let createdAt: Date
    let professionals: String
    
    var formattedAmount: String {
        String(format: "%.2f", totalAmount)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: createdAt)
    }
    
    var statusColor: Color {
        switch status.uppercased() {
        case "VALIDATED":
            return .green
        case "REJECTED":
            return .red
        case "PENDING":
            return .orange
        default:
            return .gray
        }
    }
    
    var statusLabel: String {
        switch status.uppercased() {
        case "VALIDATED":
            return "Validée"
        case "REJECTED":
            return "Refusée"
        case "PENDING":
            return "En attente"
        default:
            return status
        }
    }
}

// MARK: - Selected Professional for Wallet Request
struct SelectedProfessional: Identifiable {
    let id: UUID
    let partner: Partner
    var isSelected: Bool
    var amount: String
    
    init(partner: Partner, isSelected: Bool = false, amount: String = "") {
        self.id = UUID()
        self.partner = partner
        self.isSelected = isSelected
        self.amount = amount
    }
}

@MainActor
class WalletViewModel: ObservableObject {
    @Published var walletBalance: Double = 0.0
    @Published var allPartners: [Partner] = []
    @Published var filteredPartners: [Partner] = []
    @Published var selectedPartner: Partner?
    @Published var selectedAmount: String = ""
    @Published var isLoading: Bool = true
    @Published var hasLoadedOnce: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var walletHistory: [WalletHistoryEntry] = []
    @Published var walletRequests: [WalletRequestEntry] = []
    
    // Nouveau flux de décagnottage
    @Published var totalAmountToWithdraw: String = ""
    @Published var showProfessionalSelection: Bool = false
    @Published var selectedProfessionals: [SelectedProfessional] = []
    
    // Filtres de recherche
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    
    // Secteurs disponibles
    let sectors: [String] = [
        "Tous les secteurs",
        "Santé & bien être",
        "Beauté & Esthétique",
        "Food & plaisirs gourmands",
        "Loisirs & Divertissements",
        "Service & pratiques",
        "Entre pros"
    ]
    
    private let walletAPIService: WalletAPIService
    private let partnersAPIService: PartnersAPIService
    private let profileAPIService: ProfileAPIService
    private let dataService: MockDataService
    
    init(
        walletAPIService: WalletAPIService? = nil,
        partnersAPIService: PartnersAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        if let walletAPIService = walletAPIService {
            self.walletAPIService = walletAPIService
        } else {
            self.walletAPIService = WalletAPIService()
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
        
        self.dataService = dataService
        
        loadData()
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Charger le solde de la cagnotte
                let userLight = try await profileAPIService.getUserLight()
                walletBalance = userLight.walletBalance ?? 0.0
                
                // Charger tous les professionnels
                let professionalsResponse = try await partnersAPIService.getAllProfessionals()
                allPartners = professionalsResponse.map { $0.toPartner() }
                
                // Charger l'historique de la cagnotte
                do {
                    let historyResponse = try await walletAPIService.getWalletHistory()
                    walletHistory = historyResponse.map { response in
                        let date = parseISO8601Date(response.date) ?? Date()
                        
                        let userName: String? = {
                            if let user = response.user {
                                var name = ""
                                if let firstName = user.firstName {
                                    name = firstName
                                }
                                if let lastName = user.lastName {
                                    name += name.isEmpty ? lastName : " \(lastName)"
                                }
                                return name.isEmpty ? nil : name
                            }
                            return nil
                        }()
                        
                        return WalletHistoryEntry(
                            id: response.id,
                            amount: response.amount,
                            description: response.description,
                            date: date,
                            userName: userName
                        )
                    }
                } catch {
                    print("Erreur lors du chargement de l'historique: \(error)")
                    walletHistory = []
                }
                
                // Charger les demandes
                do {
                    let requestsResponse = try await walletAPIService.getWalletRequests()
                    walletRequests = requestsResponse.map { response in
                        let date = parseISO8601Date(response.createdAt) ?? Date()
                        
                        return WalletRequestEntry(
                            id: response.id,
                            totalAmount: response.totalAmount,
                            status: response.status,
                            createdAt: date,
                            professionals: response.professionals
                        )
                    }
                } catch {
                    print("Erreur lors du chargement des demandes: \(error)")
                    walletRequests = []
                }
                
                // Appliquer les filtres
                applyFilters()
                
                hasLoadedOnce = true
                isLoading = false
            } catch {
                hasLoadedOnce = true
                isLoading = false
                
                // Vérifier si c'est une erreur de décodage JSON corrompu
                if let apiError = error as? APIError,
                   case .decodingError(let underlyingError) = apiError,
                   let nsError = underlyingError as NSError?,
                   nsError.domain == NSCocoaErrorDomain,
                   nsError.code == 3840 {
                    // Erreur de décodage JSON corrompu - utiliser données mockées sans afficher d'erreur
                    print("Erreur de décodage JSON lors du chargement des données de la cagnotte, utilisation des données mockées")
                    allPartners = dataService.getPartners()
                    applyFilters()
                    walletHistory = []
                    walletRequests = []
                    errorMessage = nil // Ne pas afficher d'erreur pour les réponses corrompues
                } else {
                    // Autre type d'erreur - afficher le message
                    errorMessage = error.localizedDescription
                    print("Erreur lors du chargement des données de la cagnotte: \(error)")
                    
                    // En cas d'erreur, utiliser les données mockées en fallback
                    allPartners = dataService.getPartners()
                    applyFilters()
                    walletHistory = []
                    walletRequests = []
                }
            }
        }
    }
    
    func applyFilters() {
        var filtered = allPartners
        
        // Filtre par texte de recherche
        if !cityText.isEmpty {
            filtered = filtered.filter { partner in
                partner.name.localizedCaseInsensitiveContains(cityText) ||
                partner.city.localizedCaseInsensitiveContains(cityText) ||
                partner.category.localizedCaseInsensitiveContains(cityText)
            }
        }
        
        // Filtre par secteur
        if !selectedSector.isEmpty && selectedSector != "Tous les secteurs" {
            filtered = filtered.filter { partner in
                partner.category.localizedCaseInsensitiveContains(selectedSector)
            }
        }
        
        filteredPartners = filtered
        
        // Mettre à jour selectedProfessionals si on est en mode sélection
        if showProfessionalSelection {
            updateSelectedProfessionalsList()
        }
    }
    
    func updateSelectedProfessionalsList() {
        // Créer une map des professionnels déjà sélectionnés
        let existingMap = Dictionary(uniqueKeysWithValues: selectedProfessionals.map { ($0.partner.id, $0) })
        
        // Créer la nouvelle liste à partir de filteredPartners
        selectedProfessionals = filteredPartners.map { partner in
            if let existing = existingMap[partner.id] {
                // Conserver l'état existant (sélection et montant)
                return existing
            } else {
                // Nouveau professionnel, non sélectionné par défaut
                return SelectedProfessional(partner: partner, isSelected: false, amount: "")
            }
        }
    }
    
    func startWithdrawal() {
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            errorMessage = "Veuillez entrer un montant valide"
            return
        }
        
        guard totalAmount <= walletBalance else {
            errorMessage = "Le montant ne peut pas dépasser le solde de votre cagnotte"
            return
        }
        
        // Initialiser la liste des professionnels sélectionnables
        // S'assurer que les filtres sont appliqués d'abord
        applyFilters()
        // Puis initialiser la liste
        updateSelectedProfessionalsList()
        showProfessionalSelection = true
        errorMessage = nil
        successMessage = nil
    }
    
    func toggleProfessionalSelection(_ professional: SelectedProfessional) {
        if let index = selectedProfessionals.firstIndex(where: { $0.id == professional.id }) {
            selectedProfessionals[index].isSelected.toggle()
            // Si on désélectionne, réinitialiser le montant
            if !selectedProfessionals[index].isSelected {
                selectedProfessionals[index].amount = ""
            }
        }
    }
    
    func updateProfessionalAmount(_ professional: SelectedProfessional, amount: String) {
        guard let index = selectedProfessionals.firstIndex(where: { $0.id == professional.id }) else { return }
        
        // Vérifier que le montant ne dépasse pas le montant restant disponible
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            selectedProfessionals[index].amount = amount
            return
        }
        
        // Calculer le montant déjà alloué aux autres professionnels
        var totalAllocated: Double = 0
        for (i, sel) in selectedProfessionals.enumerated() {
            if i != index && sel.isSelected, let amt = Double(sel.amount) {
                totalAllocated += amt
            }
        }
        
        let remainingAmount = totalAmount - totalAllocated
        
        // Si le nouveau montant dépasse le montant restant, le limiter
        if let newAmount = Double(amount), newAmount > remainingAmount {
            selectedProfessionals[index].amount = String(format: "%.2f", remainingAmount)
        } else {
            selectedProfessionals[index].amount = amount
        }
    }
    
    // Calculer le montant restant disponible
    var remainingAmount: Double {
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            return 0
        }
        
        let totalAllocated = selectedProfessionals
            .filter { $0.isSelected }
            .compactMap { Double($0.amount) }
            .reduce(0, +)
        
        return max(0, totalAmount - totalAllocated)
    }
    
    // Calculer le montant maximum disponible pour un professionnel spécifique
    func maxAmountForProfessional(_ professional: SelectedProfessional) -> Double {
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            return 0
        }
        
        // Calculer le montant déjà alloué aux autres professionnels (sans celui-ci)
        let totalAllocated = selectedProfessionals
            .filter { $0.id != professional.id && $0.isSelected }
            .compactMap { Double($0.amount) }
            .reduce(0, +)
        
        return max(0, totalAmount - totalAllocated)
    }
    
    func submitWithdrawalRequest() async {
        // Vérifier qu'au moins un professionnel est sélectionné
        let selected = selectedProfessionals.filter { $0.isSelected && !$0.amount.isEmpty }
        
        guard !selected.isEmpty else {
            errorMessage = "Veuillez sélectionner au moins un professionnel avec un montant"
            return
        }
        
        // Vérifier que la somme des montants ne dépasse pas le montant total
        var totalSelectedAmount: Double = 0
        for sel in selected {
            guard let amount = Double(sel.amount), amount > 0 else {
                errorMessage = "Veuillez entrer un montant valide pour \(sel.partner.name)"
                return
            }
            totalSelectedAmount += amount
        }
        
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            errorMessage = "Montant total invalide"
            return
        }
        
        // La somme doit être exactement égale au montant total
        let difference = abs(totalSelectedAmount - totalAmount)
        guard difference < 0.01 else { // Tolérance de 0.01€ pour les arrondis
            if totalSelectedAmount > totalAmount {
                errorMessage = "La somme des montants sélectionnés (\(String(format: "%.2f", totalSelectedAmount))€) dépasse le montant total (\(String(format: "%.2f", totalAmount))€)"
            } else {
                errorMessage = "La somme des montants sélectionnés (\(String(format: "%.2f", totalSelectedAmount))€) doit être égale au montant total (\(String(format: "%.2f", totalAmount))€). Il reste \(String(format: "%.2f", totalAmount - totalSelectedAmount))€ à répartir."
            }
            return
        }
        
        guard totalAmount <= walletBalance else {
            errorMessage = "Le montant ne peut pas dépasser le solde de votre cagnotte"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Construire la chaîne des professionnels
            let professionalsString = selected.map { "\($0.partner.name): \($0.amount)€" }.joined(separator: ", ")
            
            // Créer la demande
            let _ = try await walletAPIService.createWalletRequest(
                amount: totalAmount,
                professionals: professionalsString
            )
            
            successMessage = "Demande créée avec succès"
            
            // Réinitialiser le formulaire
            totalAmountToWithdraw = ""
            showProfessionalSelection = false
            selectedProfessionals = []
            
            // Recharger le solde, l'historique et les demandes
            let userLight = try await profileAPIService.getUserLight()
            walletBalance = userLight.walletBalance ?? 0.0
            
            // Recharger l'historique
            do {
                let historyResponse = try await walletAPIService.getWalletHistory()
                walletHistory = historyResponse.map { response in
                    let date = parseISO8601Date(response.date) ?? Date()
                    
                    let userName: String? = {
                        if let user = response.user {
                            var name = ""
                            if let firstName = user.firstName {
                                name = firstName
                            }
                            if let lastName = user.lastName {
                                name += name.isEmpty ? lastName : " \(lastName)"
                            }
                            return name.isEmpty ? nil : name
                        }
                        return nil
                    }()
                    
                    return WalletHistoryEntry(
                        id: response.id,
                        amount: response.amount,
                        description: response.description,
                        date: date,
                        userName: userName
                    )
                }
            } catch {
                print("Erreur lors du rechargement de l'historique: \(error)")
            }
            
            // Recharger les demandes
            do {
                let requestsResponse = try await walletAPIService.getWalletRequests()
                walletRequests = requestsResponse.map { response in
                    let date = parseISO8601Date(response.createdAt) ?? Date()
                    
                    return WalletRequestEntry(
                        id: response.id,
                        totalAmount: response.totalAmount,
                        status: response.status,
                        createdAt: date,
                        professionals: response.professionals
                    )
                }
            } catch {
                print("Erreur lors du rechargement des demandes: \(error)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de la création de la demande: \(error.localizedDescription)"
            print("Erreur lors de la création de la demande: \(error)")
        }
    }
    
    var isValidWithdrawalAmount: Bool {
        guard let amount = Double(totalAmountToWithdraw), amount > 0 else {
            return false
        }
        return amount <= walletBalance
    }
    
    var canSubmitRequest: Bool {
        guard let totalAmount = Double(totalAmountToWithdraw), totalAmount > 0 else {
            return false
        }
        
        let selected = selectedProfessionals.filter { $0.isSelected && !$0.amount.isEmpty }
        guard !selected.isEmpty else { return false }
        
        // Vérifier que tous les montants sont valides
        var totalSelectedAmount: Double = 0
        for sel in selected {
            guard let amount = Double(sel.amount), amount > 0 else {
                return false
            }
            totalSelectedAmount += amount
        }
        
        // La somme doit être exactement égale au montant total (tolérance de 0.01€)
        let difference = abs(totalSelectedAmount - totalAmount)
        return difference < 0.01
    }
    
    func searchPartners() {
        applyFilters()
    }
    
    private func mapSectorToCategory(_ sector: String) -> OfferCategory? {
        switch sector.lowercased() {
        case "santé & bien être", "sante & bien etre":
            return .santeBienEtre
        case "beauté & esthétique", "beaute & esthetique":
            return .beauteEsthetique
        case "food & plaisirs gourmands":
            return .foodPlaisirs
        case "loisirs & divertissements":
            return .loisirsDivertissements
        case "service & pratiques":
            return .servicePratiques
        case "entre pros":
            return .entrePros
        default:
            return nil
        }
    }
    
    func createWalletRequest() async {
        guard let partner = selectedPartner else {
            errorMessage = "Veuillez sélectionner un professionnel"
            return
        }
        
        guard let amount = Double(selectedAmount), amount > 0 else {
            errorMessage = "Veuillez entrer un montant valide"
            return
        }
        
        guard amount <= walletBalance else {
            errorMessage = "Le montant ne peut pas dépasser le solde de votre cagnotte"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let professionalsString = "\(partner.name): \(amount)€"
            let _ = try await walletAPIService.createWalletRequest(
                amount: amount,
                professionals: professionalsString
            )
            
            successMessage = "Demande créée avec succès"
            selectedAmount = ""
            selectedPartner = nil
            
            // Recharger le solde, l'historique et les demandes
            let userLight = try await profileAPIService.getUserLight()
            walletBalance = userLight.walletBalance ?? 0.0
            
            // Recharger l'historique
            do {
                let historyResponse = try await walletAPIService.getWalletHistory()
                walletHistory = historyResponse.map { response in
                    let date = parseISO8601Date(response.date) ?? Date()
                    
                    let userName: String? = {
                        if let user = response.user {
                            var name = ""
                            if let firstName = user.firstName {
                                name = firstName
                            }
                            if let lastName = user.lastName {
                                name += name.isEmpty ? lastName : " \(lastName)"
                            }
                            return name.isEmpty ? nil : name
                        }
                        return nil
                    }()
                    
                    return WalletHistoryEntry(
                        id: response.id,
                        amount: response.amount,
                        description: response.description,
                        date: date,
                        userName: userName
                    )
                }
            } catch {
                print("Erreur lors du rechargement de l'historique: \(error)")
            }
            
            // Recharger les demandes
            do {
                let requestsResponse = try await walletAPIService.getWalletRequests()
                walletRequests = requestsResponse.map { response in
                    let date = parseISO8601Date(response.createdAt) ?? Date()
                    
                    return WalletRequestEntry(
                        id: response.id,
                        totalAmount: response.totalAmount,
                        status: response.status,
                        createdAt: date,
                        professionals: response.professionals
                    )
                }
            } catch {
                print("Erreur lors du rechargement des demandes: \(error)")
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de la création de la demande: \(error.localizedDescription)"
            print("Erreur lors de la création de la demande: \(error)")
        }
    }
    
    var isValidRequest: Bool {
        selectedPartner != nil && Double(selectedAmount) != nil && Double(selectedAmount) ?? 0 > 0
    }
    
    // MARK: - Helper Functions
    private func parseISO8601Date(_ dateString: String) -> Date? {
        // Essayer avec fractions de secondes
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }
        
        // Essayer sans fractions de secondes
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFractional.date(from: dateString) {
            return date
        }
        
        // Essayer avec un format alternatif
        let alternateFormatter = DateFormatter()
        alternateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        alternateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = alternateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}

