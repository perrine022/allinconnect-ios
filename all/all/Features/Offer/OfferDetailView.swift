//
//  OfferDetailView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct OfferDetailView: View {
    let offer: Offer? // Optionnel pour permettre le chargement depuis l'API
    let offerId: Int? // ID de l'offre pour charger depuis l'API
    
    @StateObject private var viewModel: OfferDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedPartner: Partner?
    
    // Initializer pour les offres déjà chargées (mockées)
    init(offer: Offer) {
        self.offer = offer
        self.offerId = nil
        _viewModel = StateObject(wrappedValue: OfferDetailViewModel(offer: offer))
    }
    
    // Initializer pour charger depuis l'API avec l'ID
    init(offerId: Int) {
        self.offer = nil
        self.offerId = offerId
        _viewModel = StateObject(wrappedValue: OfferDetailViewModel(offerId: offerId))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        // États de chargement et d'erreur
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                    .scaleEffect(1.5)
                                Text("Chargement des détails...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 100)
                        } else if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.appGold)
                                Text("Erreur")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    if let offerId = offerId {
                                        viewModel.loadOfferDetail(id: offerId)
                                    }
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
                            .padding(.vertical, 100)
                        } else if let offer = viewModel.offer ?? offer {
                            VStack(spacing: 0) {
                                // Image header avec dimensions fixes (ratio 16:9)
                                ZStack(alignment: .topLeading) {
                                    OfferImage(offer: offer, contentMode: .fit)
                                        .frame(width: geometry.size.width, height: geometry.size.width * 9 / 16)
                                
                                // Overlay gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.black.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 200)
                                
                                // Bouton retour
                                HStack {
                                    NavigationButton(
                                        icon: "arrow.left",
                                        iconColor: Color.white,
                                        backgroundColor: Color.black.opacity(0.5),
                                        action: {
                                            dismiss()
                                        }
                                    )
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            .frame(height: 200)
                            
                            // Contenu
                            VStack(alignment: .leading, spacing: 20) {
                                // Badge type et titre
                                VStack(alignment: .leading, spacing: 12) {
                                    BadgeView(
                                        text: offer.offerType.rawValue,
                                        gradientColors: offer.offerType == .event ? [Color.red, Color.red] : [Color.appGold, Color.appGold.opacity(0.8)]
                                    )
                                    
                                    Text(offer.title)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(offer.businessName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.appGold)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(offer.description)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(6)
                                }
                                .padding(.horizontal, 20)
                                
                                // Informations
                                VStack(alignment: .leading, spacing: 12) {
                                    // Dates sur la même ligne
                                    HStack(spacing: 20) {
                                        // Date de début (si disponible)
                                        if let startDate = offer.startDate, !startDate.isEmpty {
                                            HStack(spacing: 8) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 14))
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Date de début")
                                                        .font(.system(size: 12, weight: .regular))
                                                        .foregroundColor(.gray)
                                                    
                                                    Text(startDate)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                        
                                        // Date de fin
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Valable jusqu'au")
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.gray)
                                                
                                                Text(offer.validUntil)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    if offer.isClub10 {
                                        HStack(spacing: 12) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.appGold)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Membre CLUB10")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.gray)
                                                
                                                Text("Réduction de 10%")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    
                                    if !offer.discount.isEmpty {
                                        HStack(spacing: 12) {
                                            Image(systemName: "tag.fill")
                                                .foregroundColor(.appGold)
                                                .font(.system(size: 16))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Réduction")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.gray)
                                                
                                                Text(offer.discount)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                
                                // Bouton voir le partenaire - toujours affiché si l'offre a un businessName ou un professionnel associé
                                if !offer.businessName.isEmpty || viewModel.professionalId != nil || offer.partnerId != nil {
                                    Button(action: {
                                        print("═══════════════════════════════════════════════════════════")
                                        print("🔘 [OFFER DETAIL] Bouton 'Voir le partenaire' cliqué")
                                        print("═══════════════════════════════════════════════════════════")
                                        print("🔘 [OFFER DETAIL] 📋 État actuel:")
                                        print("   - Partner chargé: \(viewModel.partner != nil ? "OUI" : "NON")")
                                        print("   - ProfessionalId disponible: \(viewModel.professionalId != nil ? "OUI (\(viewModel.professionalId!))" : "NON")")
                                        print("   - Offer partnerId: \(offer.partnerId?.uuidString ?? "nil")")
                                        print("   - Offer apiId: \(offer.apiId != nil ? "\(offer.apiId!)" : "nil")")
                                        print("   - Offer businessName: \(offer.businessName)")
                                        
                                        // Si le partenaire est déjà chargé, naviguer directement
                                        if let partner = viewModel.partner {
                                            print("🔘 [OFFER DETAIL] ✅ Partenaire déjà chargé - Navigation directe")
                                            print("   - Partner ID: \(partner.id)")
                                            print("   - Partner apiId: \(partner.apiId != nil ? "\(partner.apiId!)" : "nil")")
                                            selectedPartner = partner
                                        } else if let professionalId = viewModel.professionalId {
                                            print("🔘 [OFFER DETAIL] ✅ ProfessionalId disponible - Création Partner temporaire")
                                            print("   - ProfessionalId: \(professionalId)")
                                            // Si on a un professionalId, créer un Partner temporaire avec l'apiId
                                            // PartnerDetailView chargera les détails depuis l'API
                                            let tempPartner = Partner(
                                                id: UUID(),
                                                name: offer.businessName,
                                                category: "",
                                                address: "",
                                                city: "",
                                                postalCode: "",
                                                phone: nil,
                                                email: nil,
                                                website: nil,
                                                instagram: nil,
                                                description: nil,
                                                rating: 0,
                                                reviewCount: 0,
                                                discount: nil,
                                                imageName: "person.circle.fill",
                                                headerImageName: "person.circle.fill",
                                                establishmentImageUrl: nil,
                                                isFavorite: false,
                                                apiId: professionalId
                                            )
                                            print("🔘 [OFFER DETAIL] 📤 Navigation vers PartnerDetailView avec apiId: \(professionalId)")
                                            selectedPartner = tempPartner
                                        } else if let partnerId = offer.partnerId,
                                                  let partner = MockDataService.shared.getPartnerById(id: partnerId) {
                                            print("🔘 [OFFER DETAIL] ✅ PartnerId mocké trouvé - Navigation avec mock")
                                            print("   - PartnerId: \(partnerId)")
                                            // Fallback vers MockDataService
                                            selectedPartner = partner
                                        } else if let offerApiId = offer.apiId {
                                            print("🔘 [OFFER DETAIL] ⏳ Récupération du professionalId depuis l'API...")
                                            print("   - Offer apiId: \(offerApiId)")
                                            // Si on a un apiId d'offre mais pas de professionalId, récupérer uniquement le professionalId
                                            // sans recharger toute l'offre pour éviter le re-render
                                            Task { @MainActor in
                                                if let professionalId = await viewModel.getProfessionalId(offerId: offerApiId) {
                                                    print("🔘 [OFFER DETAIL] ✅ ProfessionalId récupéré: \(professionalId)")
                                                    // Créer un Partner temporaire avec l'apiId
                                                    let tempPartner = Partner(
                                                        id: UUID(),
                                                        name: offer.businessName,
                                                        category: "",
                                                        address: "",
                                                        city: "",
                                                        postalCode: "",
                                                        phone: nil,
                                                        email: nil,
                                                        website: nil,
                                                        instagram: nil,
                                                        description: nil,
                                                        rating: 0,
                                                        reviewCount: 0,
                                                        discount: nil,
                                                        imageName: "person.circle.fill",
                                                        headerImageName: "person.circle.fill",
                                                        establishmentImageUrl: nil,
                                                        isFavorite: false,
                                                        apiId: professionalId
                                                    )
                                                    print("🔘 [OFFER DETAIL] 📤 Navigation vers PartnerDetailView avec apiId: \(professionalId)")
                                                    selectedPartner = tempPartner
                                                } else {
                                                    print("🔘 [OFFER DETAIL] ❌ Impossible de récupérer le professionalId")
                                                }
                                            }
                                        } else {
                                            print("🔘 [OFFER DETAIL] ❌ Aucune information disponible pour naviguer vers le partenaire")
                                        }
                                        print("═══════════════════════════════════════════════════════════")
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 18))
                                            
                                            Text("Voir le partenaire")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.red)
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                Spacer()
                                    .frame(height: 100)
                            }
                            }
                        }
                    }
                }
                
                // Footer Bar
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
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe vers la droite (translation.width > 0) pour revenir en arrière
                    if value.translation.width > 50 && abs(value.translation.width) > abs(value.translation.height) {
                        dismiss()
                    }
                }
        )
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

#Preview {
    NavigationStack {
        OfferDetailView(offer: Offer(
            title: "-50% sur l'abonnement",
            description: "Profitez de 50% de réduction sur votre premier mois d'abonnement ! Accès illimité à la salle, cours collectifs inclus.",
            businessName: "Fit & Forme Studio",
            validUntil: "22/01/2026",
            discount: "-50%",
            imageName: "figure.strengthtraining.traditional",
            offerType: .offer,
            isClub10: true
        ))
        .environmentObject(AppState())
    }
}

