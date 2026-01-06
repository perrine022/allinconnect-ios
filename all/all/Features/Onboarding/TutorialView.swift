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
            // Background noir pour la zone en dessous du bouton
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
                
                // Contenu du tutoriel (images avec plus de hauteur visible)
                TabView(selection: $viewModel.currentPage) {
                    // Écran 1: Page d'accueil avec logo
                    TutorialWelcomePage()
                        .tag(0)
                    
                    // Écran 2: Image promotionnelle "Toujours en avance sur les bonnes affaires"
                    TutorialSecondPage()
                        .tag(1)
                    
                    // Écran 3: Image promotionnelle Club10
                    TutorialThirdPage()
                        .tag(2)
                    
                    // Écran 4: Image promotionnelle (dernière page)
                    TutorialFourthPage()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // Zone noire avec boutons de navigation
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
                    .padding(.top, 30)
                    
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
                .background(Color.black)
            }
        }
    }
}

// MARK: - Tutorial Welcome Page
struct TutorialWelcomePage: View {
    var body: some View {
        // Image en plein écran avec les deux femmes et le téléphone
        VStack {
            Spacer()
            Image("TutorialFirstPageImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Tutorial Second Page
struct TutorialSecondPage: View {
    var body: some View {
        // Image promotionnelle "Toujours en avance sur les bonnes affaires"
        VStack {
            Spacer()
            Image("TutorialSecondPageImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Tutorial Third Page
struct TutorialThirdPage: View {
    var body: some View {
        // Image promotionnelle Club10 "-10% chez tous les membres du club 10"
        VStack {
            Spacer()
            Image("TutorialThirdPageImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Tutorial Fourth Page (Dernière page)
struct TutorialFourthPage: View {
    var body: some View {
        // Image promotionnelle (dernière page du tutoriel)
        VStack {
            Spacer()
            Image("TutorialFourthPageImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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

