//
//  ProSubscriptionViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ProSubscriptionViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlanResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPlan: SubscriptionPlanResponse?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    
    init(subscriptionsAPIService: SubscriptionsAPIService? = nil) {
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
    }
    
    func loadPlans() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let allPlans = try await subscriptionsAPIService.getPlans()
                // Filtrer uniquement les plans PROFESSIONAL
                plans = allPlans.filter { $0.category == "PROFESSIONAL" }
                // Sélectionner le plan mensuel par défaut
                selectedPlan = plans.first { $0.isMonthly } ?? plans.first
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des plans"
                print("Erreur lors du chargement des plans: \(error)")
            }
        }
    }
}

