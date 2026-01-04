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
    @Environment(\.dismiss) private var dismiss
    
    enum PaymentResultStatus {
        case success
        case failed
        case pending
    }
    
    init(status: PaymentResultStatus, planPrice: String? = nil) {
        self.status = status
        self.planPrice = planPrice
    }
    
    var body: some View {
        ZStack {
            // Background rouge (au lieu du gradient)
            Color.appDarkRed1
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo de l'app en haut
                if status == .success {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 20)
                }
                
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
                    dismiss()
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
            return "Votre abonnement a été activé avec succès. Vous pouvez maintenant profiter de tous les avantages !"
        case .failed:
            return "Le paiement n'a pas pu être effectué. Veuillez réessayer ou contacter le support."
        case .pending:
            return "Vérification du paiement en cours. Veuillez patienter..."
        }
    }
}

#Preview {
    PaymentResultView(status: .success)
}

