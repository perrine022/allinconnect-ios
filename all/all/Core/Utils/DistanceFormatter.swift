//
//  DistanceFormatter.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import Foundation

/// Utilitaire pour formater les distances en mètres en format lisible
struct DistanceFormatter {
    /// Formate une distance en mètres en format lisible (ex: "2.5 km", "500 m")
    /// - Parameter meters: Distance en mètres
    /// - Returns: String formatée (ex: "2.5 km", "500 m")
    static func formatDistance(_ meters: Double?) -> String? {
        guard let meters = meters, meters > 0 else {
            return nil
        }
        
        if meters < 1000 {
            // Moins d'un kilomètre, afficher en mètres
            return "\(Int(meters)) m"
        } else {
            // Plus d'un kilomètre, afficher en kilomètres avec une décimale
            let kilometers = meters / 1000.0
            return String(format: "%.1f km", kilometers)
        }
    }
    
    /// Formate une distance en mètres en format court (ex: "2.5km", "500m")
    /// - Parameter meters: Distance en mètres
    /// - Returns: String formatée (ex: "2.5km", "500m")
    static func formatDistanceShort(_ meters: Double?) -> String? {
        guard let meters = meters, meters > 0 else {
            return nil
        }
        
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            let kilometers = meters / 1000.0
            return String(format: "%.1fkm", kilometers)
        }
    }
}

