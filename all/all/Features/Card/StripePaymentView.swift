//
//  StripePaymentView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import SafariServices
import UIKit
import Combine

struct StripePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StripePaymentViewModel()
    @State private var showSafari = false
    
    // Paramètre optionnel pour afficher des messages informatifs selon le contexte
    // Note: Ne filtre plus les plans - tous les plans sont affichés
    var filterCategory: String? = nil // "PROFESSIONAL", "INDIVIDUAL", "FAMILY", ou "CLIENT" (INDIVIDUAL + FAMILY)
    var showFamilyCardPromotion: Bool = false // Afficher le message "Pensez à la carte famille !" uniquement depuis "Obtenir ma carte"
    
    var body: some View {
        StripePaymentContentView(
            viewModel: viewModel,
            filterCategory: filterCategory,
            showFamilyCardPromotion: showFamilyCardPromotion
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
        .onAppear {
            viewModel.loadPlans(filterCategory: filterCategory)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StripePaymentReturned"))) { notification in
            // Gérer le retour depuis Stripe via Universal Link
            if let userInfo = notification.userInfo,
               let status = userInfo["status"] as? String {
                if status == "success" {
                    // Le paiement a réussi, vérifier le statut
                    Task { @MainActor in
                        await PaymentStatusManager.shared.checkPaymentStatus()
                    }
                }
            }
        }
        .sheet(isPresented: $showSafari) {
            if let paymentURL = viewModel.paymentURL {
                SafariView(
                    url: paymentURL,
                    onDismiss: {
                        // Quand l'utilisateur ferme Safari manuellement, vérifier le statut
                        viewModel.handlePaymentReturn()
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showPaymentSheet) {
            // Payment Sheet Stripe (Étape B)
            // Le clientSecret peut être soit un PaymentIntent (pi_...) soit un SetupIntent (seti_...)
            // Utilise intentType du backend si disponible, sinon détection auto par préfixe
            if let clientSecret = viewModel.paymentIntentClientSecret {
                StripeSubscriptionPaymentSheetView(
                    clientSecret: clientSecret,
                    intentType: viewModel.intentType, // Utilise intentType du backend
                    onPaymentResult: { success, error in
                        Task { @MainActor in
                            await viewModel.handlePaymentSheetResult(success: success, error: error)
                        }
                    },
                    customerId: viewModel.customerId,
                    ephemeralKeySecret: viewModel.ephemeralKeySecret,
                    publishableKey: viewModel.publishableKey
                )
            }
        }
        .sheet(isPresented: $viewModel.isActivating) {
            ActivationInProgressView()
        }
        .alert("🎉 Félicitations !", isPresented: $viewModel.showSuccessMessage) {
            Button("OK", role: .cancel) {
                // Annuler le task de masquage automatique si l'utilisateur ferme manuellement
                viewModel.cancelAutoHideTask()
                
                // Fermer l'alert d'abord de manière asynchrone pour éviter les conflits
                Task.detached { @MainActor [weak viewModel] in
                    viewModel?.showSuccessMessage = false
                    
                    // Attendre un court délai pour que l'alert soit complètement fermé
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
                    
                    // Notifier pour naviguer vers l'onglet "Ma Carte" et recharger les données
                    // Envoyer plusieurs fois pour s'assurer que la notification est reçue
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToCardAfterPayment"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name("ForceReloadCardData"), object: nil)
                    
                    // Attendre un peu plus pour laisser le temps à TabBarView de traiter la notification
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconde
                    
                    // Envoyer à nouveau pour être sûr
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToCardAfterPayment"), object: nil)
                    
                    // Fermer la vue
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Votre abonnement a été activé avec succès. Vous êtes maintenant Premium !")
        }
    }
}

// Vue séparée pour simplifier le type-checking du compilateur
private struct StripePaymentContentView: View {
    @ObservedObject var viewModel: StripePaymentViewModel
    let filterCategory: String?
    let showFamilyCardPromotion: Bool
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Titre
                    VStack(spacing: 8) {
                        Text("Choisissez votre abonnement")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sélectionnez le plan qui vous convient")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Message incitatif pour les pros (carte digitale incluse)
                    if filterCategory == "PROFESSIONAL" {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Carte digitale incluse !")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Avec votre abonnement Pro, vous bénéficiez aussi de tous les avantages de la carte digitale")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appDarkRed1.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Message incitatif pour la carte famille (uniquement depuis "Obtenir ma carte")
                    if showFamilyCardPromotion {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pensez à la carte famille !")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Partagez les avantages avec jusqu'à 4 membres de votre famille")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appDarkRed1.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Indicateur de chargement
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.5)
                            .padding(.vertical, 40)
                    }
                    
                    // Liste des plans
                    if !viewModel.plans.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(viewModel.plans) { plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: viewModel.selectedPlan?.id == plan.id,
                                    showFamilyCardPromotion: showFamilyCardPromotion,
                                    onSelect: {
                                        viewModel.selectedPlan = plan
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Message d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    
                    // Bouton Payer
                    if let selectedPlan = viewModel.selectedPlan {
                        Button(action: {
                            // Utiliser le Payment Sheet Stripe (Étape A + B)
                            Task { @MainActor in
                                await viewModel.processPaymentWithStripeSheet(plan: selectedPlan)
                            }
                        }) {
                            HStack {
                                if viewModel.isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Payer \(selectedPlan.formattedPrice)")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isProcessingPayment ? Color.gray : Color.red)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isProcessingPayment)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlanResponse
    let isSelected: Bool
    let showFamilyCardPromotion: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(plan.formattedPrice)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    // Badge type
                    Text(plan.category == "FAMILY" ? "Famille" : plan.category == "PROFESSIONAL" ? "Pro" : "Individuel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Avantages selon le type
                if plan.category == "FAMILY" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Jusqu'à 4 membres")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Partagez les avantages en famille")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Carte digitale pour chaque membre")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                } else if plan.category == "PROFESSIONAL" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Visibilité locale")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Diffusion de tes offres")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Carte digitale incluse")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Accès à tous les avantages")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Carte digitale personnelle")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        if showFamilyCardPromotion {
                            Text("• Pensez à la carte famille !")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                                .italic()
                        }
                    }
                }
            }
            .padding(20)
            .background(isSelected ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Safari View Controller Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var onDismiss: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.delegate = context.coordinator
        context.coordinator.onDismiss = onDismiss
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onDismiss: (() -> Void)?
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // L'utilisateur a fermé Safari
            onDismiss?()
        }
    }
}

// MARK: - ViewModel
@MainActor
class StripePaymentViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlanResponse] = []
    @Published var selectedPlan: SubscriptionPlanResponse? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var paymentURL: URL? = nil
    @Published var isProcessingPayment: Bool = false
    @Published var showPaymentSheet: Bool = false
    @Published var paymentIntentClientSecret: String? = nil // Peut contenir pi_... ou seti_...
    @Published var intentType: String? = nil // "payment_intent" | "setup_intent" (renvoyé par le backend)
    @Published var customerId: String? = nil
    @Published var ephemeralKeySecret: String? = nil
    @Published var publishableKey: String? = nil
    @Published var currentPaymentIntentId: String? = nil // Pour vérifier le statut si nécessaire
    @Published var showSuccessMessage: Bool = false
    @Published var isActivating: Bool = false // État pour l'écran "Activation en cours"
    private var autoHideTask: Task<Void, Never>? // Task pour masquer automatiquement l'alert
    
    // Méthode publique pour annuler la tâche de masquage automatique
    func cancelAutoHideTask() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let paymentAPIService = PaymentAPIService() // Pour les paiements one-shot
    private let billingAPIService = BillingAPIService() // Pour les abonnements
    private let profileAPIService = ProfileAPIService()
    
    // Payment Link Stripe fourni (fallback si Payment Sheet non disponible)
    private let stripePaymentLinkURL = "https://buy.stripe.com/test_9B614mbv4cH93KZ0cP87K01"
    
    init(subscriptionsAPIService: SubscriptionsAPIService? = nil) {
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
    }
    
    func loadPlans(filterCategory: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let allPlans: [SubscriptionPlanResponse]
                
                // Utiliser les endpoints spécifiques selon le contexte
                if filterCategory == "PROFESSIONAL" {
                    // Pour "S'abonner" (Pro) → appeler /api/v1/subscriptions/pro
                    print("[StripePaymentViewModel] Chargement des plans PRO")
                    allPlans = try await subscriptionsAPIService.getProPlans()
                } else if filterCategory == "CLIENT" {
                    // Pour "Obtenir ma carte" (Client) → appeler /api/v1/subscriptions/client
                    print("[StripePaymentViewModel] Chargement des plans CLIENT")
                    allPlans = try await subscriptionsAPIService.getClientPlans()
                } else {
                    // Par défaut, utiliser l'endpoint général (pour compatibilité)
                    print("[StripePaymentViewModel] Chargement de tous les plans")
                    allPlans = try await subscriptionsAPIService.getPlans()
                }
                
                print("[StripePaymentViewModel] Plans récupérés depuis l'API: \(allPlans.count) plans")
                for plan in allPlans {
                    print("  - \(plan.title): \(plan.formattedPrice) (\(plan.category ?? "N/A") - \(plan.duration ?? "N/A"))")
                }
                
                // Afficher les plans récupérés
                plans = allPlans
                print("[StripePaymentViewModel] Plans affichés: \(plans.count) plans")
                
                // Sélectionner le premier plan par défaut
                if self.selectedPlan == nil && !plans.isEmpty {
                    self.selectedPlan = plans.first
                    print("[StripePaymentViewModel] Plan sélectionné par défaut: \(plans.first?.title ?? "N/A")")
                }
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des plans"
                print("[StripePaymentViewModel] Erreur lors du chargement des plans: \(error)")
            }
        }
    }
    
    func openPaymentLink(plan: SubscriptionPlanResponse) {
        errorMessage = nil
        
        // Récupérer l'email de l'utilisateur depuis UserDefaults
        let userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
        
        // Construire l'URL avec les paramètres optionnels
        guard var components = URLComponents(string: stripePaymentLinkURL) else {
            errorMessage = "URL de paiement invalide"
            return
        }
        
        var queryItems: [URLQueryItem] = []
        
        // Ajouter l'email de l'utilisateur comme référence client
        if !userEmail.isEmpty {
            queryItems.append(URLQueryItem(name: "client_reference_id", value: userEmail))
        }
        
        // IMPORTANT: Configurer les URLs de retour dans Stripe Dashboard
        // Après paiement réussi: https://votredomaine.com/payment-success?session_id={CHECKOUT_SESSION_ID}
        // Après paiement échoué: https://votredomaine.com/payment-failed
        // Ces URLs doivent être configurées dans Stripe Dashboard → Payment Links → After payment
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let finalURL = components.url else {
            errorMessage = "Erreur lors de la création du lien de paiement"
            return
        }
        
        paymentURL = finalURL
    }
    
    func handlePaymentReturn() {
        // Cette fonction est appelée quand l'utilisateur ferme Safari après le paiement
        // Vérifier le statut du paiement via l'API
        Task { @MainActor in
            await PaymentStatusManager.shared.checkPaymentStatus()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
        print("Retour du paiement Stripe - Vérification de l'abonnement en cours...")
    }
    
    // MARK: - Stripe Payment Sheet Integration
    
    /// Nouveau flux de paiement avec Payment Sheet (simplifié)
    /// Le backend récupère automatiquement le userId depuis le JWT
    /// Processus de paiement pour un abonnement
    /// Utilise le flow Stripe Subscription (create subscription avec priceId) au lieu du flow PaymentIntent one-shot
    /// 1. Vérifier si le plan a un stripePriceId
    /// 2. Appeler POST /api/billing/subscription/payment-sheet avec priceId
    /// 3. Afficher le Payment Sheet avec les secrets reçus (paymentIntent vient de subscription.latest_invoice.payment_intent)
    func processPaymentWithStripeSheet(plan: SubscriptionPlanResponse) async {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [ABONNEMENT] Début du processus de paiement pour abonnement")
        print("═══════════════════════════════════════════════════════════")
        print("💳 [ABONNEMENT] Plan sélectionné:")
        print("   - ID: \(plan.id)")
        print("   - Titre: \(plan.title)")
        print("   - Prix: \(plan.price)€")
        print("   - Catégorie: \(plan.category ?? "N/A")")
        print("   - Durée: \(plan.duration ?? "N/A")")
        print("   - stripePriceId: \(plan.stripePriceId ?? "NIL - ERREUR")")
        
        isProcessingPayment = true
        errorMessage = nil
        
        // Vérifier que le plan a un stripePriceId (obligatoire pour créer une subscription)
        guard let priceId = plan.stripePriceId, !priceId.isEmpty else {
            print("═══════════════════════════════════════════════════════════")
            print("❌ [ABONNEMENT] ERREUR: Le plan n'a pas de stripePriceId")
            print("═══════════════════════════════════════════════════════════")
            errorMessage = "Erreur: Le plan sélectionné n'a pas d'ID Stripe valide. Veuillez réessayer."
            isProcessingPayment = false
            return
        }
        
        do {
            // ÉTAPE 1 : Appeler POST /api/billing/subscription/payment-sheet avec priceId
            // Le backend crée une Subscription Stripe en default_incomplete
            // Le backend expand latest_invoice.payment_intent pour récupérer le client_secret
            print("💳 [ABONNEMENT] ÉTAPE 1 : Appel API POST /api/billing/subscription/payment-sheet")
            print("   - priceId: \(priceId)")
            print("   - Note: Le backend crée une Subscription Stripe avec default_incomplete")
            print("   - Note: Le paymentIntent vient de subscription.latest_invoice.payment_intent.client_secret")
            
            let subscriptionSheetResponse = try await billingAPIService.createSubscriptionPaymentSheet(priceId: priceId)
            
            print("💳 [ABONNEMENT] ✅ Réponse reçue du backend avec succès")
            print("   - paymentIntent (client_secret): \(subscriptionSheetResponse.paymentIntent.prefix(30))...")
            print("   - intentType: \(subscriptionSheetResponse.intentType ?? "non spécifié (détection auto)")")
            
            // Vérifier que le format est correct (doit contenir "_secret_")
            let intentType = subscriptionSheetResponse.intentType ?? (subscriptionSheetResponse.paymentIntent.hasPrefix("seti_") ? "setup_intent" : "payment_intent")
            let expectedPrefix = intentType == "setup_intent" ? "seti_" : "pi_"
            let expectedFormat = intentType == "setup_intent" ? "seti_xxx_secret_xxx" : "pi_xxx_secret_xxx"
            
            if subscriptionSheetResponse.paymentIntent.hasPrefix(expectedPrefix) && subscriptionSheetResponse.paymentIntent.contains("_secret_") {
                print("   ✅ Format client_secret correct (\(expectedFormat))")
            } else {
                print("   ⚠️ ATTENTION: Format client_secret incomplet - PaymentSheet ne fonctionnera pas")
                print("   ⚠️ Format attendu: \(expectedFormat)")
                print("   ⚠️ Format reçu: \(subscriptionSheetResponse.paymentIntent)")
            }
            print("   - customerId: \(subscriptionSheetResponse.customerId)")
            print("   - ephemeralKey: \(subscriptionSheetResponse.ephemeralKey.prefix(30))...")
            print("   - publishableKey: \(subscriptionSheetResponse.publishableKey.prefix(30))...")
            print("   - subscriptionId: \(subscriptionSheetResponse.subscriptionId ?? "nil")")
            
            // Stocker les secrets pour le Payment Sheet
            // Le paymentIntent est le client_secret COMPLET du PaymentIntent ou SetupIntent
            // Format requis: "pi_xxx_secret_xxx" (payment_intent) ou "seti_xxx_secret_xxx" (setup_intent)
            // La détection du type se fait automatiquement dans StripeSubscriptionPaymentSheetView selon le préfixe
            print("💳 [ABONNEMENT] ÉTAPE 2 : Stockage des secrets pour le Payment Sheet")
            
            // Stocker le clientSecret et intentType (renvoyés par le backend)
            paymentIntentClientSecret = subscriptionSheetResponse.paymentIntent
            self.intentType = subscriptionSheetResponse.intentType // Utilise intentType du backend
            
            // Log du type
            let detectedType = subscriptionSheetResponse.intentType ?? (subscriptionSheetResponse.paymentIntent.hasPrefix("seti_") ? "setup_intent" : "payment_intent")
            if detectedType == "setup_intent" {
                print("   ✅ SetupIntent stocké (trial/0€)")
                if subscriptionSheetResponse.intentType == nil {
                    print("   ⚠️ intentType non fourni par le backend, détection par préfixe")
                }
            } else {
                print("   ✅ PaymentIntent stocké (paiement normal)")
                if subscriptionSheetResponse.intentType == nil {
                    print("   ⚠️ intentType non fourni par le backend, détection par préfixe")
                }
            }
            
            customerId = subscriptionSheetResponse.customerId // Utiliser customerId (standardisé)
            ephemeralKeySecret = subscriptionSheetResponse.ephemeralKey
            publishableKey = subscriptionSheetResponse.publishableKey
            print("   ✅ Secrets stockés dans le ViewModel")
            
            // Extraire le paymentIntentId pour vérification du statut si nécessaire
            // Format: "pi_xxx_secret_xxx" -> extraire "pi_xxx"
            if let paymentIntentId = subscriptionSheetResponse.paymentIntent.components(separatedBy: "_secret_").first {
                currentPaymentIntentId = paymentIntentId
                print("   ✅ PaymentIntentId extrait: \(paymentIntentId)")
            }
            
            // Stocker le subscriptionId dans UserDefaults pour l'annulation future
            if let subscriptionId = subscriptionSheetResponse.subscriptionId {
                UserDefaults.standard.set(subscriptionId, forKey: "current_subscription_id")
                print("💳 [ABONNEMENT] ✅ subscriptionId stocké dans UserDefaults: \(subscriptionId)")
            }
            
            // ÉTAPE 3 : Présenter le Payment Sheet
            print("💳 [ABONNEMENT] ÉTAPE 3 : Présentation du Payment Sheet Stripe")
            print("   → Affichage de l'interface de paiement à l'utilisateur")
            print("   → Après confirmation, le webhook backend activera premiumEnabled via invoice.paid")
            showPaymentSheet = true
            print("═══════════════════════════════════════════════════════════")
            
        } catch {
            print("═══════════════════════════════════════════════════════════")
            print("❌ [PAIEMENT] ERREUR lors de l'initialisation du paiement")
            print("═══════════════════════════════════════════════════════════")
            print("❌ [PAIEMENT] Type d'erreur: \(type(of: error))")
            print("❌ [PAIEMENT] Message: \(error.localizedDescription)")
            
            if let apiError = error as? APIError {
                print("❌ [PAIEMENT] Erreur API détectée")
                switch apiError {
                case .unauthorized(let reason):
                    print("❌ [PAIEMENT] Erreur 401 - Non autorisé")
                    if let reason = reason {
                        print("   - Raison: \(reason)")
                        errorMessage = apiError.errorDescription ?? "Erreur d'authentification. Veuillez vous reconnecter."
                        
                        if reason == "Token expired" || reason == "User not found" || reason == "Invalid token" {
                            print("⚠️ [PAIEMENT] Token invalide/expiré - Déconnexion forcée dans 2 secondes")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                LoginViewModel.logout()
                                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
                            }
                        }
                    } else {
                        errorMessage = "Erreur d'authentification. Veuillez vous reconnecter."
                    }
                case .networkError:
                    print("❌ [PAIEMENT] Erreur réseau")
                    errorMessage = "Erreur de connexion. Vérifiez votre connexion internet."
                case .invalidResponse:
                    print("❌ [PAIEMENT] Réponse invalide du serveur")
                    errorMessage = "Réponse invalide du serveur. Veuillez réessayer."
                default:
                    print("❌ [PAIEMENT] Autre erreur API")
                    errorMessage = "Erreur lors de l'initialisation du paiement. Veuillez réessayer."
                }
            } else {
                print("❌ [PAIEMENT] Erreur inconnue")
                errorMessage = "Erreur lors de l'initialisation du paiement. Veuillez réessayer."
            }
            print("═══════════════════════════════════════════════════════════")
            isProcessingPayment = false
        }
    }
    
    /// Étape C : Appelée après que le Payment Sheet renvoie .completed
    func handlePaymentSheetResult(success: Bool, error: String?) async {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [PAIEMENT] Résultat du Payment Sheet reçu")
        print("═══════════════════════════════════════════════════════════")
        
        isProcessingPayment = false
        showPaymentSheet = false
        
        if success {
            print("✅ [PAIEMENT] Paiement réussi dans le Payment Sheet Stripe")
            print("💳 [PAIEMENT] ÉTAPE 6 : Vérification du statut premium...")
            
            // Afficher l'écran "Activation en cours"
            isActivating = true
            print("   → Affichage de l'écran 'Activation en cours'")
            
            // Attendre un court délai pour que le webhook Stripe soit traité par le backend
            // Le backend met automatiquement à jour tous les champs (subscriptionType, renewalDate, etc.)
            print("   ⏳ Attente de 1 seconde pour laisser le webhook Stripe traiter le paiement...")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            print("   ✅ Délai écoulé, début de la vérification du statut")
            
            // Rafraîchir simplement les données utilisateur avec GET /api/v1/users/me
            // Le backend a déjà tout mis à jour, on vérifie juste que premiumEnabled est true
            // Option A simple : quelques retries si le réseau est lent (max 3 tentatives)
            print("💳 [PAIEMENT] ÉTAPE 7 : Vérification du statut premium (max 3 tentatives)")
            let isPremiumConfirmed = await PaymentStatusManager.shared.checkPaymentStatus(maxRetries: 3)
            
            // Masquer l'écran d'activation
            isActivating = false
            print("   → Masquage de l'écran 'Activation en cours'")
            
            if isPremiumConfirmed {
                // Afficher le message de succès
                showSuccessMessage = true
                print("═══════════════════════════════════════════════════════════")
                print("🎉 [PAIEMENT] ✅ SUCCÈS COMPLET DU PAIEMENT")
                print("═══════════════════════════════════════════════════════════")
                print("   ✅ Paiement validé par Stripe")
                print("   ✅ Statut premium confirmé par le backend")
                print("   ✅ Abonnement activé avec succès")
                
                // Récupérer le prix du plan choisi pour l'afficher dans PaymentResultView
                let planPrice = selectedPlan?.priceLabel
                
                // Notifier les autres parties de l'app avec le prix du plan
                NotificationCenter.default.post(
                    name: NSNotification.Name("PaymentSuccess"),
                    object: nil,
                    userInfo: planPrice != nil ? ["planPrice": planPrice!] : nil
                )
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                // Forcer le rechargement des données de la carte depuis le backend
                NotificationCenter.default.post(name: NSNotification.Name("ForceReloadCardData"), object: nil)
                // Naviguer vers l'onglet "Ma Carte" après un paiement réussi
                // Envoyer immédiatement pour que la navigation se fasse même si l'alert n'est pas encore fermé
                print("   📍 Envoi de la notification 'NavigateToCardAfterPayment' pour rediriger vers Ma Carte...")
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToCardAfterPayment"), object: nil)
                print("   ✅ Notification 'PaymentSuccess' envoyée avec planPrice: \(planPrice ?? "nil")")
                print("   ✅ Notification 'SubscriptionUpdated' envoyée")
                print("   ✅ Notification 'ForceReloadCardData' envoyée pour forcer le rechargement")
                print("   ✅ Notification 'NavigateToCardAfterPayment' envoyée pour rediriger vers Ma Carte")
                
                // Envoyer à nouveau après un court délai pour s'assurer que TabBarView la reçoit
                Task.detached {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                    await MainActor.run {
                        print("   📍 Envoi secondaire de 'NavigateToCardAfterPayment' pour garantir la navigation...")
                        NotificationCenter.default.post(name: NSNotification.Name("NavigateToCardAfterPayment"), object: nil)
                    }
                }
                
                // Masquer le message après 3 secondes (seulement si l'utilisateur ne l'a pas déjà fermé)
                // Utiliser Task.detached pour éviter "Publishing changes from within view updates"
                autoHideTask = Task.detached { [weak self] in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    // Vérifier que l'alert est toujours affichée avant de la fermer
                    await MainActor.run {
                        guard let self = self, self.showSuccessMessage else { return }
                        self.showSuccessMessage = false
                        print("   → Message de succès masqué automatiquement")
                    }
                }
            } else {
                // Le statut n'a pas été confirmé après tous les retries
                print("═══════════════════════════════════════════════════════════")
                print("⚠️ [PAIEMENT] Paiement réussi mais statut non confirmé")
                print("═══════════════════════════════════════════════════════════")
                print("   ✅ Paiement validé par Stripe")
                print("   ⚠️ Statut premium non confirmé après 3 tentatives")
                print("   → Le webhook peut prendre plus de temps")
                errorMessage = "Paiement réussi, mais la vérification du statut prend plus de temps que prévu. Veuillez rafraîchir votre profil dans quelques instants."
            }
        } else {
            // Le paiement a échoué ou a été annulé
            print("═══════════════════════════════════════════════════════════")
            print("❌ [PAIEMENT] ÉCHEC DU PAIEMENT")
            print("═══════════════════════════════════════════════════════════")
            if let error = error {
                print("   ❌ Erreur: \(error)")
                errorMessage = error
            } else {
                print("   ⚠️ Paiement annulé par l'utilisateur")
                errorMessage = "Paiement annulé"
            }
        }
        print("═══════════════════════════════════════════════════════════")
    }
}

// MARK: - Activation In Progress View
/// Écran affiché pendant la vérification du statut premium après paiement
struct ActivationInProgressView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background avec gradient
            AppGradient.main
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Indicateur de chargement animé
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0)
                
                // Titre
                Text("Activation en cours...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Description
                VStack(spacing: 8) {
                    Text("Paiement reçu, activation en cours...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Nous vérifions l'activation de votre abonnement avec le serveur.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Message informatif
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14))
                    
                    Text("Cela peut prendre quelques secondes")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

// MARK: - Stripe Payment Sheet Placeholder View
/// Wrapper pour le Payment Sheet Stripe
/// Une fois le SDK Stripe installé, ce composant utilisera le vrai Payment Sheet
struct StripePaymentSheetPlaceholderView: View {
    let clientSecret: String
    let onPaymentResult: (Bool, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Payment Sheet Stripe")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 40)
            
            Text("Pour activer le Payment Sheet Stripe :")
                .font(.system(size: 16))
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Installer le SDK Stripe iOS")
                Text("2. Décommenter le code dans StripeSubscriptionPaymentSheetView.swift")
                Text("3. Configurer votre clé publique Stripe")
            }
            .font(.system(size: 14))
            .padding()
            
            Button("Fermer") {
                onPaymentResult(false, "SDK Stripe non installé")
                dismiss()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // TODO: Une fois le SDK Stripe installé, remplacer ce placeholder par :
            // StripeSubscriptionPaymentSheetView(
            //     paymentIntentClientSecret: clientSecret,
            //     onPaymentResult: onPaymentResult
            // )
            // Note: customerId et ephemeralKeySecret sont optionnels pour un paiement unique
            print("[StripePaymentSheetPlaceholderView] Payment Intent créé avec clientSecret: \(clientSecret.prefix(20))...")
        }
    }
}

