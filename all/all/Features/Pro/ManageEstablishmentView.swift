//
//  ManageEstablishmentView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine

struct ManageEstablishmentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManageEstablishmentViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, description, address, city, postalCode, phone, email, website
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
                        Text("Gérer mon établissement")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Photo de l'établissement
                    VStack(spacing: 12) {
                        Text("Photo de l'établissement")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            // Action pour changer la photo
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appDarkRed1.opacity(0.6))
                                    .frame(height: 200)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                    
                                    Text("Ajouter une photo")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Formulaire
                    VStack(spacing: 16) {
                        // Nom de l'établissement
                        InputField(
                            title: "Nom de l'établissement",
                            text: $viewModel.name,
                            placeholder: "Ex: Fit & Forme Studio"
                        )
                        .focused($focusedField, equals: .name)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextEditor(text: $viewModel.description)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .accentColor(.appGold)
                                .focused($focusedField, equals: .description)
                        }
                        .padding(.horizontal, 20)
                        
                        // Adresse
                        InputField(
                            title: "Adresse",
                            text: $viewModel.address,
                            placeholder: "Ex: 28 Avenue Victor Hugo"
                        )
                        .focused($focusedField, equals: .address)
                        
                        // Ville et Code postal
                        HStack(spacing: 12) {
                            InputField(
                                title: "Ville",
                                text: $viewModel.city,
                                placeholder: "Ex: Lyon"
                            )
                            .focused($focusedField, equals: .city)
                            
                            InputField(
                                title: "Code postal",
                                text: $viewModel.postalCode,
                                placeholder: "69001"
                            )
                            .focused($focusedField, equals: .postalCode)
                            .frame(width: 120)
                        }
                        
                        // Téléphone
                        InputField(
                            title: "Téléphone",
                            text: $viewModel.phone,
                            placeholder: "Ex: 04 78 12 34 56"
                        )
                        .focused($focusedField, equals: .phone)
                        .keyboardType(.phonePad)
                        
                        // Email
                        InputField(
                            title: "Email",
                            text: $viewModel.email,
                            placeholder: "contact@etablissement.fr"
                        )
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        
                        // Site web
                        InputField(
                            title: "Site web (optionnel)",
                            text: $viewModel.website,
                            placeholder: "https://www.exemple.fr"
                        )
                        .focused($focusedField, equals: .website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    }
                    
                    // Bouton Enregistrer
                    Button(action: {
                        viewModel.saveEstablishment()
                        dismiss()
                    }) {
                        Text("Enregistrer les modifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isValid ? Color.appGold : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.6)))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.appDarkRed1.opacity(0.6))
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 20)
    }
}

@MainActor
class ManageEstablishmentViewModel: ObservableObject {
    @Published var name: String = "Fit & Forme Studio"
    @Published var description: String = "Salle de sport moderne avec équipements de dernière génération."
    @Published var address: String = "28 Avenue Victor Hugo"
    @Published var city: String = "Lyon"
    @Published var postalCode: String = "69001"
    @Published var phone: String = "04 78 12 34 56"
    @Published var email: String = "contact@fitforme.fr"
    @Published var website: String = "https://fitforme.fr"
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func saveEstablishment() {
        // Sauvegarder les modifications
        // Plus tard, appeler l'API pour mettre à jour l'établissement
    }
}

#Preview {
    NavigationStack {
        ManageEstablishmentView()
    }
}

