//
//  ChangePasswordViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class ChangePasswordViewModel: ObservableObject {
    @Published var oldPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var showOldPassword: Bool = false
    @Published var showNewPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let profileAPIService: ProfileAPIService
    
    init(profileAPIService: ProfileAPIService? = nil) {
        // Créer le service dans un contexte MainActor
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
    }
    
    var isValid: Bool {
        !oldPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    func changePassword() {
        guard isValid else {
            errorMessage = "Veuillez remplir tous les champs correctement. Le nouveau mot de passe doit contenir au moins 6 caractères."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                // Créer la requête de changement de mot de passe
                let changePasswordRequest = ChangePasswordRequest(
                    oldPassword: oldPassword,
                    newPassword: newPassword
                )
                
                // Appeler l'API
                try await profileAPIService.changePassword(changePasswordRequest)
                
                isLoading = false
                successMessage = "Mot de passe modifié avec succès"
                
                // Réinitialiser les champs
                oldPassword = ""
                newPassword = ""
                confirmPassword = ""
                
                // Effacer le message de succès après 3 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.successMessage = nil
                }
            } catch {
                isLoading = false
                
                // Gérer les erreurs spécifiques
                if let apiError = error as? APIError {
                    switch apiError {
                    case .httpError(let statusCode, let message):
                        if statusCode == 400 {
                            errorMessage = message ?? "L'ancien mot de passe est incorrect"
                        } else {
                            errorMessage = message ?? "Erreur lors du changement de mot de passe"
                        }
                    default:
                        errorMessage = apiError.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                print("Erreur lors du changement de mot de passe: \(error)")
            }
        }
    }
}

