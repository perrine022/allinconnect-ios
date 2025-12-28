//
//  ProOffersView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProOffersView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProOffersViewModel()
    @State private var showCreateOffer = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Titre avec bouton +
                            HStack {
                                Text("Mes offres")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: {
                                    showCreateOffer = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color.appGold)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
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
                                    
                                    Button(action: {
                                        viewModel.loadMyOffers()
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
                            }
                            
                            // Liste des offres ou skeletons de chargement
                            if viewModel.errorMessage == nil {
                                if viewModel.isLoading {
                                    // Afficher des skeletons pendant le chargement
                                    VStack(spacing: 12) {
                                        ForEach(0..<5, id: \.self) { _ in
                                            OfferListCardSkeleton()
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                } else if viewModel.myOffers.isEmpty {
                                    VStack(spacing: 16) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white.opacity(0.5))
                                            
                                            Text("Aucune offre pour le moment")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Text("Créez votre première offre en cliquant sur le bouton +")
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white.opacity(0.6))
                                                .multilineTextAlignment(.center)
                                        }
                                        .padding(.vertical, 40)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 20)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.myOffers) { offer in
                                            ProOfferCard(offer: offer) {
                                                viewModel.deleteOffer(offer)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showCreateOffer) {
            NavigationStack {
                CreateOfferView { newOffer in
                    // Recharger les offres depuis l'API pour avoir la liste à jour
                    viewModel.loadMyOffers()
                }
            }
        }
    }
}

struct ProOfferCard: View {
    let offer: Offer
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            Image(systemName: offer.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white.opacity(0.8))
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.appDarkRed1, Color.appDarkRed2]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Contenu
            VStack(alignment: .leading, spacing: 6) {
                Text(offer.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(offer.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    BadgeView(
                        text: offer.offerType.rawValue,
                        gradientColors: offer.offerType == .event ? [Color.appRed, Color.appDarkRed] : [Color.appGold, Color.appGold.opacity(0.8)],
                        fontSize: 10
                    )
                    
                    if offer.isClub10 {
                        Text("CLUB10")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text("Jusqu'au \(offer.validUntil)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            // Bouton supprimer
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .alert("Supprimer l'offre", isPresented: $showDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cette offre ?")
        }
    }
}

#Preview {
    NavigationStack {
        ProOffersView()
            .environmentObject(AppState())
    }
}

