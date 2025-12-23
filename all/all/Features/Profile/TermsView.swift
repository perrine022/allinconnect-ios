//
//  TermsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct TermsView: View {
    let isPrivacyPolicy: Bool
    
    init(isPrivacyPolicy: Bool = false) {
        self.isPrivacyPolicy = isPrivacyPolicy
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
                VStack(alignment: .leading, spacing: 24) {
                    // Titre
                    Text(isPrivacyPolicy ? "Politique de confidentialité" : "Conditions générales")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Contenu
                    VStack(alignment: .leading, spacing: 20) {
                        Text(getContent())
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(6)
                    }
                    .padding(20)
                    .background(Color.appDarkRed1.opacity(0.8))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle(isPrivacyPolicy ? "Politique de confidentialité" : "Conditions générales")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    func getContent() -> String {
        if isPrivacyPolicy {
            return """
            Politique de confidentialité
            
            Dernière mise à jour : Décembre 2025
            
            1. Collecte des données
            
            ALL IN Connect collecte les données suivantes :
            - Informations de compte (nom, prénom, email)
            - Données de localisation (si autorisé)
            - Préférences et favoris
            - Données d'utilisation de l'application
            
            2. Utilisation des données
            
            Vos données sont utilisées pour :
            - Fournir et améliorer nos services
            - Personnaliser votre expérience
            - Vous envoyer des notifications pertinentes
            - Analyser l'utilisation de l'application
            
            3. Partage des données
            
            Nous ne vendons pas vos données personnelles. Nous pouvons partager vos données uniquement avec :
            - Les partenaires pour la gestion des réductions
            - Les prestataires de services techniques
            
            4. Vos droits
            
            Conformément au RGPD, vous disposez des droits suivants :
            - Droit d'accès à vos données
            - Droit de rectification
            - Droit à l'effacement
            - Droit à la portabilité
            - Droit d'opposition
            
            5. Sécurité
            
            Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos données personnelles.
            
            6. Contact
            
            Pour toute question concernant vos données personnelles, contactez-nous à :
            privacy@allinconnect.fr
            """
        } else {
            return """
            Conditions générales d'utilisation
            
            Dernière mise à jour : Décembre 2025
            
            1. Acceptation des conditions
            
            En utilisant l'application ALL IN Connect, vous acceptez les présentes conditions générales d'utilisation.
            
            2. Description du service
            
            ALL IN Connect est une application mobile permettant de :
            - Découvrir des partenaires locaux
            - Bénéficier de réductions exclusives
            - Gérer votre carte digitale CLUB10
            - Accéder à des offres promotionnelles
            
            3. Compte utilisateur
            
            Pour utiliser certaines fonctionnalités, vous devez créer un compte. Vous êtes responsable de la confidentialité de vos identifiants.
            
            4. Utilisation de l'application
            
            Vous vous engagez à :
            - Utiliser l'application conformément à sa destination
            - Ne pas utiliser l'application à des fins illégales
            - Respecter les droits des autres utilisateurs
            
            5. Réductions et offres
            
            Les réductions et offres sont soumises aux conditions spécifiques de chaque partenaire. ALL IN Connect ne garantit pas la disponibilité permanente des offres.
            
            6. Propriété intellectuelle
            
            Tous les contenus de l'application sont protégés par le droit d'auteur et appartiennent à ALL IN Connect ou à ses partenaires.
            
            7. Limitation de responsabilité
            
            ALL IN Connect ne peut être tenu responsable des dommages résultant de l'utilisation de l'application.
            
            8. Modification des conditions
            
            Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications seront notifiées aux utilisateurs.
            
            9. Contact
            
            Pour toute question : contact@allinconnect.fr
            """
        }
    }
}

#Preview {
    NavigationStack {
        TermsView()
    }
}

