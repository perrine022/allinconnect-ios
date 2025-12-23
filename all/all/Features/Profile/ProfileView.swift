//
//  ProfileView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @State private var user: User = User(
        firstName: "Sophie",
        lastName: "Martin",
        username: "sophie.martin",
        bio: "Passionnée de design & photographie 📸\nPartage mon quotidien et mes créations ✨",
        profileImageName: "person.circle.fill",
        publications: 342,
        subscribers: 12500,
        subscriptions: 892
    )
    @State private var showEditProfile = false
    @State private var showMoreOptions = false
    
    var body: some View {
        ZStack {
            // Background blanc
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header avec gradient violet
                    ZStack(alignment: .top) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.9),
                                Color(red: 0.5, green: 0.2, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                        .ignoresSafeArea(edges: .top)
                        
                        // Bouton menu trois points
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showMoreOptions.toggle()
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .semibold))
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    
                    // Contenu principal
                    VStack(spacing: 0) {
                        // Photo de profil qui chevauche
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: user.profileImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                )
                                .foregroundColor(.gray.opacity(0.3))
                                .offset(y: -60)
                            
                            // Bouton caméra pour éditer la photo
                            Button(action: {
                                // Action pour changer la photo
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.6, green: 0.3, blue: 0.9),
                                                    Color(red: 0.5, green: 0.2, blue: 0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .offset(x: -8, y: -60)
                        }
                        .frame(height: 60)
                        .padding(.bottom, 20)
                        
                        // Nom de l'utilisateur
                        Text(user.fullName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 8)
                        
                        // Username
                        Text("@\(user.username)")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        // Bio
                        Text(user.bio)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                            .padding(.top, 12)
                        
                        // Statistiques
                        HStack(spacing: 0) {
                            StatCard(
                                value: user.publications,
                                label: "Publications",
                                valueColor: .black,
                                labelColor: .gray
                            )
                            
                            Spacer()
                            
                            StatCard(
                                value: user.subscribers,
                                label: "Abonnés",
                                valueColor: .black,
                                labelColor: .gray
                            )
                            
                            Spacer()
                            
                            StatCard(
                                value: user.subscriptions,
                                label: "Abonnements",
                                valueColor: .black,
                                labelColor: .gray
                            )
                        }
                        .padding(.horizontal, 50)
                        .padding(.top, 32)
                        
                        // Boutons d'action
                        HStack(spacing: 12) {
                            // Bouton Modifier le profil
                            Button(action: {
                                showEditProfile.toggle()
                            }) {
                                Text("Modifier le profil")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.6, green: 0.3, blue: 0.9),
                                                Color(red: 0.5, green: 0.2, blue: 0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            
                            // Bouton partage
                            Button(action: {
                                // Action de partage
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.black)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                    .background(Color.white)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: $user)
        }
        .confirmationDialog("Options", isPresented: $showMoreOptions, titleVisibility: .hidden) {
            Button("Paramètres") {}
            Button("Signaler") {}
            Button("Annuler", role: .cancel) {}
        }
    }
}

struct EditProfileView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack {
                    Text("Édition du profil")
                        .font(.title2)
                        .foregroundColor(.black)
                    
                    // Formulaire d'édition ici
                }
            }
            .navigationTitle("Modifier le profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

