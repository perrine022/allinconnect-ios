//
//  ReferralsViewModel.swift
//  all
//
//  Created by Perrine Honoré on 06/01/2026.
//

import Foundation
import Combine

@MainActor
class ReferralsViewModel: ObservableObject {
    @Published var referrals: [ReferralResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let profileAPIService: ProfileAPIService
    
    init(profileAPIService: ProfileAPIService? = nil) {
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        // Charger les filleuls au démarrage
        Task {
            await loadReferrals()
        }
    }
    
    func loadReferrals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            referrals = try await profileAPIService.getReferrals()
            isLoading = false
            print("[ReferralsViewModel] loadReferrals() - Succès: \(referrals.count) filleuls")
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement des filleuls: \(error.localizedDescription)"
            print("[ReferralsViewModel] loadReferrals() - Erreur: \(error.localizedDescription)")
        }
    }
}

