//
//  SettingsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection?
    @State private var changePasswordNavigationId: UUID?
    
    enum SettingsSection: String, Identifiable {
        case helpSupport = "Aide & Support"
        case terms = "Conditions générales"
        case privacyPolicy = "Politique de confidentialité"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .helpSupport: return "questionmark.circle.fill"
            case .terms: return "doc.text.fill"
            case .privacyPolicy: return "shield.fill"
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
                                Text("Paramètres")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Sections
                            VStack(spacing: 0) {
                                ForEach([SettingsSection.helpSupport, .terms, .privacyPolicy], id: \.id) { section in
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
                                    
                                    if section != .privacyPolicy {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                            .padding(.leading, 54)
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 54)
                                
                                // Changer mon mot de passe
                                Button(action: {
                                    changePasswordNavigationId = UUID()
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.appGold)
                                            .font(.system(size: 18))
                                            .frame(width: 24)
                                        
                                        Text("Changer mon mot de passe")
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
                            }
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
                VStack(spacing: 8) {
                    Spacer()
                    
                    // Texte "Made with love ❤️ par Codyxo.com"
                    Text("Made with love ❤️ par Codyxo.com")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 4)
                    
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
            case .helpSupport:
                HelpSupportView()
            case .terms:
                TermsView(isPrivacyPolicy: false)
            case .privacyPolicy:
                TermsView(isPrivacyPolicy: true)
            }
        }
        .navigationDestination(item: $changePasswordNavigationId) { _ in
            ChangePasswordView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}

