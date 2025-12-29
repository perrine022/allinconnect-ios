//
//  SavingsListView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct SavingsListView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showAddSavingsPopup = false
    @State private var showEditSavingsPopup = false
    @State private var editingEntry: SavingsEntry? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
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
                                    .foregroundColor(.appRed)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appDarkRed1.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.appRed.opacity(0.3), lineWidth: 1)
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
                                        SavingsRow(
                                            entry: entry,
                                            onEdit: {
                                                editingEntry = entry
                                                showEditSavingsPopup = true
                                            },
                                            onDelete: {
                                                viewModel.deleteSavings(entry: entry)
                                            }
                                        )
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
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appRed)
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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe vers la droite (translation.width > 0) pour revenir en arrière
                    if value.translation.width > 50 && abs(value.translation.width) > abs(value.translation.height) {
                        dismiss()
                    }
                }
        )
        .sheet(isPresented: $showAddSavingsPopup) {
            AddSavingsPopupView(
                isPresented: $showAddSavingsPopup,
                onSave: { amount, date, store, description in
                    viewModel.addSavings(amount: amount, date: date, store: store, description: description)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditSavingsPopup) {
            if let entry = editingEntry {
                AddSavingsPopupView(
                    isPresented: $showEditSavingsPopup,
                    onSave: { amount, date, store, description in
                        viewModel.updateSavings(entry: entry, amount: amount, date: date, store: store, description: description)
                    },
                    editingEntry: entry
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.loadSavings()
        }
    }
}

struct SavingsRow: View {
    let entry: SavingsEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
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
                    .fill(Color.appRed.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "banknote.fill")
                    .foregroundColor(.appRed)
                    .font(.system(size: 20))
            }
            
            // Informations
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.store)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let description = entry.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
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
                .foregroundColor(.appRed)
            
            // Boutons d'action
            Menu {
                Button(action: onEdit) {
                    Label("Modifier", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Supprimer", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 16))
                    .padding(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appRed.opacity(0.2), lineWidth: 1)
                )
        )
        .alert("Supprimer l'économie", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cette économie ?")
        }
    }
}

#Preview {
    NavigationStack {
        SavingsListView(viewModel: CardViewModel())
            .environmentObject(AppState())
    }
}

