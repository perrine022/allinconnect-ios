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
                                        icon: "envelope.fill",
                                        text: "contact@allinconnect.fr",
                                        iconColor: .appGold,
                                        action: {
                                            if let url = URL(string: "mailto:contact@allinconnect.fr") {
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
    @State private var expandedQuestion: String? = nil
    
    // Vérifier si l'utilisateur est un professionnel
    private var isProfessional: Bool {
        let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
        return userTypeString == "PROFESSIONAL" || userTypeString == "PRO"
    }
    
    // FAQ pour les utilisateurs finaux
    let userFAQItems: [(question: String, answer: String)] = [
        ("Qu'est-ce qu'ALL IN Connect ?", "ALL IN Connect est une application qui regroupe les bons plans locaux, les professionnels, les offres et événements près de chez vous. Grâce à la carte PASS Club 10, vous bénéficiez de réductions chez tous les professionnels membres."),
        ("Comment télécharger et utiliser l'application ?", "Téléchargez l'application depuis l'App Store ou Google Play, créez un compte gratuit et commencez à explorer les professionnels et les offres près de chez vous."),
        ("Qu'est-ce que la carte PASS Club 10 ?", "C'est une carte personnelle sur votre téléphone qui vous offre 10 % de réduction chez tous les professionnels membres du Club 10."),
        ("Combien coûte la carte PASS ?", "Le prix est indiqué lors de l'achat dans l'application. Le paiement est sécurisé via Stripe."),
        ("Puis-je annuler ou me faire rembourser ma carte PASS Club10 ?", "Non, la carte digitale est un service numérique accessible immédiatement. Conformément au Code de la consommation, il n'y a pas de droit de rétractation après activation."),
        ("Comment utiliser ma carte chez un professionnel ?", "Montrez simplement votre carte dans l'application avant le paiement pour bénéficier de la réduction."),
        ("Puis-je parrainer mes amis ?", "Oui ! Partagez votre lien de parrainage depuis l'application et gagnez une cagnotte à utiliser chez les pros du réseau quand quelqu'un s'inscrit grâce à vous."),
        ("Puis-je gérer mes notifications ?", "Oui, vous pouvez activer ou désactiver les notifications depuis les paramètres de l'application.")
    ]
    
    // FAQ pour les professionnels
    let proFAQItems: [(question: String, answer: String)] = [
        ("Comment fonctionne l'abonnement professionnel ?", "L'abonnement vous permet de publier votre fiche établissement, vos offres et événements, et d'être visible auprès des utilisateurs de l'application.\n• Mensuel : 14,99 € / mois\n• Annuel : 149,99 € / an"),
        ("Comment publier une offre ou un événement ?", "Depuis votre profil dans l'application, cliquez sur \"Publier une offre\" ou \"Ajouter un événement\", définissez la période de validité et confirmez."),
        ("Puis-je supprimer ou modifier une offre après publication ?", "Oui, vous pouvez modifier ou supprimer vos offres à tout moment depuis votre espace pro."),
        ("Comment résilier mon abonnement ?", "Vous pouvez résilier votre abonnement depuis votre compte dans l'application. L'accès prendra fin à la fin de la période en cours. Aucun remboursement n'est possible pour la période déjà payée."),
        ("Comment contacter le support ?", "Pour toute question, envoyez un email à contact@allinconnect.fr depuis votre compte ou utilisez le formulaire de contact dans l'application.")
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
                        VStack(spacing: 20) {
                            // Titre
                            HStack {
                                Text("FAQ – ALL IN Connect")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Section Utilisateurs finaux
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pour les utilisateurs finaux / détenteurs de la carte digitale")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appGold)
                                    .padding(.horizontal, 20)
                                
                                ForEach(userFAQItems, id: \.question) { item in
                                    FAQItem(
                                        question: item.question,
                                        answer: item.answer,
                                        isExpanded: expandedQuestion == item.question,
                                        onToggle: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                expandedQuestion = expandedQuestion == item.question ? nil : item.question
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Section Professionnels
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pour les professionnels")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.appGold)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                
                                ForEach(proFAQItems, id: \.question) { item in
                                    FAQItem(
                                        question: item.question,
                                        answer: item.answer,
                                        isExpanded: expandedQuestion == item.question,
                                        onToggle: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                expandedQuestion = expandedQuestion == item.question ? nil : item.question
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .onAppear {
                                // Si l'utilisateur est un professionnel, dérouler automatiquement la première question
                                if isProfessional && expandedQuestion == nil && !proFAQItems.isEmpty {
                                    expandedQuestion = proFAQItems.first?.question
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
                                    
                                    ZStack(alignment: .topLeading) {
                                        if message.isEmpty {
                                            Text("Écris ton message ici...")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 18)
                                        }
                                        TextEditor(text: $message)
                                            .frame(height: 120)
                                            .padding(10)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(focusedField == .message ? Color.appGold : Color.gray.opacity(0.3), lineWidth: focusedField == .message ? 2 : 1)
                                            )
                                            .cornerRadius(10)
                                            .foregroundColor(.black)
                                            .accentColor(.appGold)
                                            .focused($focusedField, equals: .message)
                                    }
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
                                    
                                    ZStack(alignment: .topLeading) {
                                        if description.isEmpty {
                                            Text("Décris ton problème en détail...")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 18)
                                        }
                                        TextEditor(text: $description)
                                            .frame(height: 150)
                                            .padding(10)
                                            .background(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(focusedField == .description ? Color.appGold : Color.gray.opacity(0.3), lineWidth: focusedField == .description ? 2 : 1)
                                            )
                                            .cornerRadius(10)
                                            .foregroundColor(.black)
                                            .accentColor(.appGold)
                                            .focused($focusedField, equals: .description)
                                    }
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

