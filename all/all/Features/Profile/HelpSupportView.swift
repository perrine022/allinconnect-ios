//
//  HelpSupportView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import UIKit

struct HelpSupportView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection?
    
    enum HelpSection: String, Identifiable {
        case faq = "FAQ"
        case contact = "Nous contacter"
        case report = "Signaler un problème"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .faq: return "questionmark.circle.fill"
            case .contact: return "envelope.fill"
            case .report: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
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
                                ForEach([HelpSection.faq, .contact, .report], id: \.id) { section in
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
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(maxWidth: .infinity)
                                    
                                    if section != .report {
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
                                            let phoneNumber = "0478000000"
                                            if let url = URL(string: "tel://\(phoneNumber)") {
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
        .navigationDestination(item: $selectedSection) { section in
            switch section {
            case .faq:
                FAQView()
            case .contact:
                ContactFormView()
            case .report:
                ReportProblemView()
            }
        }
    }
}

// MARK: - FAQ View
struct FAQView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var expandedQuestion: Int? = nil
    
    let faqItems: [(question: String, answer: String)] = [
        ("Comment devenir partenaire ALL IN Connect ?", "Pour devenir partenaire, vous devez créer un compte professionnel depuis l'application. Rendez-vous dans votre profil, section 'Espace Pro' et suivez les étapes d'inscription. Un commercial vous contactera sous 48h pour finaliser votre adhésion."),
        ("Quels sont les avantages pour mon établissement ?", "En tant que partenaire, vous bénéficiez d'une visibilité accrue auprès de notre communauté, d'un système de gestion d'offres intégré, d'analyses de performance et d'un accès au réseau CLUB10 pour développer votre clientèle."),
        ("Comment créer et gérer mes offres ?", "Dans votre espace Pro, accédez à 'Mes offres' puis cliquez sur 'Créer une offre'. Vous pouvez définir le titre, la description, la réduction, la durée de validité et une image. Modifiez ou supprimez vos offres à tout moment."),
        ("Comment fonctionne le système de réduction CLUB10 ?", "Les membres CLUB10 bénéficient automatiquement de 10% de réduction chez tous les partenaires. La réduction est appliquée directement lors du paiement. Vous recevez le montant complet, la différence étant prise en charge par ALL IN Connect."),
        ("Quels sont les frais d'adhésion pour les partenaires ?", "L'adhésion est mensuelle avec un engagement minimum. Les tarifs varient selon votre secteur d'activité et votre localisation. Contactez-nous pour obtenir un devis personnalisé adapté à votre établissement."),
        ("Comment gérer les informations de mon établissement ?", "Dans votre profil Pro, accédez à 'Gérer mon établissement' pour modifier vos coordonnées, votre adresse, vos horaires, votre description et votre photo. Les modifications sont visibles immédiatement sur votre fiche partenaire."),
        ("Comment voir les statistiques de mon établissement ?", "Les statistiques (vues, clics, appels, favoris) sont disponibles dans votre espace Pro. Ces données vous permettent de suivre la performance de votre présence sur la plateforme."),
        ("Puis-je proposer des offres spéciales à mes clients ?", "Oui, vous pouvez créer des offres ponctuelles ou récurrentes. Les offres peuvent être limitées dans le temps, avec un nombre de places disponibles, ou permanentes. Vous avez un contrôle total sur vos promotions."),
        ("Comment les clients me contactent-ils ?", "Les clients peuvent vous appeler directement depuis votre fiche, vous envoyer un email, visiter votre site web ou vous suivre sur Instagram. Tous ces moyens de contact sont intégrés dans votre profil partenaire."),
        ("Que faire en cas de problème technique ?", "Si vous rencontrez un problème, utilisez la section 'Signaler un problème' dans Aide & Support. Notre équipe technique répond sous 24h. Vous pouvez aussi nous appeler au 04 78 00 00 00 ou nous écrire à support@allinconnect.fr.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 16) {
                            // Titre
                            HStack {
                                Text("FAQ")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Questions
                            VStack(spacing: 12) {
                                ForEach(Array(faqItems.enumerated()), id: \.offset) { index, item in
                                    FAQItem(
                                        question: item.question,
                                        answer: item.answer,
                                        isExpanded: expandedQuestion == index,
                                        onToggle: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                expandedQuestion = expandedQuestion == index ? nil : index
                                            }
                                        }
                                    )
                                }
                            }
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
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 12) {
                    Text(question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.appGold)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 2)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Text(answer)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.appDarkRed1.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Contact Form View
struct ContactFormView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, email, subject, message
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 20) {
                            // Titre
                            HStack {
                                Text("Nous contacter")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Formulaire
                            VStack(spacing: 16) {
                                // Nom
                                ContactInputField(
                                    title: "Nom",
                                    text: $name,
                                    placeholder: "Votre nom",
                                    isFocused: focusedField == .name
                                )
                                .focused($focusedField, equals: .name)
                                
                                // Email
                                ContactInputField(
                                    title: "Email",
                                    text: $email,
                                    placeholder: "votre@email.fr",
                                    keyboardType: .emailAddress,
                                    isFocused: focusedField == .email
                                )
                                .focused($focusedField, equals: .email)
                                .autocapitalization(.none)
                                
                                // Sujet
                                ContactInputField(
                                    title: "Sujet",
                                    text: $subject,
                                    placeholder: "Objet de votre message",
                                    isFocused: focusedField == .subject
                                )
                                .focused($focusedField, equals: .subject)
                                
                                // Message
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Message")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    TextEditor(text: $message)
                                        .frame(height: 120)
                                        .padding(10)
                                        .background(focusedField == .message ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(focusedField == .message ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .accentColor(.appGold)
                                        .focused($focusedField, equals: .message)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Bouton Envoyer
                            Button(action: {
                                // Envoyer le message
                                // Plus tard, appeler l'API pour envoyer le message
                                dismiss()
                            }) {
                                Text("Envoyer")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isValid ? Color.appGold : Color.gray.opacity(0.5))
                                    .cornerRadius(12)
                            }
                            .disabled(!isValid)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct ContactInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.6)))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(12)
                .background(isFocused ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.appGold : Color.clear, lineWidth: 2)
                )
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Report Problem View
struct ReportProblemView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var problemType: String = ""
    @State private var description: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case problemType, description
    }
    
    let problemTypes = [
        "Problème technique",
        "Problème avec un partenaire",
        "Problème de paiement",
        "Erreur dans l'application",
        "Autre"
    ]
    
    var isValid: Bool {
        !problemType.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 20) {
                            // Titre
                            HStack {
                                Text("Signaler un problème")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Formulaire
                            VStack(spacing: 16) {
                                // Type de problème
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Type de problème")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Menu {
                                        ForEach(problemTypes, id: \.self) { type in
                                            Button(type) {
                                                problemType = type
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(problemType.isEmpty ? "Sélectionner un type" : problemType)
                                                .font(.system(size: 15))
                                                .foregroundColor(problemType.isEmpty ? .gray.opacity(0.6) : .white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .padding(12)
                                        .background(Color.appDarkRed1.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(focusedField == .problemType ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description du problème")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    TextEditor(text: $description)
                                        .frame(height: 150)
                                        .padding(10)
                                        .background(focusedField == .description ? Color.appDarkRed1.opacity(0.8) : Color.appDarkRed1.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(focusedField == .description ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                        .accentColor(.appGold)
                                        .focused($focusedField, equals: .description)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Bouton Envoyer
                            Button(action: {
                                // Envoyer le signalement
                                // Plus tard, appeler l'API pour envoyer le signalement
                                dismiss()
                            }) {
                                Text("Envoyer le signalement")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(isValid ? Color.appGold : Color.gray.opacity(0.5))
                                    .cornerRadius(12)
                            }
                            .disabled(!isValid)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    NavigationStack {
        HelpSupportView()
            .environmentObject(AppState())
    }
}

