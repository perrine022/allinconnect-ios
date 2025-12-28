//
//  PaymentResultView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct PaymentResultView: View {
    let status: PaymentResultStatus
    @Environment(\.dismiss) private var dismiss
    
    enum PaymentResultStatus {
        case success
        case failed
        case pending
    }
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icône
                Image(systemName: statusIcon)
                    .font(.system(size: 80))
                    .foregroundColor(statusColor)
                    .padding(.bottom, 20)
                
                // Titre
                Text(statusTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
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

