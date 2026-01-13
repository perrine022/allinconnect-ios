//
//  AuthTokenManager.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

/// Gestionnaire pour le stockage et la récupération du token d'authentification
class AuthTokenManager {
    static let shared = AuthTokenManager()
    
    private let tokenKey = "auth_token"
    
    private init() {}
    
    /// Sauvegarde le token d'authentification
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Récupère le token d'authentification
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Vérifie si un token existe
    func hasToken() -> Bool {
        return getToken() != nil && !getToken()!.isEmpty
    }
    
    /// Supprime le token d'authentification
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.synchronize()
    }
}





