//
//  ReferralsView.swift
//  all
//
//  Created by Perrine Honoré on 06/01/2026.
//

import SwiftUI

struct ReferralsView: View {
    @StateObject private var viewModel = ReferralsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background avec gradient
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Indicateur de chargement
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.vertical, 40)
                    }
                    
                    // Message d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    
                    // Liste des filleuls
                    if !viewModel.isLoading && viewModel.referrals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 48))
                            Text("Aucun filleul pour le moment")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if !viewModel.referrals.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(viewModel.referrals) { referral in
                                ReferralRow(referral: referral)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Mes filleuls")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Referral Row
struct ReferralRow: View {
    let referral: ReferralResponse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(referral.firstName) \(referral.lastName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(referral.email)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            // Badge récompense payée
            if referral.rewardPaid {
                Text("Récompense payée")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ReferralsView()
    }
}

