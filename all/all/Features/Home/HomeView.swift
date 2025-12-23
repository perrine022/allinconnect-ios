//
//  HomeView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedProfessional: Professional?
    @State private var selectedOffer: Offer?
    @State private var selectedPartner: Partner?
    
    var body: some View {
        ZStack {
            // Background avec gradient utilisant les couleurs hex
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appDarkRed2, // #421515
                    Color.appDarkRed1, // #1D0809
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Logo et tagline
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("ALL")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ZStack {
                                Circle()
                                    .fill(Color.appRed)
                                    .frame(width: 24, height: 24)
                                
                                Circle()
                                    .fill(Color.appRed.opacity(0.6))
                                    .frame(width: 20, height: 20)
                                
                                Circle()
                                    .fill(Color.appRed.opacity(0.3))
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text("IN")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("Connect")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.appRed.opacity(0.9))
                    }
                    .padding(.top, 20)
                    
                    // Bouton "L'app qui pense à toi"
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appGold)
                                .font(.system(size: 18))
                            
                            Text("L'app qui pense à toi")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.appRed, Color.appDarkRed]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Titre principal
                    VStack(spacing: 8) {
                        Text("Trouve ton partenaire ALL IN près de chez toi")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Et profite de 10% chez tous les membres du CLUB10")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Champs de recherche
                    VStack(spacing: 12) {
                        // Champ Ville, nom, activité
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("", text: $viewModel.cityText, prompt: Text("Ville, nom, activité...").foregroundColor(.gray))
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.cityText) { _, _ in
                                    viewModel.searchProfessionals()
                                }
                            
                            Button(action: {}) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.appRed)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Champ Activité
                        HStack(spacing: 12) {
                            Image(systemName: "briefcase.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("", text: $viewModel.activityText, prompt: Text("Activité...").foregroundColor(.gray))
                                .foregroundColor(.black)
                                .font(.system(size: 15))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: viewModel.activityText) { _, _ in
                                    viewModel.searchProfessionals()
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Toggle Rayon de recherche
                        HStack {
                            Text("Rayon de recherche :")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.searchRadiusEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .appRed))
                            
                            Text(viewModel.searchRadiusEnabled ? "Activé" : "Désactivé")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Checkbox CLUB10
                        Button(action: {
                            viewModel.onlyClub10.toggle()
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(viewModel.onlyClub10 ? Color.appRed : Color.clear)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                    
                                    if viewModel.onlyClub10 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                                
                                Image(systemName: "star.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 16))
                                
                                Text("Uniquement les membres CLUB10")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.appDarkGray.opacity(0.6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Section "À ne pas louper"
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
                            
                            Button(action: {}) {
                                HStack(spacing: 4) {
                                    Text("Voir tout")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Color.appRed.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Scroll horizontal des offres
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.offers) { offer in
                                    OfferCard(offer: offer) {
                                        selectedOffer = offer
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Carte CLUB10
                    Club10Card()
                        .padding(.horizontal, 20)
                    
                    // Section "Nos partenaires"
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Nos partenaires")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
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
                        
                        // Liste des partenaires
                        VStack(spacing: 12) {
                            ForEach(viewModel.partners) { partner in
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
                    .padding(.top, 8)
                    .padding(.bottom, 100) // Espace pour le footer
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(item: $selectedOffer) { offer in
            // Détail de l'offre
        }
        .navigationDestination(item: $selectedPartner) { partner in
            PartnerDetailView(partner: partner)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
