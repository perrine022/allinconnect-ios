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
    @Published var currentFormula: String = ""
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
    private let billingAPIService: BillingAPIService
    let billingViewModel: BillingViewModel // Public pour accéder à successMessage
    
    // Stocker le subscriptionId pour l'annulation
    @Published var currentSubscriptionId: String? = nil
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        subscriptionsAPIService: SubscriptionsAPIService? = nil,
        invoicesAPIService: InvoicesAPIService? = nil,
        billingAPIService: BillingAPIService? = nil,
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
        
        if let billingAPIService = billingAPIService {
            self.billingAPIService = billingAPIService
        } else {
            self.billingAPIService = BillingAPIService()
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
        
        print("═══════════════════════════════════════════════════════════")
        print("💳 [GÉRER ABONNEMENT] loadSubscriptionData() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        // Récupérer le subscriptionId depuis UserDefaults
        currentSubscriptionId = UserDefaults.standard.string(forKey: "current_subscription_id")
        if let subscriptionId = currentSubscriptionId {
            print("[ManageSubscriptionsViewModel] subscriptionId récupéré depuis UserDefaults: \(subscriptionId)")
        } else {
            print("[ManageSubscriptionsViewModel] ⚠️ subscriptionId non trouvé dans UserDefaults")
        }
        
        do {
            // Utiliser le même endpoint que "Ma Carte" : GET /api/v1/billing/subscription/{userId}
            print("[ManageSubscriptionsViewModel] Appel API: GET /api/v1/billing/subscription/{userId}")
            let userId = try await profileAPIService.getCurrentUserId()
            print("[ManageSubscriptionsViewModel] userId: \(userId)")
            
            let subscriptionDetails = try await billingAPIService.getSubscriptionDetails(userId: userId)
            print("[ManageSubscriptionsViewModel] ✅ Détails d'abonnement récupérés:")
            print("   - status: \(subscriptionDetails.status ?? "nil")")
            print("   - premiumEnabled: \(subscriptionDetails.premiumEnabled)")
            print("   - planName: \(subscriptionDetails.planName ?? "nil")")
            print("   - currentPeriodEnd: \(subscriptionDetails.currentPeriodEnd ?? "nil")")
            
            // Vérifier si l'utilisateur a un abonnement actif
            let hasActiveSubscription = subscriptionDetails.premiumEnabled && 
                                      subscriptionDetails.status != nil && 
                                      subscriptionDetails.status != "CANCELLED" &&
                                      subscriptionDetails.status != "CANCELED"
            
            print("[ManageSubscriptionsViewModel] Abonnement actif: \(hasActiveSubscription)")
            
            // Charger les informations utilisateur pour le type
            let userLight = try await profileAPIService.getUserLight()
            let userTypeString = userLight.userType ?? ""
            let isUnknown = userTypeString == "UNKNOWN" || userTypeString.isEmpty
            
            // Déterminer le type d'utilisateur depuis l'API (ou UserDefaults si UNKNOWN)
            let userTypeForPlans = isUnknown ? (UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT") : userTypeString
            let isPro = userTypeForPlans == "PROFESSIONAL" || userTypeForPlans == "PRO"
            
            // Charger tous les plans disponibles (même si pas d'abonnement actif, pour permettre l'abonnement)
            let allPlans = try await subscriptionsAPIService.getPlans()
            print("[ManageSubscriptionsViewModel] Plans récupérés: \(allPlans.count) plans")
            print("[ManageSubscriptionsViewModel] Type d'utilisateur pour plans: \(userTypeForPlans) (isPro: \(isPro))")
            
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
            
            // Si l'utilisateur a un abonnement actif, utiliser les informations de subscriptionDetails
            if hasActiveSubscription {
                // Trouver le plan correspondant au planName
                if let planName = subscriptionDetails.planName {
                    // Utiliser filter puis first pour éviter les problèmes d'inférence de type
                    let matchingPlans = availablePlans.filter { plan in
                        plan.title == planName
                    }
                    currentSubscriptionPlan = matchingPlans.first
                    
                    // Si pas trouvé par nom, essayer de trouver par catégorie et durée
                    if currentSubscriptionPlan == nil {
                        // Essayer de trouver un plan mensuel par défaut
                        let monthlyPlans = availablePlans.filter { $0.duration == "MONTHLY" }
                        currentSubscriptionPlan = monthlyPlans.first
                    }
                } else {
                    // Si pas de planName, prendre le premier plan disponible
                    currentSubscriptionPlan = availablePlans.first
                }
                
                // Mettre à jour les informations d'affichage
                if let currentPlan = currentSubscriptionPlan {
                    currentFormula = currentPlan.isMonthly ? "Mensuel" : "Annuel"
                    currentAmount = "\(currentPlan.formattedPrice) / \(currentPlan.isMonthly ? "mois" : "an")"
                    selectedPlan = currentPlan
                } else {
                    // Si pas de plan trouvé, utiliser les infos de base
                    currentFormula = "Actif"
                    currentAmount = subscriptionDetails.planName ?? "N/A"
                }
                
                // Formater les dates depuis currentPeriodEnd
                if let periodEndString = subscriptionDetails.currentPeriodEnd {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
                    
                    if let date = formatter.date(from: periodEndString) {
                        let displayFormatter = DateFormatter()
                        displayFormatter.dateFormat = "dd/MM/yyyy"
                        nextPaymentDate = displayFormatter.string(from: date)
                        
                        // Calculer la date d'engagement (1 an après)
                        if let commitmentDate = Calendar.current.date(byAdding: .year, value: 1, to: date) {
                            commitmentUntil = displayFormatter.string(from: commitmentDate)
                        }
                    }
                }
            } else {
                    // Pas d'abonnement actif, ne pas afficher de plan
                    print("[ManageSubscriptionsViewModel] ⚠️ Pas d'abonnement actif détecté")
                    currentSubscriptionPlan = nil
                    currentFormula = ""
                    currentAmount = ""
                    nextPaymentDate = ""
                    commitmentUntil = ""
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
            // Trier par date décroissante (plus récentes en premier) - utiliser created (timestamp Unix)
            invoices.sort { (invoice1: InvoiceResponse, invoice2: InvoiceResponse) -> Bool in
                invoice1.created > invoice2.created
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
    
    func downloadInvoice(invoiceId: String) async {
        isDownloadingInvoice = true
        invoiceErrorMessage = nil
        
        do {
            // Trouver la facture par son ID (String maintenant)
            guard let invoice = invoices.first(where: { $0.id == invoiceId }),
                  let invoicePdfUrl = invoice.invoicePdf else {
                invoiceErrorMessage = "URL du PDF non disponible pour cette facture"
                isDownloadingInvoice = false
                return
            }
            
            // Télécharger le PDF depuis l'URL Stripe
            let pdfData = try await invoicesAPIService.downloadInvoicePDF(invoicePdfUrl: invoicePdfUrl)
            
            // Sauvegarder le PDF dans le dossier Documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "Facture_\(invoice.invoiceNumber).pdf"
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

