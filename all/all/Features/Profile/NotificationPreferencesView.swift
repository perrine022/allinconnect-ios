//
//  NotificationPreferencesView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @Environment(\.dismiss) private var dismiss
    
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
                    .padding(.top, 20)
                    
                    // Section "Catégories"
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Catégories :")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            CategoryToggleRow(
                                emoji: "🤸",
                                title: "Sport & Santé",
                                isOn: $viewModel.sportHealth
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 60)
                            
                            CategoryToggleRow(
                                emoji: "💅",
                                title: "Esthétique",
                                isOn: $viewModel.aesthetics
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 60)
                            
                            CategoryToggleRow(
                                emoji: "🎮",
                                title: "Divertissement",
                                isOn: $viewModel.entertainment
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 60)
                            
                            CategoryToggleRow(
                                emoji: "🍔",
                                title: "Food",
                                isOn: $viewModel.food
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
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("Préférences de notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            Text(emoji)
                .font(.system(size: 20))
            
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
    }
}

