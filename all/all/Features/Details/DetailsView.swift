//
//  DetailsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct DetailsView: View {
    let professional: Professional
    @State private var isFavorite: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(professional: Professional) {
        self.professional = professional
        _isFavorite = State(initialValue: professional.isFavorite)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background avec gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.05, blue: 0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header avec photo
                        ProfileHeaderView(
                            firstName: professional.firstName,
                            lastName: professional.lastName,
                            profession: professional.profession,
                            category: professional.category,
                            profileImageName: professional.profileImageName
                        )
                        
                        // Contenu principal
                        VStack(alignment: .leading, spacing: 0) {
                            // Nom et prénom avec style premium
                            VStack(alignment: .leading, spacing: 6) {
                                Text(professional.firstName.uppercased())
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .tracking(1)
                                
                                Text(professional.lastName.uppercased())
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.appRed)
                                    .tracking(1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            
                            // Profession avec badge rouge
                            HStack(spacing: 12) {
                                Text(professional.profession)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                BadgeView(text: professional.category)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            // Séparateur rouge
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.appRed.opacity(0.6),
                                            Color.appRed.opacity(0.2),
                                            Color.clear
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 2)
                                .padding(.horizontal, 24)
                                .padding(.top, 24)
                            
                            // Section Localisation
                            InfoSection(
                                title: "LOCALISATION",
                                icon: "mappin.circle.fill",
                                iconColor: .appRed
                            ) {
                                Button(action: {
                                    let address = "\(professional.address), \(professional.postalCode) \(professional.city)"
                                    let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                    
                                    // Essayer d'abord Apple Maps
                                    if let appleMapsURL = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
                                        UIApplication.shared.open(appleMapsURL) { success in
                                            // Si Apple Maps échoue, essayer Google Maps
                                            if !success {
                                                if let googleMapsURL = URL(string: "comgooglemaps://?q=\(encodedAddress)") {
                                                    if UIApplication.shared.canOpenURL(googleMapsURL) {
                                                        UIApplication.shared.open(googleMapsURL)
                                                    } else {
                                                        // Fallback vers Google Maps web
                                                        if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedAddress)") {
                                                            UIApplication.shared.open(webURL)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.appRed)
                                                .font(.system(size: 18))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(professional.address)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Text("\(professional.postalCode) \(professional.city)")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.appTextSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray.opacity(0.6))
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.top, 32)
                            
                            // Section Contact
                            if professional.phone != nil || professional.email != nil {
                                InfoSection(
                                    title: "CONTACT",
                                    icon: "phone.fill",
                                    iconColor: .appRed
                                ) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        if let phone = professional.phone {
                                            ContactRow(
                                                icon: "phone.fill",
                                                text: phone,
                                                action: {
                                                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))") {
                                                        UIApplication.shared.open(url)
                                                    }
                                                }
                                            )
                                        }
                                        
                                        if let email = professional.email {
                                            ContactRow(
                                                icon: "envelope.fill",
                                                text: email,
                                                action: {
                                                    if let url = URL(string: "mailto:\(email)") {
                                                        UIApplication.shared.open(url)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding(.top, 32)
                            }
                            
                            // Section Description
                            if let description = professional.description {
                                InfoSection(
                                    title: "À PROPOS",
                                    icon: "info.circle.fill",
                                    iconColor: .appRed
                                ) {
                                    Text(description)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.appTextSecondary)
                                        .lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 32)
                            }
                            
                            // Boutons d'action
                            VStack(spacing: 16) {
                                if let websiteURL = professional.websiteURL {
                                    ActionButton(
                                        title: "VISITER LE SITE WEB",
                                        icon: "globe",
                                        gradientColors: [Color.appRed, Color.appDarkRed],
                                        action: {
                                            if let url = URL(string: websiteURL) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    )
                                }
                                
                                if let instagramURL = professional.instagramURL {
                                    ActionButton(
                                        title: "SUIVRE SUR INSTAGRAM",
                                        icon: "camera.fill",
                                        gradientColors: [Color(red: 0.8, green: 0.2, blue: 0.5), Color(red: 0.6, green: 0.1, blue: 0.3)],
                                        action: {
                                            if let url = URL(string: instagramURL) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                            .padding(.bottom, 100) // Espace pour le footer
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.appBackground)
                        )
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "xmark", action: {
                    dismiss()
                })
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                FavoriteButton(isFavorite: $isFavorite, action: {})
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailsView(professional: Professional(
            firstName: "Marc",
            lastName: "Dubois",
            profession: "Coiffeur Expert",
            category: "Beauté & Bien-être",
            address: "15 Rue de la République",
            city: "Paris",
            postalCode: "75001",
            phone: "+33 1 23 45 67 89",
            email: "marc.dubois@example.com",
            profileImageName: "person.circle.fill",
            websiteURL: "https://example.com",
            instagramURL: "https://instagram.com",
            description: "Coiffeur expert avec plus de 10 ans d'expérience. Spécialisé dans les coupes modernes et les colorations. Passionné par la mode et les tendances capillaires, je vous accompagne pour trouver le style qui vous correspond."
        ))
    }
}
