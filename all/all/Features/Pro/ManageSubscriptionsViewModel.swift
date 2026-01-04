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
    
    // Factures (uniquement pour les pros)
    @Published var invoices: [InvoiceResponse] = []
    @Published var isLoadingInvoices: Bool = false
    @Published var invoiceErrorMessage: String?
    @Published var isDownloadingInvoice: Bool = false
    
    private let profileAPIService: ProfileAPIService
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let invoicesAPIService: InvoicesAPIService
    let billingViewModel: BillingViewModel // Public pour accéder à successMessage
    
    // Stocker le subscriptionId pour l'annulation
    @Published var currentSubscriptionId: String? = nil
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        subscriptionsAPIService: SubscriptionsAPIService? = nil,
        invoicesAPIService: InvoicesAPIService? = nil,
        billingViewModel: BillingViewModel? = nil
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
        
        if let invoicesAPIService = invoicesAPIService {
            self.invoicesAPIService = invoicesAPIService
        } else {
            self.invoicesAPIService = InvoicesAPIService()
        }
        
        if let billingViewModel = billingViewModel {
            self.billingViewModel = billingViewModel
        } else {
            self.billingViewModel = BillingViewModel()
        }
    }
    
    func loadSubscriptionData() async {
        isLoading = true
        errorMessage = nil
        
        // Récupérer le subscriptionId depuis UserDefaults
        currentSubscriptionId = UserDefaults.standard.string(forKey: "current_subscription_id")
        if let subscriptionId = currentSubscriptionId {
            print("[ManageSubscriptionsViewModel] subscriptionId récupéré depuis UserDefaults: \(subscriptionId)")
        } else {
            print("[ManageSubscriptionsViewModel] ⚠️ subscriptionId non trouvé dans UserDefaults")
        }
        
        do {
                // Charger les informations utilisateur avec abonnement
                let userLight = try await profileAPIService.getUserLight()
                
                // Déterminer le type d'utilisateur depuis UserDefaults
                let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
                let isPro = userTypeString == "PRO"
                
                // Charger tous les plans disponibles
                let allPlans = try await subscriptionsAPIService.getPlans()
                print("[ManageSubscriptionsViewModel] Plans récupérés: \(allPlans.count) plans")
                print("[ManageSubscriptionsViewModel] Type d'utilisateur: \(userTypeString) (isPro: \(isPro))")
                
                // Filtrer les plans selon le type d'utilisateur
                if isPro {
                    // Pour les PRO : uniquement les plans PROFESSIONAL
                    availablePlans = allPlans.filter { $0.category == "PROFESSIONAL" }
                    print("[ManageSubscriptionsViewModel] Plans filtrés pour PROFESSIONAL: \(availablePlans.count) plans")
                } else {
                    // Pour les CLIENT : uniquement les plans INDIVIDUAL et FAMILY
                    availablePlans = allPlans.filter { $0.category == "INDIVIDUAL" || $0.category == "FAMILY" }
                    print("[ManageSubscriptionsViewModel] Plans filtrés pour CLIENT (INDIVIDUAL + FAMILY): \(availablePlans.count) plans")
                }
                
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
    
    func cancelSubscription() async {
        guard let subscriptionId = currentSubscriptionId else {
            errorMessage = "Impossible de trouver l'ID de l'abonnement. Veuillez contacter le support."
            print("[ManageSubscriptionsViewModel] ❌ subscriptionId manquant pour l'annulation")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Appeler l'endpoint d'annulation via BillingViewModel
            try await billingViewModel.cancelSubscription(subscriptionId: subscriptionId)
            
            // Recharger les données pour voir le nouveau statut
            await loadSubscriptionData()
            
            // Notifier la mise à jour
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de l'annulation de l'abonnement: \(error.localizedDescription)"
            print("[ManageSubscriptionsViewModel] ❌ Erreur lors de l'annulation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Invoices Management (uniquement pour les pros)
    func loadInvoices() async {
        isLoadingInvoices = true
        invoiceErrorMessage = nil
        
        do {
            invoices = try await invoicesAPIService.getInvoices()
            // Trier par date décroissante (plus récentes en premier)
            invoices.sort { invoice1, invoice2 in
                invoice1.date > invoice2.date
            }
            isLoadingInvoices = false
        } catch {
            isLoadingInvoices = false
            invoiceErrorMessage = "Erreur lors du chargement des factures"
            print("Erreur lors du chargement des factures: \(error)")
        }
    }
    
    @Published var downloadedInvoiceURL: URL? = nil
    @Published var showShareSheet: Bool = false
    
    func downloadInvoice(invoiceId: Int) async {
        isDownloadingInvoice = true
        invoiceErrorMessage = nil
        
        do {
            let pdfData = try await invoicesAPIService.downloadInvoicePDF(invoiceId: invoiceId)
            
            // Sauvegarder le PDF dans le dossier Documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let invoice = invoices.first { $0.id == invoiceId }
            let fileName = "Facture_\(invoice?.invoiceNumber ?? "\(invoiceId)").pdf"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try pdfData.write(to: fileURL)
            
            // Stocker l'URL pour le partage
            downloadedInvoiceURL = fileURL
            showShareSheet = true
            
            isDownloadingInvoice = false
        } catch {
            isDownloadingInvoice = false
            invoiceErrorMessage = "Erreur lors du téléchargement de la facture"
            print("Erreur lors du téléchargement de la facture: \(error)")
        }
    }
}

