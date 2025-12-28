//
//  WalletView.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showAmountInput: Bool = false
    
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
                                Text("Ma Cagnotte")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // États de chargement et d'erreur - selon guidelines Apple
                            if viewModel.isLoading && !viewModel.hasLoadedOnce {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                        .scaleEffect(1.5)
                                    
                                    Text("Chargement de votre cagnotte...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.vertical, 100)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                            } else if viewModel.hasLoadedOnce {
                                // Montant total de la cagnotte
                                VStack(spacing: 12) {
                                    Text("Solde disponible")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("\(String(format: "%.2f", viewModel.walletBalance))€")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.appGold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.appDarkRed1.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.appGold.opacity(0.3), lineWidth: 2)
                                        )
                                )
                                .padding(.horizontal, 20)
                                
                                // Formulaire de décagnottage
                                if !viewModel.showProfessionalSelection {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Décagnotter")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Montant à dépenser de ma cagnotte (€):")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            TextField("", text: $viewModel.totalAmountToWithdraw, prompt: Text("0.00").foregroundColor(.gray.opacity(0.6)))
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                                .keyboardType(.decimalPad)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(Color.white)
                                                .cornerRadius(8)
                                            
                                            if !viewModel.totalAmountToWithdraw.isEmpty {
                                                if let amount = Double(viewModel.totalAmountToWithdraw), amount > viewModel.walletBalance {
                                                    Text("Le montant ne peut pas dépasser \(String(format: "%.2f", viewModel.walletBalance))€")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.red)
                                                } else if let amount = Double(viewModel.totalAmountToWithdraw), amount <= 0 {
                                                    Text("Le montant doit être supérieur à 0")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.red)
                                                }
                                            }
                                        }
                                        
                                        Button(action: {
                                            viewModel.startWithdrawal()
                                        }) {
                                            HStack {
                                                Spacer()
                                                Text("Décagnotter")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Spacer()
                                            }
                                            .padding(.vertical, 14)
                                            .background(viewModel.isValidWithdrawalAmount ? Color.appGold : Color.gray.opacity(0.5))
                                            .cornerRadius(10)
                                        }
                                        .disabled(!viewModel.isValidWithdrawalAmount || viewModel.isLoading)
                                    }
                                    .padding(16)
                                    .background(Color.appDarkRed1.opacity(0.8))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 20)
                                }
                                
                                // Liste des professionnels pour sélection (si on est en mode décagnottage)
                                if viewModel.showProfessionalSelection {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Sélectionner les professionnels")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Button(action: {
                                                viewModel.showProfessionalSelection = false
                                                viewModel.totalAmountToWithdraw = ""
                                                viewModel.selectedProfessionals = []
                                            }) {
                                                Text("Annuler")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                        }
                                        
                                        // Champs de recherche (ville et secteur) - en haut pour filtrer
                                        VStack(spacing: 6) {
                                            // Champ Ville, nom, activité
                                            HStack(spacing: 10) {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(.gray.opacity(0.6))
                                                    .font(.system(size: 13))
                                                
                                                TextField("", text: $viewModel.cityText, prompt: Text("Ville, nom, activité...").foregroundColor(.gray.opacity(0.6)))
                                                    .foregroundColor(.black)
                                                    .font(.system(size: 14))
                                                    .autocorrectionDisabled()
                                                    .textInputAutocapitalization(.never)
                                                    .onChange(of: viewModel.cityText) { _, _ in
                                                        viewModel.searchPartners()
                                                    }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 9)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            
                                            // Menu déroulant Secteur
                                            CustomSectorPicker(
                                                sectors: viewModel.sectors,
                                                selectedSector: $viewModel.selectedSector,
                                                onSelectionChange: {
                                                    viewModel.searchPartners()
                                                }
                                            )
                                            .zIndex(1000)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Montant total: \(viewModel.totalAmountToWithdraw)€")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            if viewModel.remainingAmount > 0 {
                                                Text("Montant restant: \(String(format: "%.2f", viewModel.remainingAmount))€")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.appGold)
                                            } else if viewModel.remainingAmount < 0 {
                                                Text("Dépassement: \(String(format: "%.2f", abs(viewModel.remainingAmount)))€")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.red)
                                            } else {
                                                Text("Montant total réparti ✓")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.selectedProfessionals) { selectedPro in
                                                WalletProfessionalSelectionRow(
                                                    selectedProfessional: selectedPro,
                                                    maxAmount: viewModel.maxAmountForProfessional(selectedPro),
                                                    remainingAmount: viewModel.remainingAmount,
                                                    onToggle: {
                                                        viewModel.toggleProfessionalSelection(selectedPro)
                                                    },
                                                    onAmountChange: { amount in
                                                        viewModel.updateProfessionalAmount(selectedPro, amount: amount)
                                                    }
                                                )
                                            }
                                        }
                                        
                                        Button(action: {
                                            Task {
                                                await viewModel.submitWithdrawalRequest()
                                            }
                                        }) {
                                            HStack {
                                                Spacer()
                                                Text("Envoyer")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Spacer()
                                            }
                                            .padding(.vertical, 14)
                                            .background(viewModel.canSubmitRequest && !viewModel.isLoading ? Color.appGold : Color.gray.opacity(0.5))
                                            .cornerRadius(10)
                                        }
                                        .disabled(!viewModel.canSubmitRequest || viewModel.isLoading)
                                    }
                                    .padding(16)
                                    .background(Color.appDarkRed1.opacity(0.8))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 20)
                                }
                                
                                // Message d'erreur
                                if let errorMessage = viewModel.errorMessage {
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 32))
                                        Text("Erreur")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(errorMessage)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                }
                                
                                // Message de succès
                                if let successMessage = viewModel.successMessage {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 32))
                                        Text("Succès")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        Text(successMessage)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            viewModel.successMessage = nil
                                        }
                                    }
                                }
                                
                                
                                // Section Historique
                                if !viewModel.walletHistory.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Historique")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        
                                        VStack(spacing: 8) {
                                            ForEach(viewModel.walletHistory.prefix(5)) { entry in
                                                WalletHistoryRow(entry: entry)
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
                                    .padding(.horizontal, 20)
                                }
                                
                                // Section Mes Demandes
                                if !viewModel.walletRequests.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Mes Demandes")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        
                                        VStack(spacing: 8) {
                                            ForEach(viewModel.walletRequests.prefix(5)) { request in
                                                WalletRequestRow(request: request)
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
                                    .padding(.horizontal, 20)
                                }
                                
                                Spacer()
                                    .frame(height: 100)
                            }
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
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Wallet Professional Selection Row
struct WalletProfessionalSelectionRow: View {
    let selectedProfessional: SelectedProfessional
    let maxAmount: Double
    let remainingAmount: Double
    let onToggle: () -> Void
    let onAmountChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Case à cocher
                Button(action: onToggle) {
                    Image(systemName: selectedProfessional.isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(selectedProfessional.isSelected ? .appGold : .white.opacity(0.6))
                        .font(.system(size: 24))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Informations du professionnel
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedProfessional.partner.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(selectedProfessional.partner.category)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if !selectedProfessional.partner.city.isEmpty {
                        Text(selectedProfessional.partner.city)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // Champ de montant (visible seulement si sélectionné)
            if selectedProfessional.isSelected {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Montant (€):")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        if maxAmount > 0 {
                            Text("Max: \(String(format: "%.2f", maxAmount))€")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    TextField("", text: Binding(
                        get: { selectedProfessional.amount },
                        set: { newValue in
                            // Limiter automatiquement au montant maximum disponible
                            if let amount = Double(newValue), amount > maxAmount {
                                onAmountChange(String(format: "%.2f", maxAmount))
                            } else {
                                onAmountChange(newValue)
                            }
                        }
                    ), prompt: Text("0.00").foregroundColor(.gray.opacity(0.6)))
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                        .keyboardType(.decimalPad)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    (Double(selectedProfessional.amount) ?? 0) > maxAmount ? Color.red : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    
                    if let amount = Double(selectedProfessional.amount), amount > maxAmount {
                        Text("Le montant dépasse le montant maximum disponible (\(String(format: "%.2f", maxAmount))€)")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
                .padding(.leading, 36) // Aligner avec le texte du professionnel
            }
        }
        .padding(12)
        .background(selectedProfessional.isSelected ? Color.appGold.opacity(0.2) : Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedProfessional.isSelected ? Color.appGold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Wallet History Row
struct WalletHistoryRow: View {
    let entry: WalletHistoryEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                if let userName = entry.userName {
                    Text("Par \(userName)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(entry.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text("\(entry.isPositive ? "+" : "")\(entry.formattedAmount)€")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(entry.isPositive ? .green : .red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Wallet Request Row
struct WalletRequestRow: View {
    let request: WalletRequestEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.professionals)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(request.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(request.formattedAmount)€")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appGold)
                    
                    Text(request.statusLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(request.statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(request.statusColor.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WalletPartnerCard: View {
    let partner: Partner
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Image
                Image(systemName: partner.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.gray.opacity(0.3))
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appDarkRed1.opacity(0.3), Color.appDarkRed2.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text(partner.category)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if !partner.city.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.appRed)
                                .font(.system(size: 11))
                            Text(partner.city)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Indicateur de sélection
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appGold)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 14))
                }
            }
            .padding(12)
            .background(isSelected ? Color.appGold.opacity(0.2) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        WalletView()
            .environmentObject(AppState())
    }
}

