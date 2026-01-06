//
//  EditProfileViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import CoreLocation

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var address: String = ""
    @Published var city: String = ""
    @Published var birthDay: String = ""
    @Published var birthMonth: String = ""
    @Published var birthYear: String = ""
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasChanges: Bool = false
    @Published var birthDateError: String? = nil
    
    // Valeurs initiales pour détecter les changements
    private var initialFirstName: String = ""
    private var initialLastName: String = ""
    private var initialEmail: String = ""
    private var initialAddress: String = ""
    private var initialCity: String = ""
    private var initialBirthDay: String = ""
    private var initialBirthMonth: String = ""
    private var initialBirthYear: String = ""
    
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
        
        // Charger les données utilisateur depuis l'API
        loadUserData()
        
        // Charger la localisation si disponible
        if let location = self.locationService.currentLocation {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }
    
    func loadUserData() {
        // Charger d'abord depuis UserDefaults comme fallback
        firstName = UserDefaults.standard.string(forKey: "user_first_name") ?? ""
        lastName = UserDefaults.standard.string(forKey: "user_last_name") ?? ""
        email = UserDefaults.standard.string(forKey: "user_email") ?? ""
        city = UserDefaults.standard.string(forKey: "user_postal_code") ?? ""
        address = "" // Pas stocké actuellement
        
        // Charger la date de naissance si disponible
        if let birthDateString = UserDefaults.standard.string(forKey: "user_birth_date") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: birthDateString) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day, .month, .year], from: date)
                birthDay = String(components.day ?? 1)
                birthMonth = String(components.month ?? 1)
                birthYear = String(components.year ?? 2000)
            }
        }
        
        // Sauvegarder les valeurs initiales
        saveInitialValues()
        
        // Charger les données depuis l'API pour préremplir
        Task {
            await loadUserDataFromAPI()
        }
    }
    
    private func saveInitialValues() {
        initialFirstName = firstName
        initialLastName = lastName
        initialEmail = email
        initialAddress = address
        initialCity = city
        initialBirthDay = birthDay
        initialBirthMonth = birthMonth
        initialBirthYear = birthYear
    }
    
    func checkForChanges() {
        hasChanges = firstName != initialFirstName ||
                     lastName != initialLastName ||
                     email != initialEmail ||
                     address != initialAddress ||
                     city != initialCity ||
                     birthDay != initialBirthDay ||
                     birthMonth != initialBirthMonth ||
                     birthYear != initialBirthYear
    }
    
    private func loadUserDataFromAPI() async {
        isLoading = true
        
        do {
            // Charger les données light depuis l'API
            let userLight = try await profileAPIService.getUserLight()
            
            // Préremplir les champs disponibles
            firstName = userLight.firstName
            lastName = userLight.lastName
            
            // Les autres champs (email, address, city, birthDate) ne sont pas dans /users/me/light
            // On garde les valeurs de UserDefaults si elles existent
            
            // Sauvegarder les nouvelles valeurs initiales après chargement API
            saveInitialValues()
            
            isLoading = false
        } catch {
            isLoading = false
            print("Erreur lors du chargement des données utilisateur: \(error)")
            // En cas d'erreur, on garde les valeurs de UserDefaults
        }
    }
    
    var isValid: Bool {
        // Le bouton est valide si :
        // 1. Il y a des changements
        // 2. Les champs obligatoires sont remplis et valides
        guard hasChanges else {
            return false
        }
        
        // Vérifier les champs obligatoires
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        guard !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty && isValidEmail(email) else {
            return false
        }
        
        // La date de naissance est optionnelle mais si remplie, doit être valide
        if !birthDay.isEmpty || !birthMonth.isEmpty || !birthYear.isEmpty {
            // Ne pas modifier birthDateError ici pour éviter les modifications pendant le rendu
            // La validation de l'erreur sera faite de manière asynchrone
            return isValidBirthDateWithoutError()
        }
        
        return true
    }
    
    // Validation sans modification de birthDateError (pour isValid)
    private func isValidBirthDateWithoutError() -> Bool {
        // Si tous les champs sont vides, c'est valide (optionnel)
        if birthDay.isEmpty && birthMonth.isEmpty && birthYear.isEmpty {
            return true
        }
        
        // Si un champ est rempli, tous doivent l'être
        guard !birthDay.isEmpty, !birthMonth.isEmpty, !birthYear.isEmpty else {
            return false
        }
        
        guard let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) else {
            return false
        }
        
        // Valider le jour (1-31)
        if day < 1 || day > 31 {
            return false
        }
        
        // Valider le mois (1-12)
        if month < 1 || month > 12 {
            return false
        }
        
        // Valider l'année (1900 à année actuelle)
        let currentYear = Calendar.current.component(.year, from: Date())
        if year < 1900 || year > currentYear {
            return false
        }
        
        // Valider que la date existe (ex: pas de 31 février)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard Calendar.current.date(from: components) != nil else {
            return false
        }
        
        return true
    }
    
    // Validation avec mise à jour de birthDateError (appelée de manière asynchrone)
    func validateBirthDate() {
        Task { @MainActor in
            // Si tous les champs sont vides, c'est valide (optionnel)
            if birthDay.isEmpty && birthMonth.isEmpty && birthYear.isEmpty {
                birthDateError = nil
                return
            }
            
            // Si un champ est rempli, tous doivent l'être
            guard !birthDay.isEmpty, !birthMonth.isEmpty, !birthYear.isEmpty else {
                birthDateError = "Tous les champs de date doivent être remplis"
                return
            }
            
            guard let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) else {
                birthDateError = "La date doit contenir uniquement des chiffres"
                return
            }
            
            // Valider le jour (1-31)
            if day < 1 || day > 31 {
                birthDateError = "Le jour doit être entre 1 et 31"
                return
            }
            
            // Valider le mois (1-12)
            if month < 1 || month > 12 {
                birthDateError = "Le mois doit être entre 1 et 12"
                return
            }
            
            // Valider l'année (1900 à année actuelle)
            let currentYear = Calendar.current.component(.year, from: Date())
            if year < 1900 || year > currentYear {
                birthDateError = "L'année doit être entre 1900 et \(currentYear)"
                return
            }
            
            // Valider que la date existe (ex: pas de 31 février)
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            guard Calendar.current.date(from: components) != nil else {
                birthDateError = "Cette date n'existe pas"
                return
            }
            
            birthDateError = nil
        }
    }
    
    private func formatBirthDate() -> String? {
        guard let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) else {
            return nil
        }
        guard day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900 && year <= Calendar.current.component(.year, from: Date()) else {
            return nil
        }
        // Valider que la date existe (ex: pas de 31 février)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func saveProfile() {
        guard isValid else {
            errorMessage = "Veuillez remplir tous les champs obligatoires correctement"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // Formater la date de naissance au format YYYY-MM-DD (optionnelle)
                let birthDateString: String?
                if !birthDay.isEmpty || !birthMonth.isEmpty || !birthYear.isEmpty {
                    guard let formatted = formatBirthDate() else {
                        errorMessage = "Date de naissance invalide"
                        isLoading = false
                        return
                    }
                    birthDateString = formatted
                } else {
                    birthDateString = nil
                }
                
                // Créer la requête de mise à jour
                let updateRequest = UpdateProfileRequest(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                    birthDate: birthDateString,
                    latitude: latitude,
                    longitude: longitude,
                    establishmentName: nil,
                    establishmentDescription: nil,
                    phoneNumber: nil,
                    website: nil,
                    instagram: nil,
                    openingHours: nil,
                    profession: nil,
                    category: nil
                )
                
                // Appeler l'API
                try await profileAPIService.updateProfile(updateRequest)
                
                // Sauvegarder dans UserDefaults
                UserDefaults.standard.set(firstName.trimmingCharacters(in: .whitespaces), forKey: "user_first_name")
                UserDefaults.standard.set(lastName.trimmingCharacters(in: .whitespaces), forKey: "user_last_name")
                UserDefaults.standard.set(email.trimmingCharacters(in: .whitespaces).lowercased(), forKey: "user_email")
                UserDefaults.standard.set(city.trimmingCharacters(in: .whitespaces), forKey: "user_postal_code")
                if let birthDateString = birthDateString {
                    UserDefaults.standard.set(birthDateString, forKey: "user_birth_date")
                }
                
                // Mettre à jour les valeurs initiales après sauvegarde réussie
                saveInitialValues()
                hasChanges = false
                
                isLoading = false
                successMessage = "Profil mis à jour avec succès"
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

