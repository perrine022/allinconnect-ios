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
        isLoading = true
        errorMessage = nil
        
        // Validation
        guard isValid else {
            errorMessage = "Veuillez remplir tous les champs correctement"
            isLoading = false
            return
        }
        
        Task {
            do {
                // Appeler l'API d'authentification
                let authResponse = try await authAPIService.authenticate(
                    email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                    password: password
                )
                
                // Sauvegarder le token
                AuthTokenManager.shared.saveToken(authResponse.token)
                
                // Marquer l'utilisateur comme connecté
                UserDefaults.standard.set(true, forKey: "is_logged_in")
                UserDefaults.standard.set(email.trimmingCharacters(in: .whitespaces).lowercased(), forKey: "user_email")
                
                // Note: Les autres informations utilisateur (nom, prénom, etc.) devraient être récupérées
                // depuis un endpoint de profil utilisateur après l'authentification
                // Pour l'instant, on garde les valeurs par défaut si elles existent déjà
                
                isLoading = false
                
                // Notifier que la connexion est réussie
                NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
            } catch {
                isLoading = false
                
                // Gérer les erreurs spécifiques
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let statusCode, let message):
                        if statusCode == 401 || statusCode == 403 {
                            errorMessage = "Les informations de connexion sont incorrectes"
                        } else if statusCode == 404 {
                            errorMessage = "Compte non trouvé"
                        } else {
                            errorMessage = message ?? "Un problème s'est produit lors de la connexion"
                        }
                    case .networkError(let underlyingError):
                        // Vérifier si c'est une erreur de connexion au serveur
                        let nsError = underlyingError as NSError
                        if nsError.domain == NSURLErrorDomain && (nsError.code == -1004 || nsError.code == NSURLErrorCannotConnectToHost) {
                            errorMessage = "Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://localhost:8000"
                        } else {
                            errorMessage = "Problème de connexion. Vérifiez votre connexion internet."
                        }
                    case .unauthorized:
                        errorMessage = "Les informations de connexion sont incorrectes"
                    case .invalidResponse:
                        errorMessage = "Réponse invalide du serveur"
                    case .decodingError:
                        errorMessage = "Problème lors du traitement de la réponse"
                    case .invalidURL:
                        errorMessage = "URL invalide"
                    case .notFound:
                        errorMessage = "Compte non trouvé"
                    }
                } else {
                    // Pour les autres erreurs, afficher un message générique
                    errorMessage = "Les informations de connexion sont incorrectes"
                }
                
                print("Erreur lors de la connexion: \(error)")
            }
        }
    }
    
    static func isLoggedIn() -> Bool {
        return AuthTokenManager.shared.hasToken() && UserDefaults.standard.bool(forKey: "is_logged_in")
    }
    
    static func logout() {
        // Supprimer le token d'authentification
        AuthTokenManager.shared.removeToken()
        
        // Nettoyer toutes les données de session utilisateur
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        
        // Données de profil utilisateur
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_type")
        UserDefaults.standard.removeObject(forKey: "user_first_name")
        UserDefaults.standard.removeObject(forKey: "user_last_name")
        UserDefaults.standard.removeObject(forKey: "user_postal_code")
        UserDefaults.standard.removeObject(forKey: "user_birth_date")
        UserDefaults.standard.removeObject(forKey: "user_id")
        
        // Données d'abonnement
        UserDefaults.standard.removeObject(forKey: "has_active_subscription")
        UserDefaults.standard.removeObject(forKey: "subscription_type")
        UserDefaults.standard.removeObject(forKey: "subscription_next_payment_date")
        
        // Données économies (savings)
        UserDefaults.standard.removeObject(forKey: "savings_entries")
        
        // Synchroniser immédiatement pour s'assurer que les données sont supprimées
        UserDefaults.standard.synchronize()
        
        // Notifier la déconnexion
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }
}

