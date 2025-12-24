//
//  HelpSupportView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import UIKit

struct HelpSupportView: View {
    @State private var selectedSection: HelpSection?
    
    enum HelpSection: String, Identifiable {
        case faq = "FAQ"
        case contact = "Nous contacter"
        case report = "Signaler un problème"
        case tutorial = "Tutoriels"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .faq: return "questionmark.circle.fill"
            case .contact: return "envelope.fill"
            case .report: return "exclamationmark.triangle.fill"
            case .tutorial: return "book.fill"
            }
        }
    }
    
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
                VStack(spacing: 24) {
                    // Titre
                    HStack {
                        Text("Aide & Support")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Sections d'aide
                    VStack(spacing: 0) {
                        ForEach([HelpSection.faq, .contact, .report, .tutorial], id: \.id) { section in
                            Button(action: {
                                selectedSection = section
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: section.icon)
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 18))
                                        .frame(width: 24)
                                    
                                    Text(section.rawValue)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if section != .tutorial {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 54)
                            }
                        }
                    }
                    .background(Color.appDarkRed1.opacity(0.8))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Informations de contact
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Besoin d'aide ?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ContactRow(
                                icon: "phone.fill",
                                text: "04 78 00 00 00",
                                iconColor: .appGold,
                                action: {
                                    if let url = URL(string: "tel://0478000000") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactRow(
                                icon: "envelope.fill",
                                text: "support@allinconnect.fr",
                                iconColor: .appGold,
                                action: {
                                    if let url = URL(string: "mailto:support@allinconnect.fr") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedSection) { section in
            HelpSectionDetailView(section: section)
        }
    }
}

struct HelpSectionDetailView: View {
    let section: HelpSupportView.HelpSection
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
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
                VStack(alignment: .leading, spacing: 20) {
                    Text(getContent())
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                        .padding(20)
                }
            }
        }
        .navigationTitle(section.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    func getContent() -> String {
        switch section {
        case .faq:
            return """
            Questions fréquentes
            
            1. Comment créer un compte ?
            Vous pouvez créer un compte directement depuis l'application en cliquant sur "S'inscrire" lors de votre première utilisation.
            
            2. Comment utiliser ma carte digitale ?
            Votre carte digitale est disponible dans l'onglet "Ma Carte". Elle contient votre code de parrainage et vos informations de membre CLUB10.
            
            3. Comment bénéficier des réductions CLUB10 ?
            Les membres CLUB10 bénéficient automatiquement de 10% de réduction chez tous les partenaires membres du club. La réduction est appliquée automatiquement lors de votre visite.
            
            4. Comment contacter un partenaire ?
            Sur la fiche du partenaire, vous pouvez utiliser le bouton "Contact" pour l'appeler directement, ou consulter son email et son site web.
            
            5. Comment rechercher un partenaire ?
            Utilisez les filtres de recherche sur la page d'accueil : ville, secteur d'activité, rayon de recherche et filtre CLUB10.
            
            6. Comment ajouter un partenaire en favoris ?
            Cliquez sur l'icône cœur en haut à droite de la fiche du partenaire pour l'ajouter à vos favoris.
            
            7. Comment voir mes offres favorites ?
            Vos offres favorites sont visibles dans l'onglet "Ma Carte" dans la section "Mes favoris".
            
            8. Comment fonctionne le système de parrainage ?
            Partagez votre lien de parrainage et gagnez 50% de la première mensualité de chaque filleul. Votre lien est disponible dans "Ma Carte".
            
            9. Les offres sont-elles valables immédiatement ?
            Oui, les offres sont valables dès leur publication jusqu'à la date d'expiration indiquée sur chaque offre.
            
            10. Comment modifier mes préférences de notifications ?
            Allez dans votre profil, puis "Préférences de notifications" pour gérer les types de notifications que vous souhaitez recevoir.
            """
        case .contact:
            return """
            Nous contacter
            
            Email : support@allinconnect.fr
            Téléphone : 04 78 00 00 00
            
            Horaires d'ouverture :
            Du lundi au vendredi : 9h - 18h
            Samedi : 10h - 16h
            
            Nous répondons à toutes vos questions dans les 24h.
            """
        case .report:
            return """
            Signaler un problème
            
            Si vous rencontrez un problème avec l'application ou un partenaire, vous pouvez nous le signaler.
            
            Veuillez décrire le problème en détail et nous vous répondrons dans les plus brefs délais.
            
            Email : support@allinconnect.fr
            """
        case .tutorial:
            return """
            Tutoriels
            
            Découvrez comment utiliser toutes les fonctionnalités de l'application :
            
            • Comment rechercher un partenaire
            • Comment utiliser les filtres
            • Comment ajouter une carte à votre portefeuille
            • Comment profiter des offres
            • Comment gérer vos favoris
            
            Des vidéos tutoriels sont disponibles sur notre site web.
            """
        }
    }
}

#Preview {
    NavigationStack {
        HelpSupportView()
    }
}

