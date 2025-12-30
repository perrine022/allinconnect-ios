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
    
    // Paramètre optionnel pour filtrer les plans par catégorie
    var filterCategory: String? = nil // "PROFESSIONAL", "INDIVIDUAL", "FAMILY", ou "CLIENT" (INDIVIDUAL + FAMILY)
    
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
                    
                    // Message incitatif pour la carte famille (quand on est sur CLIENT)
                    if filterCategory == "CLIENT" {
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
            if let clientSecret = viewModel.paymentIntentClientSecret {
                StripeSubscriptionPaymentSheetView(
                    paymentIntentClientSecret: clientSecret,
                    onPaymentResult: { success, error in
                        Task { @MainActor in
                            await viewModel.handlePaymentSheetResult(success: success, error: error)
                        }
                    },
                    customerId: viewModel.customerId,
                    ephemeralKeySecret: viewModel.ephemeralKeySecret
                )
            }
        }
        .sheet(isPresented: $viewModel.isActivating) {
            ActivationInProgressView()
        }
        .alert("🎉 Félicitations !", isPresented: $viewModel.showSuccessMessage) {
            Button("OK", role: .cancel) {
                viewModel.showSuccessMessage = false
            }
        } message: {
            Text("Votre abonnement a été activé avec succès. Vous êtes maintenant Premium !")
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlanResponse
    let isSelected: Bool
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
                        Text("• Pensez à la carte famille !")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .italic()
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
    @Published var paymentIntentClientSecret: String? = nil
    @Published var customerId: String? = nil
    @Published var ephemeralKeySecret: String? = nil
    @Published var showSuccessMessage: Bool = false
    @Published var isActivating: Bool = false // État pour l'écran "Activation en cours"
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let billingAPIService = BillingAPIService()
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
                let allPlans = try await subscriptionsAPIService.getPlans()
                print("[StripePaymentViewModel] Plans récupérés depuis l'API: \(allPlans.count) plans")
                for plan in allPlans {
                    print("  - \(plan.title): \(plan.formattedPrice) (\(plan.category ?? "N/A") - \(plan.duration ?? "N/A"))")
                }
                
                // Filtrer les plans si une catégorie est spécifiée
                if let filterCategory = filterCategory {
                    if filterCategory == "CLIENT" {
                        // Pour les clients, afficher INDIVIDUAL et FAMILY
                        plans = allPlans.filter { $0.category == "INDIVIDUAL" || $0.category == "FAMILY" }
                        print("[StripePaymentViewModel] Plans filtrés pour 'CLIENT' (INDIVIDUAL + FAMILY): \(plans.count) plans")
                    } else {
                        plans = allPlans.filter { $0.category == filterCategory }
                        print("[StripePaymentViewModel] Plans filtrés pour '\(filterCategory)': \(plans.count) plans")
                    }
                } else {
                    plans = allPlans
                }
                
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
    
    // MARK: - Stripe Payment Sheet Integration (Étapes A, B, C)
    
    /// Étape A : Récupérer les secrets depuis le backend
    /// Étape B : Configurer et présenter le Payment Sheet
    /// Étape C : Vérifier le statut après paiement réussi
    func processPaymentWithStripeSheet(plan: SubscriptionPlanResponse) async {
        isProcessingPayment = true
        errorMessage = nil
        
        do {
            // ÉTAPE A : Appeler POST /api/billing/subscription/start
            print("[StripePaymentViewModel] Étape A : Démarrage de l'abonnement pour planId=\(plan.id)")
            let startSubscriptionResponse = try await billingAPIService.startSubscription()
            
            print("[StripePaymentViewModel] ✅ Secrets récupérés avec succès")
            print("[StripePaymentViewModel]   - customerId: \(startSubscriptionResponse.customerId)")
            print("[StripePaymentViewModel]   - subscriptionId: \(startSubscriptionResponse.subscriptionId)")
            print("[StripePaymentViewModel]   - paymentIntentClientSecret: \(startSubscriptionResponse.paymentIntentClientSecret.prefix(20))...")
            print("[StripePaymentViewModel]   - ephemeralKeySecret: \(startSubscriptionResponse.ephemeralKeySecret.prefix(20))...")
            
            // Stocker les secrets pour le Payment Sheet
            customerId = startSubscriptionResponse.customerId
            ephemeralKeySecret = startSubscriptionResponse.ephemeralKeySecret
            paymentIntentClientSecret = startSubscriptionResponse.paymentIntentClientSecret
            
            // ÉTAPE B : Présenter le Payment Sheet
            print("[StripePaymentViewModel] Étape B : Présentation du Payment Sheet")
            showPaymentSheet = true
            
        } catch {
            print("[StripePaymentViewModel] ❌ Erreur lors du démarrage de l'abonnement: \(error)")
            
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized(let reason):
                    // Afficher le message d'erreur précis du backend
                    if let reason = reason {
                        errorMessage = apiError.errorDescription ?? "Erreur d'authentification. Veuillez vous reconnecter."
                        print("[StripePaymentViewModel] Raison de l'erreur 401: \(reason)")
                        
                        // Si le token est expiré ou l'utilisateur n'existe plus, forcer la déconnexion
                        if reason == "Token expired" || reason == "User not found" || reason == "Invalid token" {
                            print("[StripePaymentViewModel] ⚠️ Token invalide/expiré - Déconnexion forcée")
                            // Forcer la déconnexion après un court délai pour permettre l'affichage du message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                LoginViewModel.logout()
                                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
                            }
                        }
                    } else {
                        errorMessage = "Erreur d'authentification. Veuillez vous reconnecter."
                    }
                case .networkError:
                    errorMessage = "Erreur de connexion. Vérifiez votre connexion internet."
                case .invalidResponse:
                    errorMessage = "Réponse invalide du serveur. Veuillez réessayer."
                default:
                    errorMessage = "Erreur lors de l'initialisation du paiement. Veuillez réessayer."
                }
            } else {
                errorMessage = "Erreur lors de l'initialisation du paiement. Veuillez réessayer."
            }
            isProcessingPayment = false
        }
    }
    
    /// Étape C : Appelée après que le Payment Sheet renvoie .completed
    func handlePaymentSheetResult(success: Bool, error: String?) async {
        isProcessingPayment = false
        showPaymentSheet = false
        
        if success {
            print("[StripePaymentViewModel] ✅ Paiement réussi dans le Payment Sheet")
            print("[StripePaymentViewModel] Étape C : Vérification du statut premium...")
            
            // Afficher l'écran "Activation en cours"
            isActivating = true
            
            // Attendre 0.5 seconde pour que le webhook soit traité
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Utiliser PaymentStatusManager avec retry amélioré (7 tentatives avec backoff exponentiel)
            // Source de vérité : GET /api/billing/status (pas /users/me/light)
            let isPremiumConfirmed = await PaymentStatusManager.shared.checkPaymentStatus(maxRetries: 7)
            
            // Masquer l'écran d'activation
            isActivating = false
            
            if isPremiumConfirmed {
                // Afficher le message de succès
                showSuccessMessage = true
                print("[StripePaymentViewModel] 🎉 Statut premium confirmé !")
                
                // Notifier les autres parties de l'app
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
                
                // Masquer le message après 3 secondes
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    showSuccessMessage = false
                }
            } else {
                // Le statut n'a pas été confirmé après tous les retries
                errorMessage = "Paiement réussi, mais la vérification du statut prend plus de temps que prévu. Veuillez rafraîchir votre profil dans quelques instants."
                print("[StripePaymentViewModel] ⚠️ Statut premium non confirmé après tous les retries")
            }
        } else {
            // Le paiement a échoué ou a été annulé
            if let error = error {
                errorMessage = error
                print("[StripePaymentViewModel] ❌ Paiement échoué: \(error)")
            } else {
                errorMessage = "Paiement annulé"
                print("[StripePaymentViewModel] ⚠️ Paiement annulé par l'utilisateur")
            }
        }
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

