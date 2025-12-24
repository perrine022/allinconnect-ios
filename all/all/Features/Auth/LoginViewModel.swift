//
//  LoginViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(email) &&
        !password.isEmpty &&
        password.count >= 6
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func login() {
        // Pour l'instant, on simule juste la connexion
        // Plus tard, on appellera l'API
        isLoading = true
        errorMessage = nil
        
        // Simuler un délai de connexion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Sauvegarder l'état de connexion
            UserDefaults.standard.set(true, forKey: "is_logged_in")
            UserDefaults.standard.set(self.email, forKey: "user_email")
            
            // Pour tester, on peut définir le type d'utilisateur
            // Par défaut CLIENT, mais on peut le changer pour tester PRO
            // UserDefaults.standard.set("PRO", forKey: "user_type") // Décommenter pour tester PRO
            
            self.isLoading = false
            
            // Notifier que la connexion est réussie
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
        }
    }
    
    static func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: "is_logged_in")
    }
    
    static func logout() {
        // Nettoyer toutes les données de session
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_type")
        
        // Notifier la déconnexion
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }
}

