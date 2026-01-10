//
//  TermsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

enum TermsViewType {
    case terms
    case privacyPolicy
    case legalNotice
    case salesTerms
}

struct TermsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let viewType: TermsViewType
    
    init(viewType: TermsViewType = .terms) {
        self.viewType = viewType
    }
    
    // Compatibilité avec l'ancien initializer
    init(isPrivacyPolicy: Bool = false) {
        self.viewType = isPrivacyPolicy ? .privacyPolicy : .terms
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Titre
                            Text(getTitle())
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
    }
    
    func getTitle() -> String {
        switch viewType {
        case .terms:
            return "Conditions générales"
        case .privacyPolicy:
            return "Politique de confidentialité"
        case .legalNotice:
            return "Mentions légales"
        case .salesTerms:
            return "Conditions générales de vente"
        }
    }
    
    func getContent() -> String {
        switch viewType {
        case .privacyPolicy:
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
        case .legalNotice:
            return """
            Mentions légales
            
            Éditeur du site
            
            Le site internet https://allinconnect.fr et les applications mobiles et tablettes ALL IN Connect sont édité par la société :
            
            SAS ALL IN BY MUZ
            Société par actions simplifiée au capital de 500,00 euros
            N° TVA intracom : FR20981412182
            Siège social : 405 avenue Jean Aicard, 06700 Saint-Laurent-du-Var, France
            E-mail : contact@allinconnect.fr
            Numéro SIRET : 98141218200017
            
            Hébergement
            
            Le site est hébergé par :
            Hostinger International Ltd.
            Adresse : 61 Lordou Vironos Street, 6023 Larnaca, Chypre
            Site web : www.hostinger.fr
            
            Propriété intellectuelle
            
            L'ensemble du contenu du site et des applications mobiles et tablettes (textes, visuels, logos, structure, charte graphique, base de données, etc.) est la propriété exclusive de ALL IN BY MUZ, sauf mention contraire.
            """
        case .salesTerms:
            return """
            Conditions Générales de Vente (CGV) – Application ALL IN Connect
            
            1. Objet
            
            Les présentes Conditions Générales de Vente (CGV) régissent :
            • l'achat et l'utilisation de la carte PASS Club 10 par les utilisateurs finaux,
            • la souscription des abonnements professionnels pour l'accès à la plateforme, la publication de fiches établissements et d'offres.
            
            Elles s'appliquent à toute utilisation payante de l'application ALL IN Connect.
            
            2. CGV – Utilisateurs finaux (Carte digitale Club 10)
            
            Article 2.1 – Objet de la carte digitale
            
            La carte PASS Club10 permet de bénéficier de 10 % de réduction chez les professionnels membres du Club 10.
            • La carte est personnelle et dématérialisée.
            • La validité correspond à la période indiquée lors de l'achat.
            
            Article 2.2 – Prix et paiement
            
            • Abonnement mensuel : 2,99€ TTC / mois
            • Abonnement annuel : 29,99€ TTC / an
            • Abonnement mensuel Famille : 7,99€ TTC / mois
            • Abonnement annuel Famille : 79,99€ TTC / an
            • Le prix est indiqué en euros TTC.
            • Le paiement s'effectue via la plateforme de paiement sécurisé Stripe.
            • ALL IN Connect n'a pas accès aux informations bancaires.
            
            Article 2.3 – Absence de droit de rétractation
            
            Conformément à l'article L221-28 du Code de la consommation, le contenu numérique accessible immédiatement ne permet pas l'exercice d'un droit de rétractation après activation.
            
            Article 2.4 – Responsabilité
            
            ALL IN Connect ne garantit pas la disponibilité des offres ou des prestations et n'est pas responsable :
            • du refus ou de la mauvaise exécution d'une prestation par un professionnel,
            • des litiges entre utilisateurs et professionnels,
            • de tout dommage indirect lié à l'utilisation de l'application.
            
            Article 2.5 – Résiliation
            
            La carte digitale prend fin à l'expiration de sa période de validité.
            ALL IN Connect peut suspendre ou résilier l'accès en cas d'abus ou de fraude.
            
            3. CGV – Professionnels (Abonnement et visibilité)
            
            Article 3.1 – Objet
            
            Les abonnements professionnels donnent accès à la plateforme ALL IN Connect et à ses fonctionnalités :
            • création et gestion d'une fiche établissement,
            • publication d'offres commerciales et d'événements,
            • visibilité auprès des utilisateurs,
            • accès aux fonctionnalités de mise en relation et de parrainage.
            
            Article 3.2 – Offres et tarifs
            • Abonnement mensuel : 14,99 € TTC / mois
            • Abonnement annuel : 149,99 € TTC / an
            
            L'abonnement ne garantit aucun volume de clients, ni chiffre d'affaires.
            
            Article 3.3 – Souscription et paiement
            • La souscription se fait via l'application.
            • Le paiement est sécurisé par Stripe et se renouvelle automatiquement sauf résiliation.
            
            Article 3.4 – Publication de contenus
            • Le professionnel est responsable des contenus publiés sur sa fiche (offres, visuels, informations).
            • Les offres restent visibles pendant la durée définie par le professionnel.
            
            ALL IN Connect se réserve le droit, sans préavis :
            • de supprimer tout contenu ou offre jugé non conforme, trompeur ou inapproprié,
            • de suspendre ou supprimer un compte professionnel en cas de non-respect des CGV ou des valeurs de la plateforme.
            
            Article 3.5 – Absence de droit de rétractation
            
            Conformément au Code de la consommation, l'abonnement donnant accès immédiat à un service numérique ne permet pas l'exercice d'un droit de rétractation.
            
            Article 3.6 – Résiliation
            • Le professionnel peut résilier son abonnement via l'application, conformément aux règles Apple / Google.
            • L'accès prend fin à l'échéance de la période en cours.
            • ALL IN Connect peut résilier un abonnement en cas d'abus ou de fraude.
            
            Article 3.7 – Responsabilité
            
            ALL IN Connect agit uniquement en tant qu'intermédiaire de visibilité et mise en relation et n'est pas responsable :
            • des résultats commerciaux,
            • des litiges entre professionnels et utilisateurs,
            • des dommages indirects liés à l'utilisation de la plateforme.
            
            4. Modification des CGV
            
            ALL IN Connect se réserve le droit de modifier ces CGV à tout moment.
            Les utilisateurs et professionnels seront informés des modifications lors de leur prochaine connexion à l'application.
            L'utilisation continue de l'application vaut acceptation des CGV mises à jour.
            
            5. Droit applicable
            
            Les présentes CGV sont soumises au droit français.
            """
        case .terms:
            return """
            Conditions Générales d'Utilisation (CGU) – Application ALL IN Connect
            
            Article 1 – Objet
            
            Les présentes Conditions Générales d'Utilisation ont pour objet d'encadrer les modalités d'accès et d'utilisation des applications mobiles et tablettes ALL IN Connect.
            
            ALL IN Connect est une plateforme locale de mise en relation entre consommateurs et professionnels indépendants, favorisant la recommandation, le bouche-à-oreille digital et l'accès à des avantages exclusifs, notamment via la carte PASS Club 10.
            
            L'Application permet notamment :
            • la consultation de fiches établissements de professionnels locaux,
            • l'accès à des offres commerciales et événements publiés par les professionnels,
            • la gestion d'une carte PASS Club10 donnant droit à des avantages privilégiés,
            • des fonctionnalités communautaires (favoris, notes, parrainage, notifications).
            
            Article 2 – Accès à l'Application
            
            L'Application est accessible gratuitement à tout utilisateur disposant d'un appareil compatible et d'une connexion Internet.
            
            Certaines fonctionnalités nécessitent :
            • la création d'un compte utilisateur,
            • et/ou la souscription à des options payantes (ex. carte PASS Club 10).
            
            ALL IN Connect se réserve le droit de suspendre temporairement l'accès à l'Application pour des raisons techniques, de maintenance ou de mise à jour.
            
            Article 3 – Inscription et compte utilisateur
            
            L'inscription à l'Application implique la fourniture d'informations exactes, complètes et à jour.
            
            Chaque utilisateur est responsable de :
            • la confidentialité de ses identifiants,
            • l'utilisation faite de son compte.
            
            ALL IN Connect se réserve le droit de suspendre ou supprimer tout compte utilisateur en cas :
            • de non-respect des présentes CGU,
            • d'utilisation frauduleuse ou abusive de l'Application,
            • de comportement portant atteinte au bon fonctionnement de la plateforme ou à l'image du réseau.
            
            Article 4 – Fonctionnalités de l'Application
            
            L'Application permet notamment aux utilisateurs :
            • de consulter les professionnels référencés par catégorie,
            • de mettre en favori une fiche établissement,
            • de noter les professionnels sur une échelle de 1 à 5,
            • de gérer leurs préférences de notifications,
            • de parrainer d'autres utilisateurs et bénéficier d'avantages associés.
            
            Les professionnels référencés peuvent, sous leur responsabilité :
            • publier des offres commerciales et/ou événements,
            • définir une durée de validité pour chaque offre,
            • mettre à jour leurs informations visibles sur leur fiche établissement.
            
            Les offres publiées restent visibles pendant leur période de validité, sauf suppression anticipée conformément à l'article 5.
            
            Article 5 – Contenus publiés et modération
            
            Chaque professionnel est seul responsable des contenus qu'il publie sur l'Application (textes, visuels, offres, pratiques commerciales).
            
            ALL IN Connect se réserve le droit, sans préavis, de :
            • supprimer toute offre ou contenu jugé inapproprié, trompeur, non conforme à la réglementation ou à l'esprit de la plateforme,
            • suspendre ou supprimer la fiche d'un professionnel si ses contenus, pratiques ou comportements sont jugés incohérents, abusifs ou contraires aux valeurs d'ALL IN Connect.
            
            ALL IN Connect n'exerce aucun contrôle préalable systématique sur les contenus publiés et ne garantit ni leur exactitude, ni leur légalité, ni la qualité des prestations proposées par les professionnels.
            
            Article 6 – Responsabilité
            
            ALL IN Connect met en œuvre les moyens raisonnables pour assurer le bon fonctionnement de l'Application.
            
            Toutefois, la responsabilité d'ALL IN Connect ne saurait être engagée en cas :
            • d'interruptions temporaires ou dysfonctionnements techniques,
            • d'erreurs indépendantes de sa volonté,
            • de litiges entre utilisateurs et professionnels,
            • de dommages indirects liés à l'utilisation de l'Application.
            
            Les prestations, offres et réductions proposées relèvent exclusivement de la responsabilité des professionnels concernés.
            
            Article 7 – Données personnelles
            
            Les données personnelles collectées via l'Application sont traitées conformément à la Politique de confidentialité d'ALL IN Connect.
            
            L'utilisateur dispose à tout moment d'un droit d'accès, de rectification et de suppression de ses données, conformément à la réglementation en vigueur.
            
            Article 8 – Propriété intellectuelle
            
            L'Application, son contenu, sa structure, son design et ses fonctionnalités sont protégés par le droit de la propriété intellectuelle.
            
            Toute reproduction, représentation ou exploitation, totale ou partielle, sans autorisation préalable écrite d'ALL IN Connect est interdite.
            
            Article 9 – Modification des CGU
            
            ALL IN Connect se réserve le droit de modifier les présentes CGU à tout moment.
            
            Les utilisateurs seront informés des modifications lors de leur prochaine utilisation de l'Application. L'utilisation continue de l'Application vaut acceptation des CGU mises à jour.
            """
        }
    }
}

#Preview {
    NavigationStack {
        TermsView(viewType: .terms)
            .environmentObject(AppState())
    }
}

