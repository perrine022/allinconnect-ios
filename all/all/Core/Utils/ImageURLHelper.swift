//
//  ImageURLHelper.swift
//  all
//
//  Created by Perrine Honoré on 04/01/2026.
//

import Foundation

/// Helper pour construire les URLs complètes des images d'établissements
struct ImageURLHelper {
    /// Construit l'URL complète à partir de establishmentImageUrl
    /// Gère les cas :
    /// - URL absolue (http:// ou https://) : retourne directement
    /// - URL relative commençant par /uploads/ : préfixe avec l'URL de base de l'API
    /// - null/nil : retourne nil
    static func buildImageURL(from establishmentImageUrl: String?) -> String? {
        guard let imageUrl = establishmentImageUrl, !imageUrl.isEmpty else {
            return nil
        }
        
        // Si l'URL commence déjà par http:// ou https://, c'est une URL absolue
        if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
            return imageUrl
        }
        
        // Si l'URL commence par /uploads/, construire l'URL complète
        if imageUrl.hasPrefix("/uploads/") {
            let baseURL = APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "")
            return "\(baseURL)\(imageUrl)"
        }
        
        // Si l'URL est relative mais ne commence pas par /, ajouter /
        if !imageUrl.hasPrefix("/") {
            let baseURL = APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "")
            return "\(baseURL)/\(imageUrl)"
        }
        
        // Sinon, préfixer avec l'URL de base
        let baseURL = APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        return "\(baseURL)\(imageUrl)"
    }
}

