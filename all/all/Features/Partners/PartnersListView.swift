//
//  PartnersListView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import CoreLocation

struct PartnersListView: View {
    @StateObject private var viewModel = PartnersListViewModel()
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var appState: AppState
    @State private var selectedPartner: Partner?
    @State private var showLocationPermission = false
    
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
                        Text("Nos partenaires")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if !viewModel.filteredPartners.isEmpty {
                            Text("\(viewModel.filteredPartners.count) résultat\(viewModel.filteredPartners.count > 1 ? "s" : "")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Champs de recherche - Design compact et épuré (comme HomeView)
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
                            
                            Button(action: {}) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.appRed)
                                    .font(.system(size: 16))
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
                        .zIndex(1000) // zIndex très élevé pour passer au-dessus de tout
                        
                        // Slider Rayon de recherche
                        HStack(spacing: 8) {
                            Text("0")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Slider(value: $viewModel.searchRadius, in: 0...50, step: 5)
                                .tint(.appRed)
                                .onChange(of: viewModel.searchRadius) { _, _ in
                                    viewModel.searchPartners()
                                }
                            
                            Text("50")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(viewModel.searchRadius == 0 ? "Désactivé" : "\(Int(viewModel.searchRadius)) km")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(viewModel.searchRadius == 0 ? .gray.opacity(0.7) : .appGold)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        // Checkbox CLUB10
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.onlyClub10.toggle()
                                viewModel.searchPartners()
                            }
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(viewModel.onlyClub10 ? Color.appRed : Color.clear)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.white, lineWidth: 1.5)
                                        )
                                    
                                    if viewModel.onlyClub10 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                
                                Image(systemName: "star.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 13))
                                
                                Text("Uniquement les membres CLUB10")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.appDarkGray.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Liste des partenaires
                    if viewModel.filteredPartners.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Aucun partenaire trouvé")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Essayez de modifier vos critères de recherche")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.filteredPartners) { partner in
                                PartnerCard(
                                    partner: partner,
                                    onFavoriteToggle: {
                                        viewModel.togglePartnerFavorite(for: partner)
                                    },
                                    onTap: {
                                        selectedPartner = partner
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 100) // Espace pour le footer
                }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {})
                    }
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Demander la permission de localisation si pas encore demandée
            if locationService.authorizationStatus == .notDetermined {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showLocationPermission = true
                }
            }
        }
        .sheet(isPresented: $showLocationPermission) {
            LocationPermissionView(locationService: locationService) {
                showLocationPermission = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

#Preview {
    NavigationStack {
        PartnersListView()
            .environmentObject(LocationService.shared)
    }
}

