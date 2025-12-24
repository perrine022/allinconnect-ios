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
    @Published var userType: UserType = .client
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        !postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        postalCode.count == 5
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
        
        // Simuler un délai d'inscription
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Sauvegarder les données utilisateur
            UserDefaults.standard.set(true, forKey: "is_logged_in")
            UserDefaults.standard.set(self.email, forKey: "user_email")
            UserDefaults.standard.set(self.firstName, forKey: "user_first_name")
            UserDefaults.standard.set(self.lastName, forKey: "user_last_name")
            UserDefaults.standard.set(self.postalCode, forKey: "user_postal_code")
            UserDefaults.standard.set(self.userType == .pro ? "PRO" : "CLIENT", forKey: "user_type")
            
            self.isLoading = false
            
            // Notifier que l'inscription est réussie
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
            
            completion(true)
        }
    }
}

