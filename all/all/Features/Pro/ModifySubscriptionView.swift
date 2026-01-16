//
//  ModifySubscriptionView.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI
import Combine

struct ModifySubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ModifySubscriptionViewModel()
    let currentPlanId: Int? // ID du plan actuel à exclure
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Titre
                            HStack {
                                Text("Modifier mon abonnement")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Indicateur de chargement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            }
                            
                            // Message d'erreur
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Message de succès
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Plans d'abonnement disponibles (excluant le plan actuel)
                            if !viewModel.availablePlans.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Choisissez votre nouvel abonnement")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.availablePlans) { plan in
                                            Button(action: {
                                                viewModel.selectedPlan = plan
                                            }) {
                                                VStack(alignment: .leading, spacing: 12) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(plan.formattedPrice)
                                                                .font(.system(size: 32, weight: .bold))
                                                                .foregroundColor(.white)
                                                            
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(plan.isMonthly ? "par mois" : "par an")
                                                                    .font(.system(size: 16, weight: .regular))
                                                                    .foregroundColor(.white.opacity(0.8))
                                                                
                                                                if plan.isMonthly {
                                                                    Text("(engagement 6 mois)")
                                                                        .font(.system(size: 12, weight: .regular))
                                                                        .foregroundColor(.white.opacity(0.6))
                                                                } else if plan.isAnnual {
                                                                    Text("2 mois offerts 🎉")
                                                                        .font(.system(size: 12, weight: .semibold))
                                                                        .foregroundColor(.appGold)
                                                                }
                                                            }
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Image(systemName: "star.fill")
                                                            .foregroundColor(.appGold)
                                                            .font(.system(size: 28))
                                                    }
                                                    
                                                    Divider()
                                                        .background(Color.white.opacity(0.2))
                                                    
                                                    Text(plan.title)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.white.opacity(0.9))
                                                    
                                                    if let description = plan.description {
                                                        Text(description)
                                                            .font(.system(size: 12, weight: .regular))
                                                            .foregroundColor(.white.opacity(0.7))
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(20)
                                                .background(viewModel.selectedPlan?.id == plan.id ? Color.appDarkRed1.opacity(0.9) : Color.appDarkRed1.opacity(0.8))
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(viewModel.selectedPlan?.id == plan.id ? Color.appGold : Color.clear, lineWidth: 2)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            } else if !viewModel.isLoading {
                                Text("Aucun autre plan disponible")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            }
                            
                            // Bouton Modifier l'abonnement
                            if !viewModel.availablePlans.isEmpty {
                                Button(action: {
                                    Task {
                                        await viewModel.modifySubscription()
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isModifying {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        } else {
                                            if let selectedPlan = viewModel.selectedPlan {
                                                Text("Modifier l'abonnement - \(selectedPlan.priceLabel)")
                                                    .font(.system(size: 16, weight: .bold))
                                            } else {
                                                Text("Sélectionnez un plan")
                                                    .font(.system(size: 16, weight: .bold))
                                            }
                                        }
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.isModifying || viewModel.selectedPlan == nil ? Color.gray.opacity(0.5) : Color.appGold)
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.isModifying || viewModel.selectedPlan == nil)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {
                            dismiss()
                        })
                    }
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .task {
            await viewModel.loadAvailablePlans(excludingPlanId: currentPlanId)
        }
        .onReceive(viewModel.$successMessage) { successMessage in
            // Fermer la vue après un délai si la modification réussit
            if successMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

@MainActor
class ModifySubscriptionViewModel: ObservableObject {
    @Published var availablePlans: [SubscriptionPlanResponse] = []
    @Published var selectedPlan: SubscriptionPlanResponse? = nil
    @Published var isLoading: Bool = false
    @Published var isModifying: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let subscriptionsAPIService: SubscriptionsAPIService
    private let profileAPIService: ProfileAPIService
    
    init(
        subscriptionsAPIService: SubscriptionsAPIService? = nil,
        profileAPIService: ProfileAPIService? = nil
    ) {
        if let subscriptionsAPIService = subscriptionsAPIService {
            self.subscriptionsAPIService = subscriptionsAPIService
        } else {
            self.subscriptionsAPIService = SubscriptionsAPIService()
        }
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
    }
    
    func loadAvailablePlans(excludingPlanId: Int?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Déterminer le type d'utilisateur
            let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
            let isPro = userTypeString == "PROFESSIONAL" || userTypeString == "PRO"
            
            // Récupérer tous les plans
            let allPlans = try await subscriptionsAPIService.getPlans()
            
            // Filtrer selon le type d'utilisateur
            let filteredPlans: [SubscriptionPlanResponse]
            if isPro {
                filteredPlans = allPlans.filter { $0.category == "PROFESSIONAL" }
            } else {
                filteredPlans = allPlans.filter { $0.category == "INDIVIDUAL" || $0.category == "FAMILY" }
            }
            
            // Exclure le plan actuel
            if let excludingPlanId = excludingPlanId {
                availablePlans = filteredPlans.filter { $0.id != excludingPlanId }
            } else {
                availablePlans = filteredPlans
            }
            
            // Sélectionner le premier plan par défaut
            if selectedPlan == nil && !availablePlans.isEmpty {
                selectedPlan = availablePlans.first
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement des plans: \(error.localizedDescription)"
            print("Erreur lors du chargement des plans: \(error)")
        }
    }
    
    func modifySubscription() async {
        guard let selectedPlan = selectedPlan else {
            errorMessage = "Veuillez sélectionner un plan"
            return
        }
        
        isModifying = true
        errorMessage = nil
        successMessage = nil
        
        print("═══════════════════════════════════════════════════════════")
        print("💳 [MODIFY SUBSCRIPTION] modifySubscription() - Début")
        print("💳 [MODIFY SUBSCRIPTION] Plan sélectionné: ID=\(selectedPlan.id), Titre=\(selectedPlan.title)")
        print("═══════════════════════════════════════════════════════════")
        
        do {
            // Appeler l'endpoint switch
            try await subscriptionsAPIService.switchSubscription(planId: selectedPlan.id)
            
            print("💳 [MODIFY SUBSCRIPTION] ✅ Abonnement modifié avec succès")
            print("═══════════════════════════════════════════════════════════")
            
            isModifying = false
            successMessage = "Votre abonnement a été modifié avec succès. Le nouveau tarif sera appliqué lors de la prochaine échéance."
            
            // Notifier la mise à jour
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            
            // Fermer la vue après 2 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // La vue sera fermée automatiquement via le dismiss dans le parent
            }
        } catch {
            print("💳 [MODIFY SUBSCRIPTION] ❌ Erreur: \(error.localizedDescription)")
            print("═══════════════════════════════════════════════════════════")
            isModifying = false
            errorMessage = "Erreur lors de la modification de l'abonnement: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ModifySubscriptionView(currentPlanId: nil)
            .environmentObject(AppState())
    }
}
