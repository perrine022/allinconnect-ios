//
//  WalletViewModel.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine

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
    
    // Filtres de recherche
    @Published var cityText: String = ""
    @Published var selectedSector: String = ""
    
    // Secteurs disponibles
    let sectors: [String] = [
        "",
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
                
                // Appliquer les filtres
                applyFilters()
                
                hasLoadedOnce = true
                isLoading = false
            } catch {
                hasLoadedOnce = true
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors du chargement des données de la cagnotte: \(error)")
                
                // En cas d'erreur, utiliser les données mockées en fallback
                allPartners = dataService.getPartners()
                applyFilters()
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
        if !selectedSector.isEmpty {
            filtered = filtered.filter { partner in
                partner.category.localizedCaseInsensitiveContains(selectedSector)
            }
        }
        
        filteredPartners = filtered
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
            let response = try await walletAPIService.createWalletRequest(
                amount: amount,
                professionals: professionalsString
            )
            
            successMessage = "Demande créée avec succès"
            selectedAmount = ""
            selectedPartner = nil
            
            // Recharger le solde
            let userLight = try await profileAPIService.getUserLight()
            walletBalance = userLight.walletBalance ?? 0.0
            
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
}

