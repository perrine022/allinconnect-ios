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
                            // Ouvrir le Payment Link Stripe dans Safari
                            viewModel.openPaymentLink(plan: selectedPlan)
                            showSafari = true
                        }) {
                            HStack {
                                Text("Payer \(selectedPlan.formattedPrice)")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
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
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    
    // Payment Link Stripe fourni
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
}

