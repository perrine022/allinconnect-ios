//
//  TutorialView.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import SwiftUI

struct TutorialView: View {
    @StateObject private var viewModel = TutorialViewModel()
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        ZStack {
            // Background sombre
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Indicateur de progression
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        Rectangle()
                            .fill(index == viewModel.currentPage ? Color.red : Color.gray.opacity(0.3))
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Contenu du tutoriel
                TabView(selection: $viewModel.currentPage) {
                    // Écran 1: Page d'accueil avec logo
                    TutorialWelcomePage()
                        .tag(0)
                    
                    // Écran 2: "Tout ce dont tu as besoin, près de chez toi."
                    TutorialPage(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Tout ce dont tu as besoin, près de chez toi.",
                        description1: "Découvre les communautés, services, offres et événements autour de toi... en un seul endroit.",
                        description2: "All in Connect te simplifie la vie, et t'aide à trouver le meilleur près de chez toi.",
                        cardColor: Color(red: 0.2, green: 0.1, blue: 0.15) // Rouge foncé
                    )
                    .tag(1)
                    
                    // Écran 3: "Le local, mais plus accessible."
                    TutorialPage(
                        icon: "",
                        iconColor: .green,
                        title: "Le local,\nmais plus accessible.",
                        description1: "Avec la carte digitale, tu profites de -10%\nchez tous les pros du Club10.",
                        description2: "Des petits plaisirs aux besoins essentiels :\ntout devient plus simple, plus doux, plus\naccessible.",
                        cardColor: Color.red,
                        showDiscountBadge: true
                    )
                    .tag(2)
                    
                    // Écran 4: "Seulement ce qui compte pour toi."
                    TutorialPage(
                        icon: "bell.fill",
                        iconColor: .yellow,
                        title: "Seulement ce qui compte pour toi.",
                        description1: "Choisis tes catégories, ajoute tes pros favoris, reçois toutes les actualités, offres et événements en direct.",
                        description2: "Ton quotidien total, personnalisé. Sans spam, sans bruit, sans l'essentiel.",
                        cardColor: Color(red: 1.0, green: 0.4, blue: 0.6) // Rose/Magenta
                    )
                    .tag(3)
                    
                    // Écran 5: "Les bonnes adresses, les bonnes infos... au bon moment."
                    TutorialPage(
                        icon: "map.fill",
                        iconColor: .blue,
                        title: "Les bonnes adresses, les bonnes infos... au bon moment.",
                        description1: "Accède à des centaines de professionnels.",
                        description2: "Filtre par catégorie, activité, ville... et trouve exactement ce qu'il te faut - sans chercher pendant des heures.",
                        cardColor: Color.red
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                // Texte pour la première page (uniquement si on est sur la page 0)
                if viewModel.currentPage == 0 {
                    VStack(spacing: 16) {
                        // Titre
                        Text("un réseau pensé pour les pros, créé pour les habitants.")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 30)
                        
                        // Sous-titre
                        Text("Toutes les bonnes adresses autour de toi & leurs offres réunies dans une seule application.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 20)
                }
                
                // Boutons de navigation
                VStack(spacing: 12) {
                    // Bouton Suivant
                    Button(action: {
                        if viewModel.currentPage < viewModel.totalPages - 1 {
                            withAnimation {
                                viewModel.currentPage += 1
                            }
                        } else {
                            // Dernier écran, terminer le tutoriel
                            viewModel.completeTutorial()
                            onComplete()
                        }
                    }) {
                        Text(viewModel.currentPage < viewModel.totalPages - 1 ? "Suivant" : "Commencer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Bouton Passer
                    Button(action: {
                        viewModel.completeTutorial()
                        onSkip()
                    }) {
                        Text("Passer")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Tutorial Welcome Page
struct TutorialWelcomePage: View {
    var body: some View {
        ZStack {
            // Image en plein écran
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Overlay sombre pour améliorer la lisibilité du texte
            Color.black.opacity(0.3)
                .ignoresSafeArea()
        }
    }
}

struct TutorialPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description1: String
    let description2: String
    let cardColor: Color
    var showDiscountBadge: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Carte principale
            VStack(spacing: 24) {
                // Icône ou Badge
                if showDiscountBadge {
                    // Badge vert avec dollar et ailes (style de l'image)
                    ZStack {
                        // Fond vert arrondi
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                            .frame(width: 70, height: 45)
                        
                        // Dollar avec ailes stylisées
                        HStack(spacing: 4) {
                            // Aile gauche
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                                .offset(x: -2)
                            
                            // Dollar central
                            Text("$")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                            
                            // Aile droite
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                                .offset(x: 2)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 60))
                        .padding(.top, 40)
                }
                
                // Titre
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                
                // Descriptions
                VStack(spacing: 16) {
                    Text(description1)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 30)
                    
                    Text(description2)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 12)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 500)
            .padding(.vertical, 50)
            .background(cardColor)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

#Preview {
    TutorialView(
        onComplete: {},
        onSkip: {}
    )
}

