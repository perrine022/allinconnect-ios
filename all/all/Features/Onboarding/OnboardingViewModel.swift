//
//  OnboardingViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var postalCode: String = ""
    
    var isComplete: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        !postalCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        postalCode.count == 5 &&
        postalCode.allSatisfy { $0.isNumber }
    }
    
    var emailError: String? {
        if !email.isEmpty && !isValidEmail(email) {
            return "Format d'email invalide"
        }
        return nil
    }
    
    var postalCodeError: String? {
        if !postalCode.isEmpty {
            if postalCode.count != 5 {
                return "Le code postal doit contenir 5 chiffres"
            }
            if !postalCode.allSatisfy({ $0.isNumber }) {
                return "Le code postal doit contenir uniquement des chiffres"
            }
        }
        return nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func saveUserInfo() {
        // Sauvegarder dans UserDefaults
        UserDefaults.standard.set(firstName, forKey: "user_firstName")
        UserDefaults.standard.set(lastName, forKey: "user_lastName")
        UserDefaults.standard.set(email, forKey: "user_email")
        UserDefaults.standard.set(postalCode, forKey: "user_postalCode")
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }
    
    static func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
    
    static func loadUserInfo() -> (firstName: String, lastName: String, email: String, postalCode: String)? {
        guard hasCompletedOnboarding() else { return nil }
        
        return (
            firstName: UserDefaults.standard.string(forKey: "user_firstName") ?? "",
            lastName: UserDefaults.standard.string(forKey: "user_lastName") ?? "",
            email: UserDefaults.standard.string(forKey: "user_email") ?? "",
            postalCode: UserDefaults.standard.string(forKey: "user_postalCode") ?? ""
        )
    }
}

