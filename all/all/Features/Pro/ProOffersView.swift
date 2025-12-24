//
//  ProOffersView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProOffersView: View {
    @StateObject private var viewModel = ProOffersViewModel()
    @State private var showCreateOffer = false
    
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
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Mes offres")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: {
                        showCreateOffer = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Nouvelle offre")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.appGold)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Liste des offres
                if viewModel.myOffers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Aucune offre pour le moment")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Créez votre première offre pour commencer")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.myOffers) { offer in
                                ProOfferCard(offer: offer) {
                                    viewModel.deleteOffer(offer)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCreateOffer) {
            NavigationStack {
                CreateOfferView { newOffer in
                    // Ajouter la nouvelle offre à la liste
                    viewModel.addOffer(newOffer)
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
    }
}

