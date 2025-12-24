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
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ManageEstablishmentViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, description, address, city, postalCode, phone, email, website, openingHours
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
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
                        VStack(spacing: 16) {
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
                            VStack(spacing: 8) {
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
                                            .frame(height: 150)
                                        
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray.opacity(0.6))
                                            
                                            Text("Ajouter une photo")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Formulaire
                            VStack(spacing: 12) {
                                // Nom de l'établissement
                                InputField(
                                    title: "Nom de l'établissement",
                                    text: $viewModel.name,
                                    placeholder: "Ex: Fit & Forme Studio",
                                    isFocused: focusedField == .name
                                )
                                .focused($focusedField, equals: .name)
                                
                                // Description
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Description")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    TextEditor(text: $viewModel.description)
                                        .frame(height: 80)
                                        .padding(10)
                                        .background(focusedField == .description ? Color.white.opacity(0.95) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(focusedField == .description ? Color.appGold : Color.clear, lineWidth: 2)
                                        )
                                        .cornerRadius(10)
                                        .foregroundColor(.black)
                                        .accentColor(.appGold)
                                        .focused($focusedField, equals: .description)
                                }
                                .padding(.horizontal, 20)
                                
                                // Adresse
                                InputField(
                                    title: "Adresse",
                                    text: $viewModel.address,
                                    placeholder: "Ex: 28 Avenue Victor Hugo",
                                    isFocused: focusedField == .address
                                )
                                .focused($focusedField, equals: .address)
                                
                                // Ville et Code postal
                                HStack(spacing: 12) {
                                    InputField(
                                        title: "Ville",
                                        text: $viewModel.city,
                                        placeholder: "Ex: Lyon",
                                        isFocused: focusedField == .city
                                    )
                                    .focused($focusedField, equals: .city)
                                    
                                    InputField(
                                        title: "Code postal",
                                        text: $viewModel.postalCode,
                                        placeholder: "69001",
                                        isFocused: focusedField == .postalCode
                                    )
                                    .focused($focusedField, equals: .postalCode)
                                    .frame(width: 120)
                                }
                                
                                // Téléphone
                                InputField(
                                    title: "Téléphone",
                                    text: $viewModel.phone,
                                    placeholder: "Ex: 04 78 12 34 56",
                                    isFocused: focusedField == .phone
                                )
                                .focused($focusedField, equals: .phone)
                                .keyboardType(.phonePad)
                                
                                // Email
                                InputField(
                                    title: "Email",
                                    text: $viewModel.email,
                                    placeholder: "contact@etablissement.fr",
                                    isFocused: focusedField == .email
                                )
                                .focused($focusedField, equals: .email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                
                                // Site web
                                InputField(
                                    title: "Site web (optionnel)",
                                    text: $viewModel.website,
                                    placeholder: "https://www.exemple.fr",
                                    isFocused: focusedField == .website
                                )
                                .focused($focusedField, equals: .website)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                
                                // Horaires d'ouverture
                                InputField(
                                    title: "Horaires d'ouverture",
                                    text: $viewModel.openingHours,
                                    placeholder: "Ex: Lun-Ven: 9h-19h, Sam: 9h-18h",
                                    isFocused: focusedField == .openingHours
                                )
                                .focused($focusedField, equals: .openingHours)
                            }
                            
                            // Messages d'erreur et de succès
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                            }
                            
                            if let successMessage = viewModel.successMessage {
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                            }
                            
                            // Bouton Enregistrer
                            Button(action: {
                                viewModel.saveEstablishment()
                                // Ne pas fermer automatiquement, attendre le succès
                                if viewModel.successMessage != nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    } else {
                                        Text("Enregistrer les modifications")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((viewModel.isValid && !viewModel.isLoading) ? Color.appGold : Color.gray.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.isValid || viewModel.isLoading)
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
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
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
    var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray.opacity(0.6)))
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(12)
                .background(isFocused ? Color.white.opacity(0.95) : Color.white)
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
    @Published var openingHours: String = "Lun-Ven: 9h-19h, Sam: 9h-18h"
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var profession: String? = nil
    @Published var category: OfferCategory? = nil
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let profileAPIService: ProfileAPIService
    private let locationService: LocationService
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        locationService: LocationService = LocationService.shared
    ) {
        // Créer le service dans un contexte MainActor
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        self.locationService = locationService
        
        // Charger la localisation si disponible
        if let location = locationService.currentLocation {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }
    
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
        guard isValid else {
            errorMessage = "Veuillez remplir tous les champs obligatoires"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // Créer la requête de mise à jour (champs établissement uniquement)
                let updateRequest = UpdateProfileRequest(
                    firstName: nil, // Pas de modification du prénom ici
                    lastName: nil, // Pas de modification du nom ici
                    email: nil, // Pas de modification de l'email ici
                    address: address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces),
                    birthDate: nil, // Pas de modification de la date de naissance ici
                    latitude: latitude,
                    longitude: longitude,
                    establishmentName: name.trimmingCharacters(in: .whitespaces),
                    establishmentDescription: description.trimmingCharacters(in: .whitespaces),
                    phoneNumber: phone.trimmingCharacters(in: .whitespaces),
                    website: website.trimmingCharacters(in: .whitespaces).isEmpty ? nil : website.trimmingCharacters(in: .whitespaces),
                    openingHours: openingHours.trimmingCharacters(in: .whitespaces).isEmpty ? nil : openingHours.trimmingCharacters(in: .whitespaces),
                    profession: profession?.trimmingCharacters(in: .whitespaces),
                    category: category
                )
                
                // Appeler l'API
                try await profileAPIService.updateProfile(updateRequest)
                
                isLoading = false
                successMessage = "Fiche établissement mise à jour avec succès"
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors de la mise à jour de la fiche établissement: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageEstablishmentView()
            .environmentObject(AppState())
    }
}

