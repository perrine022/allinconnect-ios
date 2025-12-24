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
            // Créer un compte mocké avec accès aux deux espaces (Client et Pro)
            UserDefaults.standard.set(true, forKey: "is_logged_in")
            UserDefaults.standard.set(self.email.isEmpty ? "demo@allinconnect.fr" : self.email, forKey: "user_email")
            
            // Compte PRO pour avoir accès aux deux espaces
            UserDefaults.standard.set("PRO", forKey: "user_type")
            
            // Données mockées
            UserDefaults.standard.set("Marie", forKey: "user_first_name")
            UserDefaults.standard.set("Dupont", forKey: "user_last_name")
            UserDefaults.standard.set("69001", forKey: "user_postal_code")
            
            // Abonnement actif pour voir les deux espaces
            UserDefaults.standard.set(true, forKey: "has_active_subscription")
            UserDefaults.standard.set("PRO", forKey: "subscription_type")
            let nextPaymentDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            UserDefaults.standard.set(formatter.string(from: nextPaymentDate), forKey: "subscription_next_payment_date")
            
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

