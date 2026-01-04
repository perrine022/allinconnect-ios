//
//  StripeSubscriptionPaymentSheetView.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//
//  IMPORTANT: Pour utiliser ce composant :
//  1. Installer Stripe iOS SDK : File → Add Package Dependencies → https://github.com/stripe/stripe-ios
//  2. Sélectionner StripePaymentSheet
//  3. Décommenter l'import StripePaymentSheet ci-dessous
//  4. Configurer votre merchantId Apple Pay dans Info.plist
//

import SwiftUI
import UIKit
import StripePaymentSheet

struct StripeSubscriptionPaymentSheetView: UIViewControllerRepresentable {
    let clientSecret: String // Peut être PaymentIntent (pi_...) ou SetupIntent (seti_...)
    let intentType: String? // "payment_intent" | "setup_intent" (renvoyé par le backend)
    let onPaymentResult: (Bool, String?) -> Void
    let customerId: String?
    let ephemeralKeySecret: String?
    let publishableKey: String?

    init(
        paymentIntentClientSecret: String? = nil,
        setupIntentClientSecret: String? = nil,
        clientSecret: String? = nil,
        intentType: String? = nil,
        onPaymentResult: @escaping (Bool, String?) -> Void,
        customerId: String? = nil,
        ephemeralKeySecret: String? = nil,
        publishableKey: String? = nil
    ) {
        // Déterminer le clientSecret (priorité: paramètres explicites > clientSecret générique)
        if let setupSecret = setupIntentClientSecret {
            self.clientSecret = setupSecret
            self.intentType = "setup_intent"
        } else if let paymentSecret = paymentIntentClientSecret {
            self.clientSecret = paymentSecret
            self.intentType = intentType ?? "payment_intent"
        } else if let genericSecret = clientSecret {
            self.clientSecret = genericSecret
            self.intentType = intentType
        } else {
            // Fallback pour compatibilité (ne devrait pas arriver)
            self.clientSecret = paymentIntentClientSecret ?? ""
            self.intentType = intentType
        }
        
        self.onPaymentResult = onPaymentResult
        self.customerId = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
        self.publishableKey = publishableKey
    }

    func makeUIViewController(context: Context) -> UIViewController {
        print("[StripeSubscriptionPaymentSheetView] makeUIViewController() - Début")
        let viewController = UIViewController()

        // 1) Publishable key
        if let publishableKey = publishableKey, !publishableKey.isEmpty {
            StripeAPI.defaultPublishableKey = publishableKey
            print("[StripeSubscriptionPaymentSheetView] PK backend: \(publishableKey.prefix(20))...")
        } else {
            StripeAPI.defaultPublishableKey = "pk_test_51SiVbTC2niFYoaySD4zt1bKI5Z6m3bcmedZGBZIU3jGCaMTaI6D6sHcW7dnd0ywxTbfswQpV1njEkg2D69vxDCEc00c46UdWsb"
            print("[StripeSubscriptionPaymentSheetView] ⚠️ PK manquante -> fallback test")
        }

        // 2) Config
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "AllinConnect"

        // IMPORTANT subscriptions
        configuration.allowsDelayedPaymentMethods = true

        // 3) Customer + ephemeral key (nécessaire pour PaymentSheet subscription)
        if let customerId = customerId,
           !customerId.isEmpty,
           let ephemeralKeySecret = ephemeralKeySecret,
           !ephemeralKeySecret.isEmpty {
            configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
            print("[StripeSubscriptionPaymentSheetView] Customer configuré: \(customerId)")
        } else {
            print("[StripeSubscriptionPaymentSheetView] ⚠️ customer/ephemeralKey manquants (Subscription PaymentSheet risque de ne pas fonctionner)")
        }

        // 4) Apple Pay (optionnel)
        if let merchantId = Bundle.main.object(forInfoDictionaryKey: "ApplePayMerchantId") as? String,
           !merchantId.isEmpty {
            configuration.applePay = .init(merchantId: merchantId, merchantCountryCode: "FR")
            print("[StripeSubscriptionPaymentSheetView] Apple Pay activé: \(merchantId)")
        }

        // 5) Return URL (recommandé)
        // Mets un schéma que tu as déclaré dans ton app: allinconnect://stripe-redirect
        // et configure les URL schemes.
        configuration.returnURL = "allinconnect://stripe-redirect"

        // 6) Prefill email
        if let userEmail = UserDefaults.standard.string(forKey: "user_email"), !userEmail.isEmpty {
            configuration.defaultBillingDetails.email = userEmail
            print("[StripeSubscriptionPaymentSheetView] Email prérempli: \(userEmail)")
        }

        // 7) Créer le PaymentSheet selon PI vs SetupIntent
        // Priorité : intentType du backend > détection par préfixe
        let secret = clientSecret
        let paymentSheet: PaymentSheet
        
        // Déterminer le type d'intent (priorité: intentType du backend > détection par préfixe)
        let detectedIntentType: String
        if let intentType = intentType, !intentType.isEmpty {
            detectedIntentType = intentType
            print("[StripeSubscriptionPaymentSheetView] IntentType depuis backend: \(intentType)")
        } else if secret.hasPrefix("seti_") {
            detectedIntentType = "setup_intent"
            print("[StripeSubscriptionPaymentSheetView] IntentType détecté par préfixe: setup_intent")
        } else if secret.hasPrefix("pi_") {
            detectedIntentType = "payment_intent"
            print("[StripeSubscriptionPaymentSheetView] IntentType détecté par préfixe: payment_intent")
        } else {
            print("[StripeSubscriptionPaymentSheetView] ❌ client_secret invalide: \(secret)")
            print("[StripeSubscriptionPaymentSheetView] ❌ Format attendu: pi_..._secret_... ou seti_..._secret_...")
            DispatchQueue.main.async {
                onPaymentResult(false, "client_secret Stripe invalide (attendu pi_..._secret_... ou seti_..._secret_...)")
            }
            return viewController
        }
        
        // Créer le PaymentSheet avec le bon initializer selon intentType
        if detectedIntentType == "setup_intent" {
            paymentSheet = PaymentSheet(setupIntentClientSecret: secret, configuration: configuration)
            print("[StripeSubscriptionPaymentSheetView] ✅ PaymentSheet initialisé avec SetupIntent (trial/0€)")
        } else {
            paymentSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: configuration)
            print("[StripeSubscriptionPaymentSheetView] ✅ PaymentSheet initialisé avec PaymentIntent")
        }

        // 8) Present
        DispatchQueue.main.async {
            print("💳 [STRIPE] Présentation du PaymentSheet…")
            paymentSheet.present(from: viewController) { paymentResult in
                print("═══════════════════════════════════════════════════════════")
                print("💳 [STRIPE] Résultat PaymentSheet: \(paymentResult)")
                print("═══════════════════════════════════════════════════════════")

                switch paymentResult {
                case .completed:
                    onPaymentResult(true, nil)
                case .failed(let error):
                    onPaymentResult(false, error.localizedDescription)
                case .canceled:
                    onPaymentResult(false, "Paiement annulé")
                @unknown default:
                    onPaymentResult(false, "Erreur inconnue")
                }
            }
        }

        print("[StripeSubscriptionPaymentSheetView] makeUIViewController() - Fin")
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
