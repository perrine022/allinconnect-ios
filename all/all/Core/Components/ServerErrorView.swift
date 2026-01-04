//
//  ServerErrorView.swift
//  all
//
//  Created by Perrine Honoré on 04/01/2026.
//

import SwiftUI

struct ServerErrorView: View {
    var onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Image sympa avec icône de maintenance
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.appDarkRed1.opacity(0.3),
                                Color.appDarkRed2.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                // Icône de maintenance sympa
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appGold)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .padding(.bottom, 20)
            
            // Titre
            Text("Maintenance en cours")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Message
            VStack(spacing: 12) {
                Text("Nous travaillons actuellement")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("sur la remise en service")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("de l'application.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            // Message de retour
            Text("Nous serons de retour très rapidement !")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appGold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            
            // Bouton de retry (optionnel)
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Réessayer")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.appDarkRedButton)
                    .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appDarkRed2,
                    Color.appDarkRed1,
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }
}

// Extension pour détecter les erreurs 500
extension APIError {
    var isServerError: Bool {
        switch self {
        case .httpError(let statusCode, _):
            return statusCode >= 500 && statusCode < 600
        default:
            return false
        }
    }
    
    var statusCode: Int? {
        switch self {
        case .httpError(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }
}

// Helper pour vérifier si une erreur est une erreur serveur (500)
func isServerError(_ error: Error) -> Bool {
    if let apiError = error as? APIError {
        return apiError.isServerError
    }
    return false
}

#Preview {
    ServerErrorView {
        print("Retry tapped")
    }
}

