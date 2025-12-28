//
//  HomeView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import CoreLocation

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var appState: AppState
    @State private var selectedProfessional: Professional?
    @State private var selectedPartner: Partner?
    @State private var selectedOffer: Offer?
    @State private var showLocationPermission = false
    @State private var digitalCardInfoNavigationId: UUID?
    @State private var partnersListNavigationId: UUID?
    @State private var proInfoNavigationId: UUID?
    var body: some View {
        ZStack {
            // Background avec gradient : rouge moins intense
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.appDarkBlue, location: 0.0),      // Bleu très foncé en haut (0%)
                    .init(color: Color.appDark, location: 0.12),          // Noir (12%)
                    .init(color: Color.appDarkRed1, location: 0.25),      // Rouge très foncé (25% - 1/4 de l'écran)
                    .init(color: Color.appDarkRed2, location: 0.55),       // Rouge foncé (55%)
                    .init(color: Color.appDarkRed2, location: 0.75),       // Rouge foncé moins intense (75%)
                    .init(color: Color.appDark, location: 1.0)           // Sombre en bas (100%)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 0) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 75, maxHeight: 30)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                    }
                    
                    // Bouton "L'app qui pense à toi"
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appGold)
                                .font(.system(size: 14))
                            
                            Text("L'app qui pense à toi")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appDarkRedButton, lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Titre principal
                    VStack(spacing: 8) {
                        (Text("Trouve ton partenaire ")
                            .foregroundColor(.white) +
                         Text("ALL IN")
                            .foregroundColor(.appDarkRedButton) +
                         Text(" près de\nchez toi")
                            .foregroundColor(.white))
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Text("Et profite de 10% chez tous les membres du CLUB10")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Champs de recherche - Design compact et épuré
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
                                    viewModel.searchProfessionals()
                                }
                            
                            Button(action: {}) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.appDarkRedButton)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // Menu déroulant Secteur
                        CustomSectorPicker(
                            sectors: viewModel.sectors,
                            selectedSector: $viewModel.selectedSector,
                            onSelectionChange: {
                                viewModel.searchProfessionals()
                            }
                        )
                        
                        // Slider Rayon de recherche
                        HStack(spacing: 8) {
                            Text("0")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Slider(value: $viewModel.searchRadius, in: 0...50, step: 5)
                                .tint(.appDarkRedButton)
                                .onChange(of: viewModel.searchRadius) { _, _ in
                                    viewModel.searchProfessionals()
                                }
                            
                            Text("50")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.gray.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(viewModel.searchRadius == 0 ? "Désactivé" : "\(Int(viewModel.searchRadius)) km")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(viewModel.searchRadius == 0 ? .gray.opacity(0.7) : .appDarkRedButton)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // Checkbox CLUB10
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewModel.onlyClub10.toggle()
                                viewModel.searchProfessionals()
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
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Bouton Rechercher
                        Button(action: {
                            viewModel.searchProfessionals()
                        }) {
                            HStack {
                                Spacer()
                                Text("Rechercher")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(Color.appDarkRedButton)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Section "Nos partenaires" - affichée seulement après recherche
                    if viewModel.hasSearched {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Nos partenaires")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if !viewModel.filteredPartners.isEmpty {
                                    Text("\(viewModel.filteredPartners.count) résultat\(viewModel.filteredPartners.count > 1 ? "s" : "")")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                
                                Button(action: {
                                    partnersListNavigationId = UUID()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Voir tout")
                                            .font(.system(size: 14, weight: .medium))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Liste des partenaires filtrés
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
                        }
                        .padding(.top, 8)
                    }
                    
                    // Section "À ne pas louper" - juste après le bouton rechercher par défaut, ou après les partenaires si recherche effectuée
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 6) {
                                Text("🔥")
                                    .font(.system(size: 18))
                                Text("À ne pas louper")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                appState.navigateToTab(.offers)
                            }) {
                                HStack(spacing: 4) {
                                    Text("Voir tout")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Color.appDarkRedButton.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Scroll horizontal des offres
                        if viewModel.offers.isEmpty {
                            VStack(spacing: 8) {
                                Text("Aucune offre disponible pour le moment")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.vertical, 20)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.offers) { offer in
                                        OfferCard(offer: offer) {
                                            // Naviguer vers la page de détail de l'offre
                                            selectedOffer = offer
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, viewModel.hasSearched ? 24 : 8)
                    
                    // Carte Pro - pour les professionnels
                    ProCard(onLearnMore: {
                        proInfoNavigationId = UUID()
                    })
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Carte CLUB10 - à la fin
                    Club10Card(onLearnMore: {
                        digitalCardInfoNavigationId = UUID()
                    })
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100) // Espace pour le footer
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
        .navigationDestination(item: $digitalCardInfoNavigationId) { _ in
            DigitalCardInfoView()
        }
        .navigationDestination(item: $partnersListNavigationId) { _ in
            PartnersListView()
        }
        .navigationDestination(item: $proInfoNavigationId) { _ in
            ProInfoView()
        }
    }
}


#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(LocationService.shared)
    }
}
