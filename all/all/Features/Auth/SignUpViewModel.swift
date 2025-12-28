//
//  SignUpViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var postalCode: String = ""
    @Published var birthDay: String = ""
    @Published var birthMonth: String = ""
    @Published var birthYear: String = ""
    @Published var referralCode: String = ""
    @Published var userType: UserType = .client
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Messages d'erreur pour la validation en temps réel
    @Published var birthDayError: String? = nil
    @Published var birthMonthError: String? = nil
    @Published var birthYearError: String? = nil
    @Published var birthDateError: String? = nil
    @Published var postalCodeError: String? = nil
    
    var isValidEmail: Bool {
        isValidEmail(email)
    }
    
    private let authAPIService: AuthAPIService
    
    init(authAPIService: AuthAPIService? = nil) {
        // Créer le service dans un contexte MainActor
        if let authAPIService = authAPIService {
            self.authAPIService = authAPIService
        } else {
            self.authAPIService = AuthAPIService()
        }
    }
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        postalCode.count == 5 &&
        isValidBirthDate()
    }
    
    func validatePostalCode() {
        postalCodeError = nil
        
        if !postalCode.isEmpty {
            if postalCode.count != 5 {
                postalCodeError = "Le code postal doit contenir exactement 5 chiffres"
            }
        }
    }
    
    func validateBirthDate() {
        // Réinitialiser les erreurs
        birthDayError = nil
        birthMonthError = nil
        birthYearError = nil
        birthDateError = nil
        
        // Valider le jour
        if !birthDay.isEmpty {
            if let day = Int(birthDay) {
                if day < 1 || day > 31 {
                    birthDayError = "Le jour doit être entre 1 et 31"
                }
            } else {
                birthDayError = "Le jour doit être un nombre"
            }
        }
        
        // Valider le mois
        if !birthMonth.isEmpty {
            if let month = Int(birthMonth) {
                if month < 1 || month > 12 {
                    birthMonthError = "Le mois doit être entre 1 et 12"
                }
            } else {
                birthMonthError = "Le mois doit être un nombre"
            }
        }
        
        // Valider l'année
        if !birthYear.isEmpty {
            if let year = Int(birthYear) {
                let currentYear = Calendar.current.component(.year, from: Date())
                if year < 1900 || year > currentYear {
                    birthYearError = "L'année doit être entre 1900 et \(currentYear)"
                }
            } else {
                birthYearError = "L'année doit être un nombre"
            }
        }
        
        // Valider la date complète si tous les champs sont remplis
        if !birthDay.isEmpty && !birthMonth.isEmpty && !birthYear.isEmpty {
            if birthDayError == nil && birthMonthError == nil && birthYearError == nil {
                if let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) {
                    var components = DateComponents()
                    components.year = year
                    components.month = month
                    components.day = day
                    
                    if let date = Calendar.current.date(from: components) {
                        // Vérifier que la date correspond bien aux valeurs entrées
                        let calendar = Calendar.current
                        if calendar.component(.day, from: date) != day ||
                           calendar.component(.month, from: date) != month ||
                           calendar.component(.year, from: date) != year {
                            birthDateError = "Cette date n'existe pas (ex: pas de 31 février)"
                        }
                    } else {
                        birthDateError = "Cette date n'existe pas"
                    }
                }
            }
        }
    }
    
    private func isValidBirthDate() -> Bool {
        guard let day = Int(birthDay), let month = Int(birthMonth), let year = Int(birthYear) else {
            return false
        }
        guard day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1900 && year <= Calendar.current.component(.year, from: Date()) else {
            return false
        }
        // Vérifier que la date existe
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else {
            return false
        }
        // Vérifier que la date correspond bien aux valeurs entrées
        let calendar = Calendar.current
        return calendar.component(.day, from: date) == day &&
               calendar.component(.month, from: date) == month &&
               calendar.component(.year, from: date) == year
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
    
    func signUp(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard isValid else {
            errorMessage = "Veuillez remplir tous les champs correctement"
            isLoading = false
            completion(false)
            return
        }
        
        Task {
            do {
                // Convertir le code postal en ville (on peut extraire la ville du code postal ou utiliser le code postal comme ville)
                let city = postalCode // Pour l'instant, on utilise le code postal comme ville
                
                // Formater la date de naissance au format YYYY-MM-DD
                guard let birthDateString = formatBirthDate() else {
                    errorMessage = "Date de naissance invalide"
                    isLoading = false
                    completion(false)
                    return
                }
                
                // Créer la requête d'inscription
                let registrationRequest = RegistrationRequest(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password,
                    address: nil, // Peut être ajouté plus tard
                    city: city,
                    birthDate: birthDateString,
                    userType: userType == .pro ? .professional : .client,
                    subscriptionType: .free, // Par défaut FREE
                    profession: userType == .pro ? nil : nil, // Peut être ajouté plus tard
                    category: nil, // Peut être sélectionné plus tard pour les PRO
                    referralCode: referralCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : referralCode.trimmingCharacters(in: .whitespaces)
                )
                
                // Appeler l'API
                let authResponse = try await authAPIService.register(registrationRequest)
                
                // Sauvegarder le token
                AuthTokenManager.shared.saveToken(authResponse.token)
                
                // Sauvegarder les données utilisateur localement
                UserDefaults.standard.set(true, forKey: "is_logged_in")
                UserDefaults.standard.set(email.trimmingCharacters(in: .whitespaces).lowercased(), forKey: "user_email")
                UserDefaults.standard.set(firstName.trimmingCharacters(in: .whitespaces), forKey: "user_first_name")
                UserDefaults.standard.set(lastName.trimmingCharacters(in: .whitespaces), forKey: "user_last_name")
                UserDefaults.standard.set(postalCode, forKey: "user_postal_code")
                UserDefaults.standard.set(userType == .pro ? "PRO" : "CLIENT", forKey: "user_type")
                
                isLoading = false
                
                // Notifier que l'inscription est réussie
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                
                completion(true)
            } catch {
                isLoading = false
                
                // Gérer les erreurs spécifiques
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let statusCode, let message):
                        if statusCode == 400 {
                            errorMessage = message ?? "Les informations fournies sont invalides"
                        } else if statusCode == 409 {
                            errorMessage = "Cet email est déjà utilisé"
                        } else {
                            errorMessage = message ?? "Erreur lors de l'inscription"
                        }
                    case .networkError(let underlyingError):
                        // Vérifier si c'est une erreur de connexion au serveur
                        let nsError = underlyingError as NSError
                        if nsError.domain == NSURLErrorDomain && (nsError.code == -1004 || nsError.code == NSURLErrorCannotConnectToHost) {
                            errorMessage = "Impossible de se connecter au serveur. Vérifiez votre connexion internet."
                        } else {
                            errorMessage = "Erreur de connexion. Vérifiez votre connexion internet."
                        }
                    default:
                        errorMessage = apiError.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                print("Erreur lors de l'inscription: \(error)")
                completion(false)
            }
        }
    }
}

