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
                                
                                // Champs de recherche
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
                                .padding(.horizontal, 20)
                                
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
                                
                                // Liste des professionnels
                                if viewModel.errorMessage == nil {
                                    if viewModel.filteredPartners.isEmpty {
                                        VStack(spacing: 12) {
                                            Image(systemName: "person.3.fill")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .font(.system(size: 48))
                                            Text("Aucun professionnel trouvé")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                    } else {
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.filteredPartners) { partner in
                                                WalletPartnerCard(
                                                    partner: partner,
                                                    isSelected: viewModel.selectedPartner?.id == partner.id,
                                                    onSelect: {
                                                        viewModel.selectedPartner = partner
                                                        showAmountInput = true
                                                    }
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                
                                // Formulaire de demande (si un professionnel est sélectionné)
                                if let selectedPartner = viewModel.selectedPartner {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Demande d'utilisation")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Professionnel sélectionné:")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Text(selectedPartner.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.appGold)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Montant (€):")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            TextField("", text: $viewModel.selectedAmount, prompt: Text("0.00").foregroundColor(.gray.opacity(0.6)))
                                                .foregroundColor(.black)
                                                .font(.system(size: 16))
                                                .keyboardType(.decimalPad)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(Color.white)
                                                .cornerRadius(8)
                                        }
                                        
                                        Button(action: {
                                            Task {
                                                await viewModel.createWalletRequest()
                                            }
                                        }) {
                                            HStack {
                                                Spacer()
                                                Text("Créer la demande")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Spacer()
                                            }
                                            .padding(.vertical, 14)
                                            .background(viewModel.isValidRequest ? Color.appGold : Color.gray.opacity(0.5))
                                            .cornerRadius(10)
                                        }
                                        .disabled(!viewModel.isValidRequest || viewModel.isLoading)
                                        
                                        Button(action: {
                                            viewModel.selectedPartner = nil
                                            viewModel.selectedAmount = ""
                                        }) {
                                            HStack {
                                                Spacer()
                                                Text("Annuler")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                                Spacer()
                                            }
                                            .padding(.vertical, 10)
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

