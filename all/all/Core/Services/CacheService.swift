//
//  CacheService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

// MARK: - Cache Entry
struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let expirationTime: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}

// MARK: - Cache Service
class CacheService {
    static let shared = CacheService()
    
    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "cache_"
    
    // Durées de cache par défaut (en secondes)
    enum CacheDuration {
        static let offers: TimeInterval = 300 // 5 minutes
        static let profile: TimeInterval = 600 // 10 minutes
        static let card: TimeInterval = 300 // 5 minutes
    }
    
    private init() {}
    
    // MARK: - Generic Cache Methods
    
    /// Sauvegarder des données en cache
    func save<T: Codable>(_ data: T, forKey key: String, expirationTime: TimeInterval) {
        let entry = CacheEntry(data: data, timestamp: Date(), expirationTime: expirationTime)
        
        if let encoded = try? JSONEncoder().encode(entry) {
            userDefaults.set(encoded, forKey: "\(cachePrefix)\(key)")
            print("[CacheService] Données sauvegardées en cache pour la clé: \(key)")
        }
    }
    
    /// Récupérer des données depuis le cache
    func get<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: "\(cachePrefix)\(key)"),
              let entry = try? JSONDecoder().decode(CacheEntry<T>.self, from: data) else {
            print("[CacheService] Aucune donnée en cache pour la clé: \(key)")
            return nil
        }
        
        if entry.isExpired {
            print("[CacheService] Cache expiré pour la clé: \(key)")
            remove(forKey: key)
            return nil
        }
        
        print("[CacheService] Données récupérées depuis le cache pour la clé: \(key)")
        return entry.data
    }
    
    /// Vérifier si des données sont en cache et valides
    func hasValidCache(forKey key: String) -> Bool {
        guard let data = userDefaults.data(forKey: "\(cachePrefix)\(key)") else {
            return false
        }
        
        // Essayer de décoder juste pour vérifier la structure et la date
        struct CacheEntryMetadata: Codable {
            let timestamp: Date
            let expirationTime: TimeInterval
        }
        
        guard let entry = try? JSONDecoder().decode(CacheEntryMetadata.self, from: data) else {
            return false
        }
        
        return Date().timeIntervalSince(entry.timestamp) <= entry.expirationTime
    }
    
    /// Supprimer des données du cache
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: "\(cachePrefix)\(key)")
        print("[CacheService] Cache supprimé pour la clé: \(key)")
    }
    
    /// Vider tout le cache
    func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cachePrefix) }
        keys.forEach { userDefaults.removeObject(forKey: $0) }
        print("[CacheService] Tout le cache a été vidé")
    }
    
    // MARK: - Specific Cache Methods
    
    /// Sauvegarder les offres en cache
    func saveOffers(_ offers: [Offer]) {
        save(offers, forKey: "offers", expirationTime: CacheDuration.offers)
    }
    
    /// Récupérer les offres depuis le cache
    func getOffers() -> [Offer]? {
        return get([Offer].self, forKey: "offers")
    }
    
    /// Sauvegarder les infos profil en cache
    func saveProfile(_ userLight: UserLightResponse) {
        save(userLight, forKey: "profile", expirationTime: CacheDuration.profile)
    }
    
    /// Récupérer les infos profil depuis le cache
    func getProfile() -> UserLightResponse? {
        return get(UserLightResponse.self, forKey: "profile")
    }
    
    /// Sauvegarder les données de carte en cache
    func saveCardData(_ cardData: CardCacheData) {
        save(cardData, forKey: "card", expirationTime: CacheDuration.card)
    }
    
    /// Récupérer les données de carte depuis le cache
    func getCardData() -> CardCacheData? {
        return get(CardCacheData.self, forKey: "card")
    }
}

// MARK: - Card Cache Data
struct CardCacheData: Codable {
    let cardNumber: String?
    let cardType: String?
    let isCardActive: Bool
    let cardExpirationDate: Date?
    let isMember: Bool
    let referralCode: String
    let referralLink: String
    let savings: Double
    let referrals: Int
    let wallet: Double
    let favoritesCount: Int
}


