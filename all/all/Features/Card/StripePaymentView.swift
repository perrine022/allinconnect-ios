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
    @State private var selectedPlan: SubscriptionPlanResponse?
    @State private var showSafari = false
    @State private var stripePaymentURL: URL?
    
    var body: some View {
        ZStack {
            // Background avec gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appDarkRed2,
                    Color.appDarkRed1,
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
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
                    
                    // Indicateur de chargement
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                            .scaleEffect(1.5)
                            .padding(.vertical, 40)
                    }
                    
                    // Liste des plans
                    if !viewModel.plans.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(viewModel.plans) { plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: selectedPlan?.id == plan.id,
                                    onSelect: {
                                        selectedPlan = plan
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
                    if let selectedPlan = selectedPlan {
                        Button(action: {
                            viewModel.openStripePaymentLink(plan: selectedPlan) { url in
                                stripePaymentURL = url
                                showSafari = true
                            }
                        }) {
                            HStack {
                                if viewModel.isProcessingPayment {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Payer \(String(format: "%.2f€", selectedPlan.price))")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isProcessingPayment ? Color.gray.opacity(0.5) : Color.appGold)
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
        .onAppear {
            viewModel.loadPlans()
        }
        .sheet(isPresented: $showSafari) {
            if let url = stripePaymentURL {
                SafariView(url: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StripePaymentSuccess"))) { _ in
            // Recharger les données après paiement réussi
            viewModel.handlePaymentSuccess()
            dismiss()
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
                        
                        Text(String(format: "%.2f€", plan.price))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.appGold)
                    }
                    
                    Spacer()
                    
                    // Badge type
                    Text(plan.category == "FAMILY" ? "Famille" : "Individuel")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appGold)
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
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Accès à tous les avantages")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                        Text("• Carte digitale personnelle")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(20)
            .background(isSelected ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appGold : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Safari View Controller Wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.delegate = context.coordinator
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // L'utilisateur a fermé Safari
        }
    }
}

// MARK: - ViewModel
@MainActor
class StripePaymentViewModel: ObservableObject {
    @Published var plans: [SubscriptionPlanResponse] = []
    @Published var isLoading: Bool = false
    @Published var isProcessingPayment: Bool = false
    @Published var errorMessage: String?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    
    // URL de base pour les Payment Links Stripe (fallback si le backend n'est pas disponible)
    private let stripePaymentLinkBaseURL = "https://buy.stripe.com/test_"
    
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
                plans = try await subscriptionsAPIService.getPlans()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Erreur lors du chargement des plans"
                print("Erreur lors du chargement des plans: \(error)")
            }
        }
    }
    
    func openStripePaymentLink(plan: SubscriptionPlanResponse, completion: @escaping (URL) -> Void) {
        isProcessingPayment = true
        errorMessage = nil
        
        Task {
            do {
                // Récupérer l'URL du Payment Link depuis le backend
                var paymentLinkURL = try await subscriptionsAPIService.getStripePaymentLink(planId: plan.id)
                
                // Récupérer l'email de l'utilisateur depuis UserDefaults
                let userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
                
                // Ajouter les paramètres URL
                guard var components = URLComponents(string: paymentLinkURL) else {
                    errorMessage = "URL de paiement invalide"
                    isProcessingPayment = false
                    return
                }
                
                var queryItems = components.queryItems ?? []
                
                // Ajouter l'email prérempli si disponible
                if !userEmail.isEmpty {
                    queryItems.append(URLQueryItem(name: "prefilled_email", value: userEmail))
                }
                
                // Ajouter un client_reference_id pour identifier l'utilisateur
                if let userId = UserDefaults.standard.string(forKey: "user_id") {
                    queryItems.append(URLQueryItem(name: "client_reference_id", value: userId))
                } else {
                    // Utiliser l'email comme référence si pas d'ID utilisateur
                    if !userEmail.isEmpty {
                        queryItems.append(URLQueryItem(name: "client_reference_id", value: userEmail))
                    }
                }
                
                components.queryItems = queryItems
                
                guard let finalURL = components.url else {
                    errorMessage = "Erreur lors de la création du lien de paiement"
                    isProcessingPayment = false
                    return
                }
                
                await MainActor.run {
                    isProcessingPayment = false
                    completion(finalURL)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors de la récupération du lien de paiement"
                    isProcessingPayment = false
                    print("Erreur lors de la récupération du lien de paiement: \(error)")
                    
                    // Fallback: utiliser une URL de test si le backend n'est pas disponible
                    let userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
                    var fallbackURL = "\(stripePaymentLinkBaseURL)\(plan.id)"
                    
                    if var components = URLComponents(string: fallbackURL) {
                        var queryItems: [URLQueryItem] = []
                        if !userEmail.isEmpty {
                            queryItems.append(URLQueryItem(name: "prefilled_email", value: userEmail))
                        }
                        components.queryItems = queryItems
                        if let url = components.url {
                            completion(url)
                        }
                    }
                }
            }
        }
    }
    
    func handlePaymentSuccess() {
        // Recharger les données d'abonnement après un paiement réussi
        // Cette fonction sera appelée quand le webhook Stripe confirmera le paiement
        // Pour l'instant, on peut juste notifier l'utilisateur
        NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
    }
}

