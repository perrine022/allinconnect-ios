//
//  ManageSubscriptionsViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ManageSubscriptionsViewModel: ObservableObject {
    @Published var currentSubscriptionPlan: SubscriptionPlanResponse? = nil
    @Published var availablePlans: [SubscriptionPlanResponse] = []
    @Published var selectedPlan: SubscriptionPlanResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Informations d'abonnement actuel
    @Published var currentFormula: String = "Mensuel"
    @Published var currentAmount: String = ""
    @Published var nextPaymentDate: String = ""
    @Published var commitmentUntil: String = ""
    
    private let profileAPIService: ProfileAPIService
    private let subscriptionsAPIService: SubscriptionsAPIService
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        subscriptionsAPIService: SubscriptionsAPIService? = nil
    ) {
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
    }
    
    func loadSubscriptionData() async {
        isLoading = true
        errorMessage = nil
        
        do {
                // Charger les informations utilisateur avec abonnement
                let userLight = try await profileAPIService.getUserLight()
                
                // Charger tous les plans disponibles
                let allPlans = try await subscriptionsAPIService.getPlans()
                
                // Filtrer uniquement les plans PROFESSIONAL
                availablePlans = allPlans.filter { $0.category == "PROFESSIONAL" }
                
                // Trouver le plan actuel basé sur les informations de l'utilisateur
                if let subscriptionAmount = userLight.subscriptionAmount {
                    // Trouver le plan correspondant au montant
                    currentSubscriptionPlan = availablePlans.first { plan in
                        abs(plan.price - subscriptionAmount) < 0.01
                    }
                    
                    // Si pas trouvé par montant, essayer de trouver par date
                    if currentSubscriptionPlan == nil {
                        // Par défaut, prendre le premier plan mensuel
                        currentSubscriptionPlan = availablePlans.first { $0.isMonthly }
                    }
                } else {
                    // Par défaut, prendre le premier plan mensuel
                    currentSubscriptionPlan = availablePlans.first { $0.isMonthly }
                }
                
                // Mettre à jour les informations d'affichage
                if let currentPlan = currentSubscriptionPlan {
                    currentFormula = currentPlan.isMonthly ? "Mensuel" : "Annuel"
                    currentAmount = "\(currentPlan.formattedPrice) / \(currentPlan.isMonthly ? "mois" : "an")"
                    
                    // Sélectionner le plan actuel par défaut
                    selectedPlan = currentPlan
                }
                
                // Formater les dates
                if let renewalDate = userLight.renewalDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    if let date = dateFormatter.date(from: renewalDate) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "dd/MM/yyyy"
                        nextPaymentDate = displayFormatter.string(from: date)
                        
                        // Calculer la date d'engagement (1 an après)
                        if let commitmentDate = Calendar.current.date(byAdding: .year, value: 1, to: date) {
                            commitmentUntil = displayFormatter.string(from: commitmentDate)
                        }
                    } else {
                        // Essayer un autre format
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: renewalDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "dd/MM/yyyy"
                            nextPaymentDate = displayFormatter.string(from: date)
                            
                            if let commitmentDate = Calendar.current.date(byAdding: .year, value: 1, to: date) {
                                commitmentUntil = displayFormatter.string(from: commitmentDate)
                            }
                        }
                    }
                }
                
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement des données d'abonnement"
            print("Erreur lors du chargement des données d'abonnement: \(error)")
        }
    }
    
    func updateSubscription() {
        guard let selectedPlan = selectedPlan else {
            errorMessage = "Veuillez sélectionner un plan"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Appeler l'API pour mettre à jour l'abonnement
                try await subscriptionsAPIService.subscribe(planId: selectedPlan.id)
                
                // Recharger les données
                await loadSubscriptionData()
                
                // Notifier la mise à jour
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors de la mise à jour de l'abonnement"
                print("Erreur lors de la mise à jour de l'abonnement: \(error)")
            }
        }
    }
    
    func cancelSubscription() {
        // TODO: Implémenter l'annulation d'abonnement via l'API
        isLoading = true
        errorMessage = nil
        
        Task {
            // Appeler l'API pour annuler l'abonnement
            // try await subscriptionsAPIService.cancelSubscription()
            
            // Pour l'instant, juste notifier
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            
            isLoading = false
        }
    }
}

