//
//  OffersView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OffersView: View {
    @StateObject private var viewModel = OffersViewModel()
    @EnvironmentObject private var locationService: LocationService
    @State private var selectedPartner: Partner?
    @State private var showLocationPermission = false
    
    var body: some View {
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
                        Text("Offres & Événements")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
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
                                    viewModel.searchOffers()
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
                        
                        // Champ Secteur/Activité
                        HStack(spacing: 10) {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 13))
                            
                            TextField("", text: $viewModel.activityText, prompt: Text("Secteur...").foregroundColor(.gray.opacity(0.6)))
                                .foregroundColor(.black)
                                .font(.system(size: 14))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.activityText) { _, _ in
                                    viewModel.searchOffers()
                                }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        // Slider Rayon de recherche
                        VStack(spacing: 6) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.system(size: 12))
                                    
                                    Text("Rayon de recherche")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Text(viewModel.searchRadius == 0 ? "Désactivé" : "\(Int(viewModel.searchRadius)) km")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(viewModel.searchRadius == 0 ? .gray.opacity(0.7) : .appGold)
                                    .frame(minWidth: 70, alignment: .trailing)
                            }
                            
                            HStack(spacing: 8) {
                                Text("0")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .frame(width: 20)
                                
                                Slider(value: $viewModel.searchRadius, in: 0...50, step: 5)
                                    .tint(.appRed)
                                    .onChange(of: viewModel.searchRadius) { _, _ in
                                        viewModel.searchOffers()
                                    }
                                
                                Text("50")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .frame(width: 20)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
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
                    
                    // Liste des offres
                    VStack(spacing: 12) {
                        ForEach(viewModel.filteredOffers) { offer in
                            OfferListCard(offer: offer) {
                                if let partner = viewModel.getPartner(for: offer) {
                                    selectedPartner = partner
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Espace pour le footer
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
    }
}

#Preview {
    NavigationStack {
        OffersView()
            .environmentObject(LocationService.shared)
    }
}

