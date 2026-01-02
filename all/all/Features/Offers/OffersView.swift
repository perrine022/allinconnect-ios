//
//  OffersView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import CoreLocation

struct OffersView: View {
    @StateObject private var viewModel = OffersViewModel()
    @EnvironmentObject private var locationService: LocationService
    @State private var selectedPartner: Partner?
    @State private var selectedOffer: Offer?
    @State private var showLocationPermission = false
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Titre
                    HStack {
                        Text("Offres & Événements")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Pastilles de filtre par type
                    HStack(spacing: 12) {
                        // Pastille "Tous" (toujours rouge)
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.selectedOfferType = nil
                                viewModel.applyFilters()
                            }
                        }) {
                            Text("Tous")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.red)
                                )
                        }
                        
                        // Pastille "Offres"
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                if viewModel.selectedOfferType == .offer {
                                    viewModel.selectedOfferType = nil // Désélectionner
                                } else {
                                    viewModel.selectedOfferType = .offer
                                }
                                viewModel.applyFilters()
                            }
                        }) {
                            Text("Offres")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.selectedOfferType == .offer ? .white : .red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(viewModel.selectedOfferType == .offer ? Color.red : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.red, lineWidth: 1.5)
                                        )
                                )
                        }
                        
                        // Pastille "Événements"
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                if viewModel.selectedOfferType == .event {
                                    viewModel.selectedOfferType = nil // Désélectionner
                                } else {
                                    viewModel.selectedOfferType = .event
                                }
                                viewModel.applyFilters()
                            }
                        }) {
                            Text("Événements")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(viewModel.selectedOfferType == .event ? .white : .red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(viewModel.selectedOfferType == .event ? Color.red : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.red, lineWidth: 1.5)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Boutons "Offres actuelles" et "À venir" (prennent toute la largeur)
                    HStack(spacing: 12) {
                        // Bouton "Offres actuelles"
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.offerTimeMode = .current
                                // Réinitialiser les dates quand on passe en mode actuelles
                                viewModel.startDate = nil
                                viewModel.endDate = nil
                                viewModel.searchOffers()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(viewModel.offerTimeMode == .current ? .white : .red)
                                    .font(.system(size: 14))
                                
                                Text("Offres actuelles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.offerTimeMode == .current ? .white : .red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.offerTimeMode == .current ? Color.red : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.red, lineWidth: 1.5)
                                    )
                            )
                        }
                        
                        // Bouton "À venir"
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.offerTimeMode = .upcoming
                                viewModel.searchOffers()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(viewModel.offerTimeMode == .upcoming ? .white : .red)
                                    .font(.system(size: 14))
                                
                                Text("À venir")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.offerTimeMode == .upcoming ? .white : .red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.offerTimeMode == .upcoming ? Color.red : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.red, lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Filtres de date (affichés en permanence quand on est sur "À venir")
                    if viewModel.offerTimeMode == .upcoming {
                        DateRangePicker(
                            startDate: $viewModel.startDate,
                            endDate: $viewModel.endDate,
                            alwaysExpanded: true
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .onChange(of: viewModel.startDate) { _, _ in
                            viewModel.searchOffers()
                        }
                        .onChange(of: viewModel.endDate) { _, _ in
                            viewModel.searchOffers()
                        }
                    }
                    
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
                                    viewModel.searchOffers()
                                }
                            
                            Button(action: {}) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        // Menu déroulant Secteur - avec zIndex élevé
                        CustomSectorPicker(
                            sectors: viewModel.sectors,
                            selectedSector: $viewModel.selectedSector,
                            onSelectionChange: {
                                viewModel.searchOffers()
                            }
                        )
                        .zIndex(1000)
                        
                        // Slider Rayon de recherche
                        HStack(spacing: 8) {
                            Text("0")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Slider(value: $viewModel.searchRadius, in: 0...50, step: 5)
                                .tint(.red)
                                .onChange(of: viewModel.searchRadius) { _, _ in
                                    viewModel.searchOffers()
                                }
                            
                            Text("50")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(viewModel.searchRadius == 0 ? "Désactivé" : "\(Int(viewModel.searchRadius)) km")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(viewModel.searchRadius == 0 ? .gray.opacity(0.7) : .red)
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
                                viewModel.searchOffers()
                            }
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(viewModel.onlyClub10 ? Color.green : Color.clear)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.green, lineWidth: 1.5)
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
                                    .foregroundColor(.green)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.85, green: 0.95, blue: 0.85)) // Vert clair/pastel
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .zIndex(1000) // zIndex élevé pour le VStack des champs de recherche
                    
                    // États de chargement et d'erreur - selon guidelines Apple
                    // Afficher le loader uniquement pendant le chargement initial
                    if viewModel.isLoading && !viewModel.hasLoadedOnce {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                .scaleEffect(1.5)
                            
                            Text("Chargement des offres...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 100)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                    } else if let errorMessage = viewModel.errorMessage {
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
                            
                            Button(action: {
                                viewModel.loadOffers()
                            }) {
                                Text("Réessayer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.appGold)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if viewModel.hasLoadedOnce {
                        // Afficher le contenu seulement après le premier chargement
                        if viewModel.isLoading {
                            // Afficher des skeletons pendant un rechargement (après le premier chargement)
                            VStack(spacing: 12) {
                                ForEach(0..<5, id: \.self) { _ in
                                    OfferListCardSkeleton()
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if viewModel.filteredOffers.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tag.slash.fill")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.system(size: 48))
                                Text("Aucune offre trouvée")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.filteredOffers) { offer in
                                    OfferListCard(offer: offer) {
                                        // Naviguer vers la page de détail de l'offre
                                        selectedOffer = offer
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.filteredOffers.count)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 100) // Espace pour le footer
                }
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
        .navigationDestination(item: $selectedOffer) { offer in
            // Si l'offre a un ID API, charger depuis l'API, sinon utiliser l'offre directement
            if let apiId = offer.extractApiId() {
                OfferDetailView(offerId: apiId)
            } else {
                OfferDetailView(offer: offer)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OffersView()
            .environmentObject(LocationService.shared)
    }
}

