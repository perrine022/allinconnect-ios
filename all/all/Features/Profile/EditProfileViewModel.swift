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
        
        // Charger les données depuis l'API pour préremplir
        Task {
            await loadUserDataFromAPI()
        }
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
            
            isLoading = false
        } catch {
            isLoading = false
            print("Erreur lors du chargement des données utilisateur: \(error)")
            // En cas d'erreur, on garde les valeurs de UserDefaults
        }
    }
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        isValidBirthDate()
    }
    
    private func isValidBirthDate() -> Bool {
        guard let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) else {
            return false
        }
        return day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900 && year <= Calendar.current.component(.year, from: Date())
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
                // Formater la date de naissance au format YYYY-MM-DD
                guard let birthDateString = formatBirthDate() else {
                    errorMessage = "Date de naissance invalide"
                    isLoading = false
                    return
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
                UserDefaults.standard.set(birthDateString, forKey: "user_birth_date")
                
                isLoading = false
                successMessage = "Profil mis à jour avec succès"
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Erreur lors de la mise à jour du profil: \(error)")
            }
        }
    }
}

