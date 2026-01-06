//
//  ManageEstablishmentView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import Combine
import CoreLocation
import PhotosUI

struct ManageEstablishmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ManageEstablishmentViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, description, address, city, postalCode, phone, email, website, instagram, openingHours
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
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
                            
                            // Indicateur de chargement des données
                            if viewModel.isLoadingData {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            }
                            
                            // Photo de l'établissement
                            VStack(spacing: 8) {
                                Text("Photo de l'établissement")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                PhotosPicker(
                                    selection: $viewModel.selectedImageItem,
                                    matching: .images
                                ) {
                                    ZStack {
                                        // Afficher l'image sélectionnée ou l'image existante
                                        if let selectedImage = viewModel.selectedImage {
                                            Image(uiImage: selectedImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 150)
                                                .clipped()
                                        } else if let imageUrl = viewModel.establishmentImageUrl, let url = URL(string: imageUrl) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                case .failure:
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(.gray.opacity(0.6))
                                                @unknown default:
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 32))
                                                        .foregroundColor(.gray.opacity(0.6))
                                                }
                                            }
                                            .frame(height: 150)
                                            .clipped()
                                        } else {
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
                                        
                                        // Overlay pour indiquer que c'est cliquable
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.3))
                                            .frame(height: 150)
                                            .overlay(
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Image(systemName: "pencil.circle.fill")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(.white)
                                                            .padding(8)
                                                    }
                                                }
                                            )
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
                                
                                // Instagram
                                InputField(
                                    title: "Instagram (optionnel)",
                                    text: $viewModel.instagram,
                                    placeholder: "https://instagram.com/votrecompte",
                                    isFocused: focusedField == .instagram
                                )
                                .focused($focusedField, equals: .instagram)
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
                            .disabled(viewModel.isLoadingData)
                            .opacity(viewModel.isLoadingData ? 0.5 : 1.0)
                            
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
                                print("🏢 [GÉRER ÉTABLISSEMENT] =========================================")
                                print("🏢 [GÉRER ÉTABLISSEMENT] Bouton 'Enregistrer les modifications' cliqué")
                                print("🏢 [GÉRER ÉTABLISSEMENT] État avant appel:")
                                print("   - isValid: \(viewModel.isValid)")
                                print("   - hasChanges: \(viewModel.hasChanges)")
                                print("   - isLoading: \(viewModel.isLoading)")
                                print("   - isLoadingData: \(viewModel.isLoadingData)")
                                print("🏢 [GÉRER ÉTABLISSEMENT] =========================================")
                                
                                // Toujours appeler saveEstablishment, la validation se fait à l'intérieur
                                viewModel.saveEstablishment()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Enregistrer les modifications")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background((viewModel.isValid && viewModel.hasChanges && !viewModel.isLoading && !viewModel.isLoadingData) ? Color.appRed : Color.gray.opacity(0.5))
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading || viewModel.isLoadingData)
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
        .onAppear {
            // Charger les données au démarrage
            viewModel.loadEstablishmentData()
        }
        .onReceive(viewModel.$successMessage) { successMessage in
            // Fermer la vue après un délai si la sauvegarde réussit
            if successMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
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
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var address: String = ""
    @Published var city: String = ""
    @Published var postalCode: String = ""
    @Published var phone: String = ""
    @Published var email: String = ""
    @Published var website: String = ""
    @Published var instagram: String = ""
    @Published var openingHours: String = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var profession: String? = nil
    @Published var category: OfferCategory? = nil
    
    @Published var isLoading: Bool = false
    @Published var isLoadingData: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedImage: UIImage? = nil
    @Published var selectedImageItem: PhotosPickerItem? = nil
    @Published var establishmentImageUrl: String? = nil
    
    // Valeurs initiales pour détecter les modifications
    private var initialName: String = ""
    private var initialDescription: String = ""
    private var initialAddress: String = ""
    private var initialCity: String = ""
    private var initialPostalCode: String = ""
    private var initialPhone: String = ""
    private var initialEmail: String = ""
    private var initialWebsite: String = ""
    private var initialInstagram: String = ""
    private var initialOpeningHours: String = ""
    private var initialLatitude: Double? = nil
    private var initialLongitude: Double? = nil
    private var initialProfession: String? = nil
    private var initialCategory: OfferCategory? = nil
    private var initialImageUrl: String? = nil
    private var hasInitialImage: Bool = false
    
    private let profileAPIService: ProfileAPIService
    private let locationService: LocationService
    
    init(
        profileAPIService: ProfileAPIService? = nil,
        locationService: LocationService? = nil
    ) {
        // Créer le service dans un contexte MainActor
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        // Accéder à LocationService.shared dans un contexte MainActor
        self.locationService = locationService ?? LocationService.shared
        
        // Charger la localisation si disponible
        if let location = self.locationService.currentLocation {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
        
        // Observer les changements de selectedImageItem pour convertir en UIImage
        $selectedImageItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor [weak self] in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self?.selectedImage = image
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // Charger les données depuis l'API
    func loadEstablishmentData() {
        isLoadingData = true
        errorMessage = nil
        
        Task {
            do {
                let userMe = try await profileAPIService.getUserMe()
                
                // Remplir les champs avec les données de l'API
                name = userMe.establishmentName ?? ""
                description = userMe.establishmentDescription ?? ""
                address = userMe.address ?? ""
                city = userMe.city ?? ""
                postalCode = userMe.postalCode ?? ""
                phone = userMe.phoneNumber ?? ""
                email = userMe.email ?? ""
                website = userMe.website ?? ""
                instagram = userMe.instagram ?? ""
                openingHours = userMe.openingHours ?? ""
                latitude = userMe.latitude
                longitude = userMe.longitude
                profession = userMe.profession
                category = userMe.category
                
                // Construire l'URL complète de l'image d'établissement
                // Gère les URLs absolues (http/https) et les URLs relatives (/uploads/)
                establishmentImageUrl = ImageURLHelper.buildImageURL(from: userMe.establishmentImageUrl)
                
                // Sauvegarder les valeurs initiales pour détecter les modifications
                saveInitialValues()
                
                isLoadingData = false
            } catch {
                isLoadingData = false
                errorMessage = "Erreur lors du chargement des données"
                print("Erreur lors du chargement des données de l'établissement: \(error)")
            }
        }
    }
    
    // Sauvegarder les valeurs initiales
    private func saveInitialValues() {
        initialName = name
        initialDescription = description
        initialAddress = address
        initialCity = city
        initialPostalCode = postalCode
        initialPhone = phone
        initialEmail = email
        initialWebsite = website
        initialInstagram = instagram
        initialOpeningHours = openingHours
        initialLatitude = latitude
        initialLongitude = longitude
        initialProfession = profession
        initialCategory = category
        initialImageUrl = establishmentImageUrl
        hasInitialImage = (establishmentImageUrl != nil)
    }
    
    // Vérifier si des modifications ont été faites
    var hasChanges: Bool {
        // Vérifier les modifications de texte
        let textChanged = name.trimmingCharacters(in: .whitespaces) != initialName.trimmingCharacters(in: .whitespaces) ||
                         description.trimmingCharacters(in: .whitespaces) != initialDescription.trimmingCharacters(in: .whitespaces) ||
                         address.trimmingCharacters(in: .whitespaces) != initialAddress.trimmingCharacters(in: .whitespaces) ||
                         city.trimmingCharacters(in: .whitespaces) != initialCity.trimmingCharacters(in: .whitespaces) ||
                         postalCode.trimmingCharacters(in: .whitespaces) != initialPostalCode.trimmingCharacters(in: .whitespaces) ||
                         phone.trimmingCharacters(in: .whitespaces) != initialPhone.trimmingCharacters(in: .whitespaces) ||
                         email.trimmingCharacters(in: .whitespaces) != initialEmail.trimmingCharacters(in: .whitespaces) ||
                         website.trimmingCharacters(in: .whitespaces) != initialWebsite.trimmingCharacters(in: .whitespaces) ||
                         instagram.trimmingCharacters(in: .whitespaces) != initialInstagram.trimmingCharacters(in: .whitespaces) ||
                         openingHours.trimmingCharacters(in: .whitespaces) != initialOpeningHours.trimmingCharacters(in: .whitespaces)
        
        // Vérifier les modifications de localisation
        let locationChanged = latitude != initialLatitude || longitude != initialLongitude
        
        // Vérifier les modifications de profession/catégorie
        let professionChanged = profession != initialProfession || category != initialCategory
        
        // Vérifier si une nouvelle image a été sélectionnée
        let imageChanged = selectedImage != nil
        
        return textChanged || locationChanged || professionChanged || imageChanged
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
        print("═══════════════════════════════════════════════════════════")
        print("🏢 [GÉRER ÉTABLISSEMENT] saveEstablishment() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("🏢 [GÉRER ÉTABLISSEMENT] isValid: \(isValid)")
        print("🏢 [GÉRER ÉTABLISSEMENT] hasChanges: \(hasChanges)")
        print("🏢 [GÉRER ÉTABLISSEMENT] isLoading: \(isLoading)")
        print("🏢 [GÉRER ÉTABLISSEMENT] isLoadingData: \(isLoadingData)")
        
        guard isValid else {
            print("🏢 [GÉRER ÉTABLISSEMENT] ❌ Validation échouée - Champs manquants")
            errorMessage = "Veuillez remplir tous les champs obligatoires"
            return
        }
        
        guard hasChanges else {
            print("🏢 [GÉRER ÉTABLISSEMENT] ❌ Aucune modification détectée")
            errorMessage = "Aucune modification à enregistrer"
            return
        }
        
        print("🏢 [GÉRER ÉTABLISSEMENT] ✅ Validation OK, début de l'appel API")
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                print("🏢 [GÉRER ÉTABLISSEMENT] Création de la requête de mise à jour...")
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
                    instagram: instagram.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instagram.trimmingCharacters(in: .whitespaces),
                    openingHours: openingHours.trimmingCharacters(in: .whitespaces).isEmpty ? nil : openingHours.trimmingCharacters(in: .whitespaces),
                    profession: profession?.trimmingCharacters(in: .whitespaces),
                    category: category
                )
                
                // Convertir l'image en Data si elle existe
                var imageData: Data? = nil
                if let selectedImage = selectedImage {
                    imageData = selectedImage.jpegData(compressionQuality: 0.8)
                }
                
                // Appeler l'API avec ou sans image
                print("🏢 [GÉRER ÉTABLISSEMENT] Appel API...")
                print("🏢 [GÉRER ÉTABLISSEMENT] Image fournie: \(imageData != nil)")
                if imageData != nil {
                    print("🏢 [GÉRER ÉTABLISSEMENT] Appel: updateProfileWithImage()")
                    try await profileAPIService.updateProfileWithImage(updateRequest, imageData: imageData)
                } else {
                    print("🏢 [GÉRER ÉTABLISSEMENT] Appel: updateProfile()")
                    try await profileAPIService.updateProfile(updateRequest)
                }
                
                print("🏢 [GÉRER ÉTABLISSEMENT] ✅ Appel API réussi")
                isLoading = false
                successMessage = "Fiche établissement mise à jour avec succès"
                
                // Réinitialiser l'image sélectionnée après sauvegarde
                selectedImage = nil
                
                // Recharger les données depuis l'API pour s'assurer qu'on a les dernières valeurs
                loadEstablishmentData()
                
                // Notifier que les données ont été mises à jour
                NotificationCenter.default.post(name: NSNotification.Name("EstablishmentUpdated"), object: nil)
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                print("═══════════════════════════════════════════════════════════")
                print("🏢 [GÉRER ÉTABLISSEMENT] ❌ ERREUR lors de la mise à jour")
                print("═══════════════════════════════════════════════════════════")
                print("🏢 [GÉRER ÉTABLISSEMENT] Type d'erreur: \(type(of: error))")
                print("🏢 [GÉRER ÉTABLISSEMENT] Message: \(error.localizedDescription)")
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors de la mise à jour de la fiche établissement: \(error)")
            }
        }
        print("═══════════════════════════════════════════════════════════")
        print("🏢 [GÉRER ÉTABLISSEMENT] saveEstablishment() - Fin")
        print("═══════════════════════════════════════════════════════════")
    }
}

#Preview {
    NavigationStack {
        ManageEstablishmentView()
            .environmentObject(AppState())
    }
}

