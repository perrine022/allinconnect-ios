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
    @State private var proInfoNavigationId: UUID?
    @State private var partnersListNavigationId: UUID?
    @State private var isSearchExpanded: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    var body: some View {
        ZStack {
            // Background avec gradient : identique partout dans l'app
            AppGradient.main
                .ignoresSafeArea(edges: .top)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Champs de recherche - Design compact et épuré
                        VStack(spacing: 6) {
                            // Champ Ville, nom, activité - toujours visible - ID pour scroll vers le haut
                            HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 13))
                            
                            TextField("", text: $viewModel.cityText, prompt: Text("Ville, nom, activité...").foregroundColor(.gray.opacity(0.6)))
                                .foregroundColor(.black)
                                .font(.system(size: 14))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($isSearchFieldFocused)
                                .onChange(of: isSearchFieldFocused) { _, newValue in
                                    if newValue {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            isSearchExpanded = true
                                        }
                                    }
                                }
                                .onChange(of: viewModel.cityText) { _, _ in
                                    viewModel.searchProfessionals()
                                }
                            
                            Button(action: {}) {
                                Image("SearchIcon")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .onTapGesture {
                            // Forcer le focus sur le champ pour déclencher l'expansion
                            isSearchFieldFocused = true
                        }
                        
                        // Autres champs - masqués par défaut, déroulés au clic
                        if isSearchExpanded {
                            // Menu déroulant Secteur
                            CustomSectorPicker(
                                sectors: viewModel.sectors,
                                selectedSector: $viewModel.selectedSector,
                                onSelectionChange: {
                                    viewModel.searchProfessionals()
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            // Slider Rayon de recherche
                            HStack(spacing: 8) {
                                Text("0")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .frame(width: 20)
                                
                                Slider(value: $viewModel.searchRadius, in: 0...50, step: 5)
                                    .tint(.red)
                                    .onChange(of: viewModel.searchRadius) { _, _ in
                                        viewModel.searchProfessionals()
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            // Bouton Rechercher - navigue vers la page Nos partenaires avec les filtres
                            Button(action: {
                                partnersListNavigationId = UUID()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Rechercher")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                        .id("top")
                    
                    // Titre principal - plus petit, juste sous le filtre
                    VStack(spacing: 4) {
                        (Text("Trouve ton partenaire ")
                            .foregroundColor(.white) +
                         Text("ALL IN")
                            .foregroundColor(.red) +
                         Text(" près de chez toi")
                            .foregroundColor(.white))
                            .font(.system(size: 14, weight: .semibold))
                            .multilineTextAlignment(.center)
                        
                        Text("Et profite de 10% chez tous les membres du CLUB10")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
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
                        .padding(.top, 2)
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
                                .foregroundColor(Color.red.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Scroll horizontal des offres
                        if viewModel.isLoadingOffers {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Chargement des offres...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else if let apiError = viewModel.offersAPIError, apiError.isServerError {
                            // Afficher ServerErrorView pour les erreurs 500
                            ServerErrorView {
                                viewModel.loadOffersByCity()
                            }
                            .frame(maxWidth: .infinity, minHeight: 400)
                        } else if let error = viewModel.offersError {
                            VStack(spacing: 8) {
                                Text("Erreur lors du chargement")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.9))
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                Button(action: {
                                    viewModel.loadOffersByCity()
                                }) {
                                    Text("Réessayer")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
                        } else if viewModel.offers.isEmpty {
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
                    .padding(.top, viewModel.hasSearched ? 24 : 16)
                    
                    // Section "Les partenaires"
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 6) {
                                Text("Les partenaires")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Affichage vertical des partenaires (4 max)
                        if viewModel.isLoadingPartners {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Chargement des partenaires...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else if viewModel.featuredPartners.isEmpty {
                            VStack(spacing: 8) {
                                Text("Aucun partenaire disponible pour le moment")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.vertical, 20)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.featuredPartners) { partner in
                                    ModernPartnerCard(
                                        partner: partner,
                                        onFavoriteToggle: {
                                            viewModel.togglePartnerFavorite(for: partner)
                                        },
                                        onTap: {
                                            selectedPartner = partner
                                        }
                                    )
                                }
                                
                                // Bouton "Voir tout" avec design neuromarketing
                                Button(action: {
                                    partnersListNavigationId = UUID()
                                }) {
                                    HStack(spacing: 10) {
                                        Text("Découvrir tous les partenaires")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.red,
                                                Color.red.opacity(0.85)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.4),
                                                        Color.white.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                                .padding(.top, 12)
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Carte Pro - pour les professionnels (uniquement si statut UNKNOWN)
                    if viewModel.isUserUnknown {
                        ProCard(onLearnMore: {
                            proInfoNavigationId = UUID()
                        })
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Carte CLUB10 - à la fin (uniquement si statut UNKNOWN)
                    if viewModel.isUserUnknown {
                        Club10Card(onLearnMore: {
                            digitalCardInfoNavigationId = UUID()
                        })
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Bouton "L'app qui pense à toi" - en bas de la page
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
                                .stroke(Color.red, lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100) // Espace pour le footer
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ScrollToTop"))) { notification in
                    if let tab = notification.userInfo?["tab"] as? TabItem, tab == .home {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .task {
            // Charger les 4 premières offres réelles depuis l'API au démarrage
            viewModel.loadOffersByCity()
            // Charger les 5 premiers partenaires pour la page d'accueil
            viewModel.loadFeaturedPartners()
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
        .navigationDestination(item: $proInfoNavigationId) { _ in
            ProInfoView()
        }
        .navigationDestination(item: $partnersListNavigationId) { _ in
            PartnersListView(
                initialCityText: viewModel.cityText,
                initialSelectedSector: viewModel.selectedSector,
                initialSearchRadius: viewModel.searchRadius,
                initialOnlyClub10: viewModel.onlyClub10
            )
        }
    }
}

// Carte partenaire moderne pour la page d'accueil
struct ModernPartnerCard: View {
    let partner: Partner
    let onFavoriteToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Fond avec gradient moderne et contour visible - plus marqué
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.appDarkRed1,
                                Color.appDarkRed2,
                                Color.red.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        // Image de l'établissement avec style moderne
                        Group {
                            if let imageUrl = ImageURLHelper.buildImageURL(from: partner.establishmentImageUrl),
                               let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.15))
                                            Image(systemName: partner.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.white.opacity(0.5))
                                                .frame(width: 30, height: 30)
                                        }
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.15))
                                            Image(systemName: partner.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.white.opacity(0.5))
                                                .frame(width: 30, height: 30)
                                        }
                                    @unknown default:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.15))
                                            Image(systemName: partner.imageName)
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.white.opacity(0.5))
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                }
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.15))
                                    Image(systemName: partner.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // Nom avec texte plus petit
                            Text(partner.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            // Catégorie avec badge moderne plus petit
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(partner.category)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                            
                            // Localisation plus petite
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(partner.city)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Note avec style moderne plus petit
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 11))
                                Text(String(format: "%.1f", partner.rating))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("(\(partner.reviewCount))")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                }
                
                // Badge de réduction en haut à droite plus petit
                if let discount = partner.discount {
                    VStack {
                        Text("-\(discount)%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
                    }
                    .padding(12)
                }
                
                // Bouton favori en bas à droite plus petit
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: onFavoriteToggle) {
                            Image(systemName: partner.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(partner.isFavorite ? .red : .white.opacity(0.75))
                                .font(.system(size: 18))
                                .padding(8)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(LocationService.shared)
    }
}
