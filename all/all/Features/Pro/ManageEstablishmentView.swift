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
        case name, description, address, city, postalCode, phone, email, website, instagram, subCategory
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                            
                            // Message si la fiche est vide
                            if !viewModel.isLoadingData && viewModel.isEstablishmentEmpty {
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                        
                                        Text("Votre fiche établissement est vide")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("Remplissez les informations ci-dessous pour que votre établissement soit visible par les utilisateurs.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(16)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            }
                            
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
                                        // PRIORITÉ 1: Toujours afficher l'image croppée si elle existe
                                        // C'est cette image croppée qui sera envoyée au backend
                                        if let selectedImage = viewModel.selectedImage {
                                            Image(uiImage: selectedImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 150)
                                                .clipped()
                                                .cornerRadius(12)
                                        } else if let imageUrl = viewModel.establishmentImageUrl, let url = URL(string: imageUrl) {
                                            // PRIORITÉ 2: Afficher l'image existante depuis le serveur seulement si pas d'image croppée
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
                                            .cornerRadius(12)
                                        } else {
                                            // PRIORITÉ 3: Afficher le placeholder si aucune image
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
                                    
                                    ZStack(alignment: .topLeading) {
                                        // Background blanc fixe pour éviter le carré noir
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white)
                                            .frame(height: 80)
                                        
                                        TextEditor(text: $viewModel.description)
                                            .frame(height: 80)
                                            .padding(8)
                                            .background(Color.clear)
                                            .scrollContentBackground(.hidden)
                                            .foregroundColor(.black)
                                            .font(.system(size: 15))
                                            .accentColor(.appGold)
                                            .focused($focusedField, equals: .description)
                                    }
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
                                    .keyboardType(.numberPad)
                                    .frame(width: 120)
                                    .onChange(of: viewModel.postalCode) { oldValue, newValue in
                                        // Limiter à 5 chiffres maximum
                                        if newValue.count > 5 {
                                            viewModel.postalCode = String(newValue.prefix(5))
                                        }
                                        // Ne garder que les chiffres
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered != newValue {
                                            viewModel.postalCode = filtered
                                        }
                                    }
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
                                .onChange(of: viewModel.phone) { oldValue, newValue in
                                    // Ne garder que les chiffres
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        viewModel.phone = filtered
                                    }
                                }
                                
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
                                
                                // Catégorie (Activité)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Activité")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    if viewModel.isLoadingCategories || viewModel.categoriesTree.isEmpty {
                                        HStack {
                                            Text("Chargement...")
                                                .foregroundColor(.gray.opacity(0.6))
                                            Spacer()
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        }
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    } else {
                                        Picker("Activité", selection: Binding(
                                            get: { viewModel.selectedCategoryId ?? "" },
                                            set: { newId in
                                                if let categoryResponse = viewModel.categoriesTree.first(where: { $0.id == newId }),
                                                   let categoryEnum = OfferCategory(rawValue: categoryResponse.id) {
                                                    viewModel.category = categoryEnum
                                                    viewModel.selectedCategoryId = categoryResponse.id
                                                    // Ne plus utiliser availableSubCategories - sous-catégorie en saisie libre
                                                }
                                            }
                                        )) {
                                            Text("Sélectionner une activité")
                                                .tag("")
                                            ForEach(viewModel.categoriesTree) { categoryResponse in
                                                Text(categoryResponse.name)
                                                    .tag(categoryResponse.id)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Sous-catégorie (saisie libre)
                                InputField(
                                    title: "Sous-catégorie",
                                    text: Binding(
                                        get: { viewModel.subCategory ?? "" },
                                        set: { viewModel.subCategory = $0.isEmpty ? nil : $0 }
                                    ),
                                    placeholder: "Ex: Coiffure, Restaurant, etc.",
                                    isFocused: focusedField == .subCategory
                                )
                                .focused($focusedField, equals: .subCategory)
                                .padding(.horizontal, 20)
                                
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
                                
                                // Checkbox Club 10
                                Button(action: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        viewModel.isClub10.toggle()
                                        print("🏢 [GÉRER ÉTABLISSEMENT] Checkbox Club 10 togglée - Nouvelle valeur: \(viewModel.isClub10)")
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(viewModel.isClub10 ? Color.green : Color.clear)
                                                .frame(width: 16, height: 16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .stroke(Color.green, lineWidth: 1.5)
                                                )
                                            
                                            if viewModel.isClub10 {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                        }
                                        
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.appGold)
                                            .font(.system(size: 13))
                                        
                                        Text("Club 10")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.green)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(red: 0.85, green: 0.95, blue: 0.85)) // Vert clair/pastel
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
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
            // Charger les données (qui charge aussi les catégories en parallèle)
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
        .sheet(isPresented: $viewModel.showImageCrop) {
            if let imageToCrop = viewModel.imageToCrop {
                ImageCropSheet(
                    isPresented: $viewModel.showImageCrop,
                    image: imageToCrop,
                    cropSize: CGSize(width: 400, height: 400),
                    croppedImage: $viewModel.selectedImage
                )
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
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var profession: String? = nil
    @Published var category: OfferCategory? = nil
    @Published var subCategory: String? = nil // Sous-catégorie sélectionnée
    @Published var isClub10: Bool = false // Indique si l'établissement fait partie du Club 10
    
    // Catégories et sous-catégories depuis l'API
    @Published var categoriesTree: [CategoryResponse] = []
    @Published var isLoadingCategories: Bool = false
    @Published var selectedCategoryId: String? = nil // ID technique de la catégorie sélectionnée (ex: "BEAUTE_ESTHETIQUE")
    @Published var availableSubCategories: [String] = [] // Sous-catégories disponibles selon la catégorie sélectionnée
    
    @Published var isLoading: Bool = false
    @Published var isLoadingData: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedImage: UIImage? = nil // Image CROPPÉE - c'est cette image qui est affichée et envoyée au backend
    @Published var selectedImageItem: PhotosPickerItem? = nil // Item sélectionné depuis PhotosPicker
    @Published var establishmentImageUrl: String? = nil // URL de l'image existante depuis le serveur
    @Published var showImageCrop: Bool = false // Afficher le sheet de crop
    @Published var imageToCrop: UIImage? = nil // Image originale avant crop (utilisée pour le crop sheet)
    
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
    private var initialLatitude: Double? = nil
    private var initialLongitude: Double? = nil
    private var initialProfession: String? = nil
    private var initialCategory: OfferCategory? = nil
    private var initialSubCategory: String? = nil
    private var initialIsClub10: Bool = false
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
                        self?.imageToCrop = image
                        self?.showImageCrop = true
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
                // Charger les données utilisateur et les catégories en parallèle
                async let userMeTask = profileAPIService.getUserMe()
                async let categoriesTask = profileAPIService.getProfessionalsCategoriesTree()
                
                let (userMe, categories) = try await (userMeTask, categoriesTask)
                
                // Mettre à jour l'arbre des catégories
                categoriesTree = categories
                
                // Remplir les champs avec les données de l'API
                name = userMe.establishmentName ?? ""
                description = userMe.establishmentDescription ?? ""
                address = userMe.address ?? ""
                
                // Gérer le code postal
                let backendPostalCode = userMe.postalCode ?? ""
                postalCode = backendPostalCode
                
                // Pour la ville : ne la remplir QUE si elle existe vraiment et ne ressemble pas à un code postal
                // Lors de l'inscription, on ne collecte que le code postal, pas la ville
                let backendCity = userMe.city ?? ""
                let cityIsNumeric = backendCity.allSatisfy { $0.isNumber } && backendCity.count == 5
                
                if !backendCity.isEmpty && !cityIsNumeric {
                    // La ville existe et ne ressemble pas à un code postal : on l'utilise
                    city = backendCity
                } else {
                    // La ville est vide ou ressemble à un code postal : on laisse le champ vide
                    city = ""
                }
                
                // Log pour debug
                print("🏢 [GÉRER ÉTABLISSEMENT] Données finales:")
                print("   - city (backend): \(backendCity)")
                print("   - city (final): \(city)")
                print("   - postalCode: \(postalCode)")
                phone = userMe.phoneNumber ?? ""
                email = userMe.email ?? ""
                website = userMe.website ?? ""
                instagram = userMe.instagram ?? ""
                latitude = userMe.latitude
                longitude = userMe.longitude
                profession = userMe.profession
                category = userMe.category
                subCategory = userMe.subCategory
                
                // Charger isClub10 depuis l'API
                let backendIsClub10 = userMe.isClub10 ?? false
                isClub10 = backendIsClub10
                print("🏢 [GÉRER ÉTABLISSEMENT] isClub10 chargé depuis l'API: \(backendIsClub10) (raw: \(userMe.isClub10?.description ?? "nil"))")
                
                // Si une catégorie est chargée, mettre à jour selectedCategoryId
                // Note: Les sous-catégories sont maintenant en saisie libre, on ne les charge plus depuis l'API
                if let category = category {
                    if let categoryResponse = categoriesTree.first(where: { $0.id == category.rawValue }) {
                        selectedCategoryId = categoryResponse.id
                    } else {
                        selectedCategoryId = category.rawValue
                    }
                }
                
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
        initialLatitude = latitude
        initialLongitude = longitude
        initialProfession = profession
        initialCategory = category
        initialSubCategory = subCategory
        initialIsClub10 = isClub10
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
                         instagram.trimmingCharacters(in: .whitespaces) != initialInstagram.trimmingCharacters(in: .whitespaces)
        
        // Vérifier les modifications de localisation
        let locationChanged = latitude != initialLatitude || longitude != initialLongitude
        
        // Vérifier les modifications de catégorie/sous-catégorie/Club 10
        let categoryChanged = category != initialCategory || subCategory != initialSubCategory || isClub10 != initialIsClub10
        
        // Vérifier si une nouvelle image a été sélectionnée
        let imageChanged = selectedImage != nil
        
        return textChanged || locationChanged || categoryChanged || imageChanged
    }
    
    var isEstablishmentEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty ||
        description.trimmingCharacters(in: .whitespaces).isEmpty ||
        address.trimmingCharacters(in: .whitespaces).isEmpty ||
        city.trimmingCharacters(in: .whitespaces).isEmpty ||
        postalCode.trimmingCharacters(in: .whitespaces).isEmpty ||
        phone.trimmingCharacters(in: .whitespaces).isEmpty ||
        email.trimmingCharacters(in: .whitespaces).isEmpty
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
                
                // Convertir la catégorie sélectionnée en ID technique pour l'API
                // Le backend attend l'ID technique (ex: "BEAUTE_ESTHETIQUE") dans le champ category
                var categoryToSend: OfferCategory? = nil
                if let selectedCategoryId = selectedCategoryId,
                   let categoryEnum = OfferCategory(rawValue: selectedCategoryId) {
                    categoryToSend = categoryEnum
                    print("🏢 [GÉRER ÉTABLISSEMENT] Catégorie sélectionnée: \(selectedCategoryId)")
                } else if let category = category {
                    // Fallback : utiliser la catégorie existante si pas de sélection explicite
                    categoryToSend = category
                    print("🏢 [GÉRER ÉTABLISSEMENT] Utilisation de la catégorie existante: \(category.rawValue)")
                }
                
                // Créer la requête de mise à jour (champs établissement uniquement)
                print("🏢 [GÉRER ÉTABLISSEMENT] ========================================")
                print("🏢 [GÉRER ÉTABLISSEMENT] Valeur isClub10 dans ViewModel: \(isClub10)")
                print("🏢 [GÉRER ÉTABLISSEMENT] Type: \(type(of: isClub10))")
                
                // IMPORTANT: Toujours inclure isClub10 dans la requête, même si false
                // Le backend a besoin de cette valeur pour mettre à jour le statut
                let updateRequest = UpdateProfileRequest(
                    firstName: nil, // Pas de modification du prénom ici
                    lastName: nil, // Pas de modification du nom ici
                    email: nil, // Pas de modification de l'email ici
                    address: address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                    postalCode: postalCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : postalCode.trimmingCharacters(in: .whitespaces),
                    birthDate: nil, // Pas de modification de la date de naissance ici
                    latitude: latitude,
                    longitude: longitude,
                    establishmentName: name.trimmingCharacters(in: .whitespaces),
                    establishmentDescription: description.trimmingCharacters(in: .whitespaces),
                    phoneNumber: phone.trimmingCharacters(in: .whitespaces),
                    website: website.trimmingCharacters(in: .whitespaces).isEmpty ? nil : website.trimmingCharacters(in: .whitespaces),
                    instagram: instagram.trimmingCharacters(in: .whitespaces).isEmpty ? nil : instagram.trimmingCharacters(in: .whitespaces),
                    openingHours: nil,
                    profession: subCategory?.trimmingCharacters(in: .whitespaces), // Utiliser subCategory comme profession pour compatibilité
                    category: categoryToSend, // ID technique de la catégorie (ex: "BEAUTE_ESTHETIQUE")
                    subCategory: subCategory?.trimmingCharacters(in: .whitespaces), // Texte de la sous-catégorie (ex: "Coiffure")
                    isClub10: isClub10 // IMPORTANT: Toujours envoyer la valeur (true ou false)
                )
                print("🏢 [GÉRER ÉTABLISSEMENT] Valeur isClub10 dans updateRequest: \(updateRequest.isClub10?.description ?? "nil")")
                print("🏢 [GÉRER ÉTABLISSEMENT] ========================================")
                
                // IMPORTANT: Convertir UNIQUEMENT l'image croppée en Data pour l'envoi au backend
                // selectedImage contient toujours l'image croppée (pas l'image originale)
                var imageData: Data? = nil
                if let selectedImage = selectedImage {
                    // Utiliser l'image croppée (selectedImage) pour l'envoi au backend
                    // Compression à 0.8 pour un bon équilibre qualité/taille
                    imageData = selectedImage.jpegData(compressionQuality: 0.8)
                    print("🏢 [GÉRER ÉTABLISSEMENT] ✅ Image croppée convertie en Data pour envoi au backend")
                    print("🏢 [GÉRER ÉTABLISSEMENT] Taille de l'image: \(imageData?.count ?? 0) bytes")
                }
                
                // Appeler l'API avec ou sans image
                print("🏢 [GÉRER ÉTABLISSEMENT] Appel API...")
                print("🏢 [GÉRER ÉTABLISSEMENT] Image croppée fournie: \(imageData != nil)")
                if let imageData = imageData {
                    print("🏢 [GÉRER ÉTABLISSEMENT] Appel: updateProfileWithImage() avec image croppée")
                    try await profileAPIService.updateProfileWithImage(updateRequest, imageData: imageData)
                } else {
                    print("🏢 [GÉRER ÉTABLISSEMENT] Appel: updateProfile() sans image")
                    try await profileAPIService.updateProfile(updateRequest)
                }
                
                print("🏢 [GÉRER ÉTABLISSEMENT] ✅ Appel API réussi")
                isLoading = false
                successMessage = "Fiche établissement mise à jour avec succès"
                
                // Réinitialiser l'image sélectionnée après sauvegarde
                // L'image croppée a été envoyée, on peut la réinitialiser
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

