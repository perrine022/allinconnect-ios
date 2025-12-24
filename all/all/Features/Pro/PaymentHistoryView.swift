//
//  PaymentHistoryView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

struct PaymentHistoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaymentHistoryViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
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
                            HStack {
                                Text("Historique des paiements")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Liste des paiements
                            if viewModel.payments.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text("Aucun paiement")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Votre historique de paiements apparaîtra ici")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.payments) { payment in
                                        PaymentRow(payment: payment)
                                    }
                                }
                                .padding(.horizontal, 20)
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
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(Color.appGold.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.appGold)
                    .font(.system(size: 20))
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 6) {
                Text(payment.description)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(payment.date)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                if let reference = payment.reference {
                    Text("Réf: \(reference)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Montant
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.amount)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appGold)
                
                HStack(spacing: 4) {
                    Image(systemName: payment.status == .success ? "checkmark.circle.fill" : payment.status == .pending ? "clock.fill" : "xmark.circle.fill")
                        .foregroundColor(payment.status == .success ? .green : payment.status == .pending ? .orange : .red)
                        .font(.system(size: 12))
                    
                    Text(payment.status.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(payment.status == .success ? .green : payment.status == .pending ? .orange : .red)
                }
            }
        }
        .padding(16)
        .background(Color.appDarkRed1.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct Payment: Identifiable {
    let id: UUID
    let date: String
    let amount: String
    let description: String
    let status: PaymentStatus
    let reference: String?
    
    init(
        id: UUID = UUID(),
        date: String,
        amount: String,
        description: String,
        status: PaymentStatus,
        reference: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.description = description
        self.status = status
        self.reference = reference
    }
}

enum PaymentStatus: String {
    case success = "Payé"
    case pending = "En attente"
    case failed = "Échoué"
}

@MainActor
class PaymentHistoryViewModel: ObservableObject {
    @Published var payments: [Payment] = []
    
    init() {
        loadPayments()
    }
    
    func loadPayments() {
        // Données de test
        payments = [
            Payment(
                date: "15/01/2026",
                amount: "49,90€",
                description: "Abonnement Mensuel",
                status: .success,
                reference: "PAY-2026-001"
            ),
            Payment(
                date: "15/12/2025",
                amount: "49,90€",
                description: "Abonnement Mensuel",
                status: .success,
                reference: "PAY-2025-012"
            ),
            Payment(
                date: "15/11/2025",
                amount: "49,90€",
                description: "Abonnement Mensuel",
                status: .success,
                reference: "PAY-2025-011"
            )
        ]
    }
}

#Preview {
    NavigationStack {
        PaymentHistoryView()
            .environmentObject(AppState())
    }
}

