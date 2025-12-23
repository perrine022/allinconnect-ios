//
//  OffersView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OffersView: View {
    @StateObject private var viewModel = OffersViewModel()
    @State private var selectedPartner: Partner?
    
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
                    
                    // Filtres horizontaux
                    HStack(spacing: 12) {
                        ForEach(OfferFilterType.allCases, id: \.self) { filter in
                            Button(action: {
                                viewModel.selectFilter(filter)
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(viewModel.selectedFilter == filter ? .black : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedFilter == filter ? Color.appGold : Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Filtre secteur
                    Button(action: {
                        viewModel.showSectorFilter.toggle()
                    }) {
                        HStack {
                            Text(viewModel.selectedSector)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.appDarkRed1.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Liste des offres
                    VStack(spacing: 16) {
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
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
        .sheet(isPresented: $viewModel.showSectorFilter) {
            FilterSheet(
                title: "Secteur",
                items: viewModel.sectors,
                selectedItem: viewModel.selectedSector,
                isPresented: $viewModel.showSectorFilter,
                onSelect: { sector in
                    viewModel.selectSector(sector)
                }
            )
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        OffersView()
    }
}

