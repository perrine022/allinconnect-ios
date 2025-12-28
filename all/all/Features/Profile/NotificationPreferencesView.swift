//
//  NotificationPreferencesView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
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
                                Text("Préférences de notifications")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Section "Je souhaite recevoir"
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Je souhaite recevoir :")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 0) {
                                    NotificationToggleRow(
                                        title: "Nouvelles offres",
                                        isOn: $viewModel.newOffers
                                    )
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 60)
                                    
                                    NotificationToggleRow(
                                        title: "Nouvel indépendant dans mon secteur",
                                        isOn: $viewModel.newIndependent
                                    )
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 60)
                                    
                                    NotificationToggleRow(
                                        title: "Événements locaux",
                                        isOn: $viewModel.localEvents
                                    )
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 60)
                                    
                                    NotificationToggleRow(
                                        title: "Nouvelles offres selon ma localisation",
                                        isOn: $viewModel.localizedOffers
                                    )
                                }
                                .background(Color.appDarkRed1.opacity(0.8))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // Section "Catégories" (mêmes que homepage)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Catégories :")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(viewModel.categories.enumerated()), id: \.element.key) { index, category in
                                        CategoryToggleRow(
                                            emoji: category.emoji,
                                            title: category.title,
                                            isOn: bindingForCategory(category.key)
                                        )
                                        
                                        if index < viewModel.categories.count - 1 {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                                .padding(.leading, 16)
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
    
    private func bindingForCategory(_ key: String) -> Binding<Bool> {
        switch key {
        case "santeBienEtre":
            return $viewModel.santeBienEtre
        case "beauteEsthetique":
            return $viewModel.beauteEsthetique
        case "foodPlaisirsGourmands":
            return $viewModel.foodPlaisirsGourmands
        case "loisirsDivertissements":
            return $viewModel.loisirsDivertissements
        case "servicePratiques":
            return $viewModel.servicePratiques
        case "entrePros":
            return $viewModel.entrePros
        default:
            return .constant(false)
        }
    }
}

struct NotificationToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .appRed))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct CategoryToggleRow: View {
    let emoji: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .appRed))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
            .environmentObject(AppState())
    }
}

