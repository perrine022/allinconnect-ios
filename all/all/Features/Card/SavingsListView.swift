//
//  SavingsListView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct SavingsListView: View {
    @StateObject private var viewModel = CardViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showAddSavingsPopup = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 20) {
                            // Titre
                            HStack {
                                Text("Mes économies")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Total des économies
                            VStack(spacing: 8) {
                                Text("Total")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("\(String(format: "%.2f", viewModel.savings))€")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.appGold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appDarkRed1.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.appGold.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                            
                            // Liste des économies
                            if viewModel.savingsEntries.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "banknote")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.system(size: 48))
                                    Text("Aucune économie enregistrée")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.savingsEntries.sorted(by: { $0.date > $1.date })) { entry in
                                        SavingsRow(entry: entry)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Bouton ajouter
                            Button(action: {
                                showAddSavingsPopup = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Ajouter une économie")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appGold)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
        .sheet(isPresented: $showAddSavingsPopup) {
            AddSavingsPopupView(isPresented: $showAddSavingsPopup) { amount, date, store in
                viewModel.addSavings(amount: amount, date: date, store: store)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct SavingsRow: View {
    let entry: SavingsEntry
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(Color.appGold.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "banknote.fill")
                    .foregroundColor(.appGold)
                    .font(.system(size: 20))
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.store)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                        Text(formattedDate)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Montant
            Text("\(String(format: "%.2f", entry.amount))€")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appGold)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        SavingsListView()
            .environmentObject(AppState())
    }
}

