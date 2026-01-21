//
//  PaymentResultView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct PaymentResultView: View {
    let status: PaymentResultStatus
    let planPrice: String? // Prix du plan choisi (ex: "9,99€ / mois")
    let planCategory: String? // Catégorie du plan (ex: "PROFESSIONAL", "INDIVIDUAL", "FAMILY")
    let onDismiss: (() -> Void)? // Callback appelé quand l'utilisateur ferme la popup
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    enum PaymentResultStatus {
        case success
        case failed
        case pending
    }
    
    init(status: PaymentResultStatus, planPrice: String? = nil, planCategory: String? = nil, onDismiss: (() -> Void)? = nil) {
        self.status = status
        self.planPrice = planPrice
        self.planCategory = planCategory
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Background rouge (au lieu du gradient)
            Color.appDarkRed1
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icône de statut
                Image(systemName: statusIcon)
                    .font(.system(size: 80))
                    .foregroundColor(statusColor)
                    .padding(.bottom, 20)
                
                // Titre
                Text(statusTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Prix du plan (uniquement si succès et prix disponible)
                if status == .success, let price = planPrice {
                    Text(price)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appGold)
                        .padding(.top, 8)
                }
                
                // Message
                Text(statusMessage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Bouton
                Button(action: {
                    // Appeler le callback si fourni
                    onDismiss?()
                    
                    // Vérifier si l'utilisateur est un professionnel
                    // Priorité 1: Vérifier la catégorie du plan qui vient d'être payé
                    // Priorité 2: Vérifier dans UserDefaults
                    var isPro = false
                    
                    if let planCategory = planCategory, planCategory == "PROFESSIONAL" {
                        // Si on vient de payer un plan PROFESSIONAL, c'est qu'on est pro
                        isPro = true
                    } else {
                        // Sinon, vérifier dans UserDefaults
                        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
                        isPro = userTypeString == "PRO" || userTypeString == "PROFESSIONAL"
                    }
                    
                    if isPro && status == .success {
                        // Pour les pros après un paiement réussi, rediriger vers "Gérer mon établissement"
                        // D'abord naviguer vers l'onglet Profil
                        appState.navigateToTab(.profile)
                        
                        // Ensuite, après un court délai, déclencher la navigation vers ManageEstablishmentView
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Envoyer une notification pour déclencher la navigation vers ManageEstablishmentView
                            NotificationCenter.default.post(name: NSNotification.Name("NavigateToManageEstablishment"), object: nil)
                        }
                    } else if status == .success {
                        // Pour les clients particuliers après un paiement réussi, naviguer vers la page d'accueil
                        appState.navigateToTab(.home)
                    } else {
                        // En cas d'échec, naviguer vers l'accueil
                        appState.navigateToTab(.home)
                    }
                    
                    // Fermer la vue après un court délai pour laisser la navigation se faire
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    Text("Fermer")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appGold)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .pending:
            return "clock.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .success:
            return .green
        case .failed:
            return .red
        case .pending:
            return .orange
        }
    }
    
    private var statusTitle: String {
        switch status {
        case .success:
            return "Paiement réussi !"
        case .failed:
            return "Paiement échoué"
        case .pending:
            return "Paiement en cours..."
        }
    }
    
    private var statusMessage: String {
        switch status {
        case .success:
            return "Ton abonnement a été activé avec succès. Tu peux maintenant profiter de tous les avantages !"
        case .failed:
            return "Le paiement n'a pas pu être effectué. Réessaye ou contacte le support."
        case .pending:
            return "Vérification du paiement en cours. Patient un peu..."
        }
    }
}

#Preview {
    PaymentResultView(status: .success)
}

