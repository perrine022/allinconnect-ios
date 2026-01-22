//
//  Offer.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

enum OfferType: String, Codable {
    case offer = "Offre"
    case event = "Event"
}

struct Offer: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let businessName: String
    let validUntil: String
    let startDate: String? // Date de début au format DD/MM/YYYY
    let discount: String
    let imageName: String
    let imageUrl: String? // URL de l'image depuis le backend (chemin relatif)
    let offerType: OfferType
    let isClub10: Bool
    let partnerId: UUID?
    let apiId: Int? // ID original de l'API pour pouvoir recharger les détails
    let distanceMeters: Double? // Distance en mètres depuis la position de l'utilisateur (si recherche géolocalisée)
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        businessName: String,
        validUntil: String,
        startDate: String? = nil,
        discount: String,
        imageName: String,
        imageUrl: String? = nil,
        offerType: OfferType = .offer,
        isClub10: Bool = false,
        partnerId: UUID? = nil,
        apiId: Int? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.businessName = businessName
        self.validUntil = validUntil
        self.startDate = startDate
        self.discount = discount
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.offerType = offerType
        self.isClub10 = isClub10
        self.partnerId = partnerId
        self.apiId = apiId
        self.distanceMeters = distanceMeters
    }
    
    /// Retourne l'URL complète de l'image
    /// Le backend renvoie maintenant des URLs absolues directement
    func fullImageUrl() -> String? {
        guard let imageUrl = imageUrl, !imageUrl.isEmpty else {
            return nil
        }
        
        // Si l'URL commence déjà par "http", c'est une URL absolue, on l'utilise directement
        if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
            return imageUrl
        }
        
        // Sinon, construire l'URL complète (fallback pour compatibilité)
        let baseURL = APIConfig.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        let path = imageUrl.hasPrefix("/") ? imageUrl : "/\(imageUrl)"
        return "\(baseURL)\(path)"
    }
    
    // Fonction utilitaire pour extraire l'ID API depuis l'UUID si possible
    func extractApiId() -> Int? {
        if let apiId = apiId {
            return apiId
        }
        // Essayer d'extraire depuis l'UUID si généré avec le format standard
        let uuidString = id.uuidString
        // Format: XXXXXXXX-0000-0000-0000-XXXXXXXXXXXX
        // On peut extraire les 8 premiers caractères hex
        if uuidString.count >= 8 {
            let hexString = String(uuidString.prefix(8))
            return Int(hexString, radix: 16)
        }
        return nil
    }
    
    /// Vérifie si l'offre est active à la date du jour
    /// Une offre est active si : startDate <= dateDuJour <= validUntil
    func isActiveToday() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Parser la date de début (format DD/MM/YYYY)
        let startDateParsed: Date?
        if let startDateString = startDate, !startDateString.isEmpty, startDateString != "N/A" {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            dateFormatter.dateFormat = "dd/MM/yyyy"
            startDateParsed = dateFormatter.date(from: startDateString)
        } else {
            // Si pas de date de début, considérer que l'offre a déjà commencé
            startDateParsed = nil
        }
        
        // Parser la date de fin (validUntil, format DD/MM/YYYY)
        let endDateParsed: Date?
        if validUntil != "N/A" && !validUntil.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "fr_FR")
            dateFormatter.dateFormat = "dd/MM/yyyy"
            endDateParsed = dateFormatter.date(from: validUntil)
        } else {
            // Si pas de date de fin, considérer que l'offre n'a pas de limite
            endDateParsed = nil
        }
        
        // Vérifier que startDate <= today (ou pas de startDate)
        if let startDate = startDateParsed {
            let startOfStartDate = calendar.startOfDay(for: startDate)
            if today < startOfStartDate {
                return false
            }
        }
        
        // Vérifier que today <= endDate (ou pas de endDate)
        if let endDate = endDateParsed {
            let startOfEndDate = calendar.startOfDay(for: endDate)
            if today > startOfEndDate {
                return false
            }
        }
        
        // Si on arrive ici, l'offre est active
        return true
    }
    
    /// Vérifie si l'offre est à venir (startDate > dateDuJour)
    /// Une offre est à venir si sa date de début est strictement supérieure à la date du jour
    func isUpcoming() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Parser la date de début (format DD/MM/YYYY)
        guard let startDateString = startDate, !startDateString.isEmpty, startDateString != "N/A" else {
            // Si pas de date de début, l'offre n'est pas considérée comme "à venir"
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        guard let startDateParsed = dateFormatter.date(from: startDateString) else {
            // Si on ne peut pas parser la date, on ne peut pas déterminer si c'est à venir
            return false
        }
        
        let startOfStartDate = calendar.startOfDay(for: startDateParsed)
        
        // L'offre est à venir si startDate > today
        return startOfStartDate > today
    }
}

