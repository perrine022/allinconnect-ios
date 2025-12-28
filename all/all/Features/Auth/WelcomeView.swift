//
//  WelcomeView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct WelcomeView: View {
    let userName: String
    let userType: UserType
    let onComplete: () -> Void
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Animation de bienvenue
                VStack(spacing: 20) {
                    if showContent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.appGold)
                            .transition(.scale.combined(with: .opacity))
                        
                        Text("Bienvenue")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.opacity)
                        
                        Text("\(userName) !")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.appGold)
                            .transition(.opacity)
                        
                        Text(userType == .pro ? "Votre compte professionnel est prêt" : "Votre compte est prêt")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // Bouton Continuer
                if showContent {
                    Button(action: {
                        onComplete()
                    }) {
                        Text("Continuer")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appGold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

#Preview {
    WelcomeView(userName: "Marie", userType: .client, onComplete: {})
}

