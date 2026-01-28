//
//  BillingViewModel.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class BillingViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var premiumEnabled: Bool = false
    @Published var subscriptionStatus: String? // "ACTIVE", "PAST_DUE", "CANCELED", etc.
    @Published var currentPeriodEnd: Date?
    @Published var currentPeriodStart: Date? // Début de la période actuelle
    @Published var subscriptionCreatedAt: Date? // Date de création de l'abonnement
    @Published var cardValidityDate: Date? // Date de validité de la carte depuis /users/me/light
    
    // Détails de l'abonnement
    @Published var stripeSubscriptionId: String?
    @Published var planName: String?
    @Published var lastFour: String?
    @Published var cardBrand: String?
    
    // Cache optionnel (la source de vérité reste le backend)
    private let premiumCacheKey = "premium_enabled_cache"
    
    private let billingAPIService: BillingAPIService
    private let profileAPIService: ProfileAPIService
    
    init(billingAPIService: BillingAPIService? = nil, profileAPIService: ProfileAPIService? = nil) {
        print("[BillingViewModel] init() - Début")
        if let billingAPIService = billingAPIService {
            self.billingAPIService = billingAPIService
        } else {
            self.billingAPIService = BillingAPIService()
        }
        
        if let profileAPIService = profileAPIService {
            self.profileAPIService = profileAPIService
        } else {
            self.profileAPIService = ProfileAPIService()
        }
        
        // Charger le cache optionnel au démarrage
        loadPremiumCache()
        
        // Charger le statut depuis le backend
        Task {
            await loadSubscriptionStatus()
            // Charger les détails après le statut (en parallèle si possible)
            await loadSubscriptionDetails()
        }
        print("[BillingViewModel] init() - Fin")
    }
    
    // MARK: - Load Subscription Status
    func loadSubscriptionStatus() async {
        print("[BillingViewModel] loadSubscriptionStatus() - Début")
        isLoading = true
        errorMessage = nil
        
        do {
            let status = try await billingAPIService.getSubscriptionStatus()
            premiumEnabled = status.premiumEnabled
            subscriptionStatus = status.subscriptionStatus
            
            // Parser la date de fin de période
            if let periodEndString = status.currentPeriodEnd {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
                currentPeriodEnd = formatter.date(from: periodEndString)
            }
            
            // Charger les données allégées depuis /users/me/light pour récupérer cardValidityDate
            await loadUserLightData()
            
            // Mettre à jour le cache
            savePremiumCache(status.premiumEnabled)
            
            isLoading = false
            print("[BillingViewModel] loadSubscriptionStatus() - Succès: premiumEnabled=\(status.premiumEnabled), status=\(status.subscriptionStatus ?? "nil")")
        } catch {
            isLoading = false
            errorMessage = "Erreur lors du chargement du statut: \(error.localizedDescription)"
            print("[BillingViewModel] loadSubscriptionStatus() - Erreur: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load User Light Data
    /// Charge les données allégées depuis /users/me/light pour récupérer cardValidityDate
    func loadUserLightData() async {
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [BillingViewModel] loadUserLightData() - DÉBUT")
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [BillingViewModel] Endpoint: GET /api/v1/users/me/light")
        
        do {
            let userLight = try await profileAPIService.getUserLight()
            
            print("🔍 [BillingViewModel] Réponse /users/me/light reçue:")
            print("   - firstName: \(userLight.firstName)")
            print("   - lastName: \(userLight.lastName)")
            print("   - isMember: \(userLight.isMember?.description ?? "nil")")
            print("   - userType: \(userLight.userType ?? "nil")")
            print("   - isCardActive: \(userLight.isCardActive?.description ?? "nil")")
            print("   - subscriptionDate (raw): \(userLight.subscriptionDate ?? "nil")")
            print("   - renewalDate (raw): \(userLight.renewalDate ?? "nil")")
            print("   - cardValidityDate (raw): \(userLight.cardValidityDate ?? "nil")")
            print("   - planDuration: \(userLight.planDuration ?? "nil")")
            if let card = userLight.card {
                print("   - card.cardNumber: \(card.cardNumber)")
                print("   - card.type: \(card.type)")
            }
            
            // Parser cardValidityDate
            if let cardValidityDateString = userLight.cardValidityDate {
                print("🔍 [BillingViewModel] Parsing de cardValidityDate...")
                print("   - cardValidityDateString (raw): \(cardValidityDateString)")
                
                // Essayer plusieurs formats de parsing
                var parsedDate: Date? = nil
                
                // Format 1: ISO8601 avec fractional seconds et timezone (ex: 2026-07-27T08:06:07.000000Z)
                let formatter1 = ISO8601DateFormatter()
                formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
                parsedDate = formatter1.date(from: cardValidityDateString)
                if parsedDate != nil {
                    print("   ✅ Parsing réussi avec format ISO8601 (fractional seconds + timezone)")
                }
                
                // Format 2: ISO8601 standard avec timezone (ex: 2026-07-27T08:06:07Z)
                if parsedDate == nil {
                    let formatter2 = ISO8601DateFormatter()
                    formatter2.formatOptions = [.withInternetDateTime, .withTimeZone]
                    parsedDate = formatter2.date(from: cardValidityDateString)
                    if parsedDate != nil {
                        print("   ✅ Parsing réussi avec format ISO8601 (timezone)")
                    }
                }
                
                // Format 3: ISO8601 sans timezone (ex: 2026-07-27T08:06:07)
                if parsedDate == nil {
                    let formatter3 = ISO8601DateFormatter()
                    formatter3.formatOptions = [.withInternetDateTime]
                    parsedDate = formatter3.date(from: cardValidityDateString)
                    if parsedDate != nil {
                        print("   ✅ Parsing réussi avec format ISO8601 (sans timezone)")
                    }
                }
                
                // Format 4: Format personnalisé yyyy-MM-dd'T'HH:mm:ss (sans timezone)
                if parsedDate == nil {
                    let customFormatter = DateFormatter()
                    customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    customFormatter.locale = Locale(identifier: "en_US_POSIX")
                    customFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC par défaut
                    customFormatter.isLenient = true // Permet plus de flexibilité
                    parsedDate = customFormatter.date(from: cardValidityDateString)
                    if parsedDate != nil {
                        print("   ✅ Parsing réussi avec format personnalisé (yyyy-MM-dd'T'HH:mm:ss)")
                    } else {
                        print("   ❌ Échec parsing avec format yyyy-MM-dd'T'HH:mm:ss")
                        print("   - String à parser: '\(cardValidityDateString)'")
                        print("   - Longueur: \(cardValidityDateString.count) caractères")
                    }
                }
                
                // Format 5: Format personnalisé avec timezone (ex: 2026-07-27T08:06:07+00:00)
                if parsedDate == nil {
                    let customFormatter2 = DateFormatter()
                    customFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    customFormatter2.locale = Locale(identifier: "en_US_POSIX")
                    parsedDate = customFormatter2.date(from: cardValidityDateString)
                    if parsedDate != nil {
                        print("   ✅ Parsing réussi avec format personnalisé (avec timezone)")
                    }
                }
                
                cardValidityDate = parsedDate
                
                if let date = cardValidityDate {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    print("✅ [BillingViewModel] cardValidityDate parsé avec succès:")
                    print("   - cardValidityDate (Date): \(dateFormatter.string(from: date))")
                    print("   - cardValidityDate (ISO): \(date)")
                    
                    // Comparer avec la date actuelle
                    let currentDate = Date()
                    let comparison = currentDate.compare(date)
                    if comparison == .orderedAscending {
                        print("   - cardValidityDate est dans le FUTUR (date actuelle < cardValidityDate)")
                        let daysUntil = Calendar.current.dateComponents([.day], from: currentDate, to: date).day ?? 0
                        print("   - Jours jusqu'à cardValidityDate: \(daysUntil)")
                    } else if comparison == .orderedDescending {
                        print("   - cardValidityDate est dans le PASSÉ (date actuelle > cardValidityDate)")
                        let daysSince = Calendar.current.dateComponents([.day], from: date, to: currentDate).day ?? 0
                        print("   - Jours écoulés depuis cardValidityDate: \(daysSince)")
                    } else {
                        print("   - cardValidityDate est AUJOURD'HUI (date actuelle == cardValidityDate)")
                    }
                } else {
                    print("❌ [BillingViewModel] Impossible de parser cardValidityDate avec tous les formats testés")
                    print("   - Format reçu: \(cardValidityDateString)")
                }
            } else {
                print("⚠️ [BillingViewModel] cardValidityDate non disponible dans la réponse /users/me/light")
                print("   → cardValidityDate restera nil")
            }
            
            // Parser subscriptionDate si disponible
            if let subscriptionDateString = userLight.subscriptionDate {
                print("🔍 [BillingViewModel] Parsing de subscriptionDate depuis /users/me/light...")
                print("   - subscriptionDateString (raw): \(subscriptionDateString)")
                
                // Essayer plusieurs formats comme pour cardValidityDate
                var parsedSubscriptionDate: Date? = nil
                
                // Format 1: ISO8601 avec fractional seconds et timezone
                let formatter1 = ISO8601DateFormatter()
                formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
                parsedSubscriptionDate = formatter1.date(from: subscriptionDateString)
                if parsedSubscriptionDate != nil {
                    print("   ✅ Parsing réussi avec format ISO8601 (fractional seconds + timezone)")
                }
                
                // Format 2: ISO8601 standard avec timezone
                if parsedSubscriptionDate == nil {
                    let formatter2 = ISO8601DateFormatter()
                    formatter2.formatOptions = [.withInternetDateTime, .withTimeZone]
                    parsedSubscriptionDate = formatter2.date(from: subscriptionDateString)
                    if parsedSubscriptionDate != nil {
                        print("   ✅ Parsing réussi avec format ISO8601 (timezone)")
                    }
                }
                
                // Format 3: ISO8601 sans timezone
                if parsedSubscriptionDate == nil {
                    let formatter3 = ISO8601DateFormatter()
                    formatter3.formatOptions = [.withInternetDateTime]
                    parsedSubscriptionDate = formatter3.date(from: subscriptionDateString)
                    if parsedSubscriptionDate != nil {
                        print("   ✅ Parsing réussi avec format ISO8601 (sans timezone)")
                    }
                }
                
                // Format 4: Format personnalisé yyyy-MM-dd'T'HH:mm:ss
                if parsedSubscriptionDate == nil {
                    let customFormatter = DateFormatter()
                    customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    customFormatter.locale = Locale(identifier: "en_US_POSIX")
                    customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    customFormatter.isLenient = true
                    parsedSubscriptionDate = customFormatter.date(from: subscriptionDateString)
                    if parsedSubscriptionDate != nil {
                        print("   ✅ Parsing réussi avec format personnalisé (yyyy-MM-dd'T'HH:mm:ss)")
                    } else {
                        print("   ❌ Échec parsing avec format yyyy-MM-dd'T'HH:mm:ss")
                    }
                }
                
                subscriptionCreatedAt = parsedSubscriptionDate
                
                if let date = subscriptionCreatedAt {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    print("✅ [BillingViewModel] subscriptionDate récupéré depuis /users/me/light: \(dateFormatter.string(from: date))")
                } else {
                    print("❌ [BillingViewModel] Impossible de parser subscriptionDate avec tous les formats: \(subscriptionDateString)")
                }
            } else {
                print("⚠️ [BillingViewModel] subscriptionDate non disponible dans /users/me/light")
            }
            
            print("🔍 [BillingViewModel] loadUserLightData() - SUCCÈS")
            print("   - cardValidityDate final: \(cardValidityDate?.description ?? "nil")")
            print("═══════════════════════════════════════════════════════════")
        } catch {
            print("❌ [BillingViewModel] loadUserLightData() - ERREUR: \(error.localizedDescription)")
            print("   - Type d'erreur: \(type(of: error))")
            // Ne pas bloquer l'UI si cette requête échoue
        }
    }
    
    // MARK: - Load Subscription Details
    func loadSubscriptionDetails() async {
        print("[BillingViewModel] loadSubscriptionDetails() - Début")
        // Ne pas mettre isLoading à true ici pour ne pas bloquer l'UI
        do {
            // Récupérer l'ID utilisateur
            let userId = try await profileAPIService.getCurrentUserId()
            
            // Charger les détails de l'abonnement
            let details = try await billingAPIService.getSubscriptionDetails(userId: userId)
            
            // S'assurer que cardValidityDate est chargé depuis /users/me/light
            // (au cas où loadSubscriptionStatus() n'aurait pas été appelé)
            if cardValidityDate == nil {
                print("⚠️ [BillingViewModel] cardValidityDate est nil, appel de loadUserLightData()...")
                await loadUserLightData()
            }
            
            // Mettre à jour les propriétés
            stripeSubscriptionId = details.stripeSubscriptionId
            planName = details.planName
            lastFour = details.lastFour
            cardBrand = details.cardBrand
            
            // Mettre à jour le statut et premiumEnabled si disponibles
            if let status = details.status {
                subscriptionStatus = status
            }
            premiumEnabled = details.premiumEnabled
            
            // Parser les dates si disponibles
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
            
            if let periodStartString = details.currentPeriodStart {
                currentPeriodStart = formatter.date(from: periodStartString)
            }
            
            if let periodEndString = details.currentPeriodEnd {
                currentPeriodEnd = formatter.date(from: periodEndString)
            }
            
            // Parser la date de création de l'abonnement
            print("🔍 [BillingViewModel] Parsing de la date de souscription...")
            print("   - details.createdAt (raw): \(details.createdAt ?? "nil")")
            print("   - currentPeriodStart (raw): \(details.currentPeriodStart ?? "nil")")
            
            if let createdAtString = details.createdAt {
                subscriptionCreatedAt = formatter.date(from: createdAtString)
                if let date = subscriptionCreatedAt {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    print("   ✅ subscriptionCreatedAt défini depuis createdAt: \(dateFormatter.string(from: date))")
                } else {
                    print("   ⚠️ Impossible de parser createdAt: \(createdAtString)")
                }
            } else if let periodStart = currentPeriodStart {
                // Si createdAt n'est pas disponible, utiliser currentPeriodStart comme approximation
                subscriptionCreatedAt = periodStart
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                dateFormatter.locale = Locale(identifier: "fr_FR")
                print("   ⚠️ createdAt non disponible, utilisation de currentPeriodStart: \(dateFormatter.string(from: periodStart))")
            } else {
                print("   ❌ Aucune date de souscription disponible (ni createdAt ni currentPeriodStart)")
            }
            
            print("[BillingViewModel] loadSubscriptionDetails() - Succès")
            print("   - planName: \(planName ?? "nil")")
            print("   - status: \(subscriptionStatus ?? "nil")")
            print("   - lastFour: \(lastFour ?? "nil")")
            print("   - cardBrand: \(cardBrand ?? "nil")")
            if let subscriptionDate = subscriptionCreatedAt {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                dateFormatter.locale = Locale(identifier: "fr_FR")
                print("   - subscriptionCreatedAt: \(dateFormatter.string(from: subscriptionDate))")
            } else {
                print("   - subscriptionCreatedAt: nil")
            }
        } catch {
            print("[BillingViewModel] loadSubscriptionDetails() - Erreur: \(error.localizedDescription)")
            // Ne pas afficher d'erreur si l'utilisateur n'a pas d'abonnement (404)
            if !error.localizedDescription.contains("404") && !error.localizedDescription.contains("Not Found") {
                // Ne pas écraser l'erreur existante si elle est déjà définie
                if errorMessage == nil {
                    errorMessage = "Erreur lors du chargement des détails: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Start Subscription
    /// Démarre le processus d'abonnement en appelant le backend pour créer le PaymentSheet
    /// Retourne les données nécessaires pour afficher le PaymentSheet Stripe
    func startSubscription(priceId: String) async throws -> SubscriptionPaymentSheetResponse {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] startSubscription() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Appeler le backend pour créer la subscription et récupérer le PaymentSheet
            let response = try await billingAPIService.createSubscriptionPaymentSheet(priceId: priceId)
            
            isLoading = false
            print("💳 [BILLING] startSubscription() - Succès")
            print("   - subscriptionId: \(response.subscriptionId ?? "nil")")
            print("   - customerId: \(response.customerId)")
            print("   - intentType: \(response.intentType ?? "auto-détecté")")
            
            return response
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de l'initialisation du paiement: \(error.localizedDescription)"
            print("💳 [BILLING] startSubscription() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Handle Payment Success
    /// Appelée après que le PaymentSheet renvoie .completed
    /// Selon le guide : Appeler GET /api/v1/payment/status/{paymentIntentId} pour forcer la synchronisation
    func handlePaymentSuccess(paymentIntentClientSecret: String?) async {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] handlePaymentSuccess() - Début")
        print("═══════════════════════════════════════════════════════════")
        
        // Étape 1 : Extraire le paymentIntentId du clientSecret
        // Format: "pi_xxx_secret_xxx" -> extraire "pi_xxx"
        var paymentIntentId: String? = nil
        if let clientSecret = paymentIntentClientSecret {
            if let secretIndex = clientSecret.range(of: "_secret_") {
                // Extraire tout ce qui est avant "_secret_"
                paymentIntentId = String(clientSecret[..<secretIndex.lowerBound])
            } else if clientSecret.hasPrefix("pi_") {
                // Si pas de "_secret_", prendre les premiers caractères jusqu'à un certain point
                let components = clientSecret.components(separatedBy: "_")
                if components.count >= 2 {
                    paymentIntentId = "\(components[0])_\(components[1])"
                }
            } else if clientSecret.hasPrefix("seti_") {
                // Pour setup_intent, on peut aussi extraire l'ID de la même manière
                if let secretIndex = clientSecret.range(of: "_secret_") {
                    paymentIntentId = String(clientSecret[..<secretIndex.lowerBound])
                }
            }
            
            if let id = paymentIntentId {
                print("💳 [BILLING] PaymentIntentId extrait: \(id)")
            } else {
                print("💳 [BILLING] ⚠️ Impossible d'extraire le paymentIntentId du clientSecret")
            }
        }
        
        // Étape 2 : Appeler GET /api/v1/payment/status/{paymentIntentId} pour forcer la synchronisation
        // Selon le guide : "Cet appel déclenche l'activation manuelle du mode Premium sur le backend si Stripe confirme le succès"
        if let paymentIntentId = paymentIntentId {
            print("💳 [BILLING] Appel GET /api/v1/payment/status/\(paymentIntentId) pour forcer la synchronisation...")
            let paymentAPIService = PaymentAPIService()
            do {
                let statusResponse = try await paymentAPIService.getPaymentStatus(paymentIntentId: paymentIntentId)
                print("💳 [BILLING] ✅ Statut du paiement: \(statusResponse.status)")
            } catch {
                print("💳 [BILLING] ⚠️ Erreur lors de la vérification du statut: \(error.localizedDescription)")
                // On continue quand même, le webhook peut avoir déjà traité
            }
        }
        
        // Étape 3 : Attendre un court délai pour que le webhook Stripe soit traité
        print("💳 [BILLING] ⏳ Attente de 1 seconde pour laisser le webhook Stripe traiter le paiement...")
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
        
        // Étape 4 : Rafraîchir le profil utilisateur via GET /api/v1/users/me
        // Selon la checklist : "Une fois que Stripe renvoie .completed, l'app doit rafraîchir le profil"
        // "Le profil renvoie maintenant un objet card (de type CardDTO) et un subscriptionStatus"
        // "Si subscriptionStatus == 'ACTIVE', c'est gagné !"
        print("💳 [BILLING] Rafraîchissement du profil utilisateur via GET /api/v1/users/me...")
        let profileAPIService = ProfileAPIService()
        var subscriptionActive = false
        
        // Faire quelques tentatives pour laisser le webhook se traiter (max 3 tentatives)
        for attempt in 0..<3 {
            do {
                let userMe = try await profileAPIService.getUserMe()
                print("💳 [BILLING] ✅ Profil utilisateur récupéré (tentative \(attempt + 1)/3)")
                print("   - premiumEnabled: \(userMe.premiumEnabled?.description ?? "nil")")
                print("   - subscriptionType: \(userMe.subscriptionType ?? "nil")")
                print("   - card: \(userMe.card != nil ? "présent" : "nil")")
                
                // Vérifier si premiumEnabled == true (le backend met à jour ce champ via webhook)
                // Note: subscriptionStatus est vérifié via loadSubscriptionStatus() qui appelle /billing/subscription/status
                if userMe.premiumEnabled == true {
                    subscriptionActive = true
                    print("💳 [BILLING] ✅ premiumEnabled == true - Premium activé !")
                    break
                } else {
                    print("💳 [BILLING] ⏳ Tentative \(attempt + 1)/3 : subscriptionStatus pas encore ACTIVE, attente...")
                    if attempt < 2 {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes entre chaque tentative
                    }
                }
            } catch {
                print("💳 [BILLING] ⚠️ Erreur lors du rafraîchissement du profil (tentative \(attempt + 1)/3): \(error.localizedDescription)")
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes entre chaque tentative
                }
            }
        }
        
        // Étape 5 : Recharger aussi le statut de l'abonnement via l'endpoint dédié
        print("💳 [BILLING] Rechargement du statut de l'abonnement via GET /billing/subscription/status...")
        await loadSubscriptionStatus()
        
        if subscriptionActive || premiumEnabled {
            successMessage = "Abonnement activé avec succès !"
            print("💳 [BILLING] ✅ Premium activé avec succès")
        } else {
            print("💳 [BILLING] ⚠️ Premium pas encore activé, le webhook peut être en cours de traitement")
            print("💳 [BILLING] 💡 L'utilisateur peut rafraîchir manuellement ou attendre quelques secondes")
        }
        
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] handlePaymentSuccess() - Fin")
        print("═══════════════════════════════════════════════════════════")
    }
    
    // MARK: - Create Portal Session
    func createPortalSession() async throws -> URL {
        print("[BillingViewModel] createPortalSession() - Début")
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await billingAPIService.createPortalSession()
            guard let url = URL(string: response.url) else {
                throw APIError.invalidResponse
            }
            isLoading = false
            print("[BillingViewModel] createPortalSession() - Succès: url=\(response.url)")
            return url
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de la création de la session: \(error.localizedDescription)"
            print("[BillingViewModel] createPortalSession() - Erreur: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Cancel Subscription
    /// Annule un abonnement Stripe
    /// Endpoint: POST /api/v1/billing/subscription/cancel
    /// Body: {"subscriptionId": "sub_..."}
    /// Après annulation, le backend met à jour automatiquement le statut via webhook
    /// Le front doit rafraîchir le profil pour voir le nouveau statut
    func cancelSubscription(subscriptionId: String) async throws {
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] cancelSubscription() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("💳 [BILLING] subscriptionId: \(subscriptionId)")
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Appeler l'endpoint d'annulation
            let response = try await billingAPIService.cancelSubscription(subscriptionId: subscriptionId)
            
            print("💳 [BILLING] ✅ Abonnement annulé avec succès")
            print("   - Statut: \(response.status ?? "N/A")")
            print("   - canceledAt: \(response.canceledAt != nil ? "\(response.canceledAt!)" : "N/A")")
            
            // Attendre un court délai pour que le webhook Stripe soit traité
            print("💳 [BILLING] ⏳ Attente de 1 seconde pour laisser le webhook Stripe traiter l'annulation...")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            
            // Rafraîchir le profil utilisateur pour voir le nouveau statut
            // Le backend met à jour automatiquement premiumEnabled et subscriptionStatus via webhook
            print("💳 [BILLING] Rafraîchissement du profil utilisateur via GET /api/v1/users/me...")
            let profileAPIService = ProfileAPIService()
            do {
                let userMe = try await profileAPIService.getUserMe()
                print("💳 [BILLING] ✅ Profil utilisateur récupéré")
                print("   - premiumEnabled: \(userMe.premiumEnabled?.description ?? "nil")")
                print("   - subscriptionType: \(userMe.subscriptionType ?? "nil")")
            } catch {
                print("💳 [BILLING] ⚠️ Erreur lors du rafraîchissement du profil: \(error.localizedDescription)")
                // On continue quand même, le webhook peut avoir déjà traité
            }
            
            // Recharger aussi le statut de l'abonnement via l'endpoint dédié
            print("💳 [BILLING] Rechargement du statut de l'abonnement via GET /billing/subscription/status...")
            await loadSubscriptionStatus()
            
            // Nettoyer le subscriptionId de UserDefaults après annulation réussie
            UserDefaults.standard.removeObject(forKey: "current_subscription_id")
            print("💳 [BILLING] ✅ subscriptionId supprimé de UserDefaults")
            
            isLoading = false
            successMessage = "Abonnement annulé avec succès"
            
            // Notifier les autres parties de l'app
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionUpdated"), object: nil)
            print("💳 [BILLING] ✅ Notification 'SubscriptionUpdated' envoyée")
            
            print("═══════════════════════════════════════════════════════════")
            print("💳 [BILLING] cancelSubscription() - Fin")
            print("═══════════════════════════════════════════════════════════")
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de l'annulation de l'abonnement: \(error.localizedDescription)"
            print("💳 [BILLING] ❌ Erreur lors de l'annulation: \(error.localizedDescription)")
            print("═══════════════════════════════════════════════════════════")
            throw error
        }
    }
    
    // MARK: - Cache Management (optionnel)
    private func loadPremiumCache() {
        premiumEnabled = UserDefaults.standard.bool(forKey: premiumCacheKey)
    }
    
    private func savePremiumCache(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: premiumCacheKey)
    }
}

