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
import SafariServices

// Décommenter une fois le SDK Stripe installé :
// import StripePaymentSheet

struct StripeSubscriptionPaymentSheetView: UIViewControllerRepresentable {
    let paymentIntentClientSecret: String
    let onPaymentResult: (Bool, String?) -> Void
    // Optionnel : Customer ID et Ephemeral Key (pour les abonnements récurrents)
    let customerId: String?
    let ephemeralKeySecret: String?
    
    init(
        paymentIntentClientSecret: String,
        onPaymentResult: @escaping (Bool, String?) -> Void,
        customerId: String? = nil,
        ephemeralKeySecret: String? = nil
    ) {
        self.paymentIntentClientSecret = paymentIntentClientSecret
        self.onPaymentResult = onPaymentResult
        self.customerId = customerId
        self.ephemeralKeySecret = ephemeralKeySecret
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        print("[StripeSubscriptionPaymentSheetView] makeUIViewController() - Début")
        let viewController = UIViewController()
        
        // TODO: Une fois le SDK Stripe installé, décommenter ce code :
        /*
        // 1. Configurer la clé publique Stripe
        // IMPORTANT: Remplacer par votre clé publique depuis Stripe Dashboard
        // Test : https://dashboard.stripe.com/test/apikeys
        // Live : https://dashboard.stripe.com/apikeys
        StripeAPI.defaultPublishableKey = "pk_test_VOTRE_CLE_PUBLIQUE_ICI"
        
        // 2. Créer la configuration du Payment Sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "All In Connect"
        
        // 3. Configurer le Customer avec l'ephemeral key (si fourni)
        // Note: Pour un paiement unique, le Customer n'est pas nécessaire
        if let customerId = customerId, let ephemeralKeySecret = ephemeralKeySecret {
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKeySecret
            )
        }
        
        // 4. Activer Apple Pay si disponible
        // IMPORTANT: Configurer votre merchantId dans Info.plist
        // Ajouter : <key>com.apple.developer.in-app-payments</key>
        //           <array><string>merchant.com.yourapp.merchantid</string></array>
        if let merchantId = Bundle.main.object(forInfoDictionaryKey: "ApplePayMerchantId") as? String,
           !merchantId.isEmpty {
            configuration.applePay = .init(
                merchantId: merchantId,
                merchantCountryCode: "FR"
            )
        }
        
        // 5. Préremplir l'email si disponible
        if let userEmail = UserDefaults.standard.string(forKey: "user_email"), !userEmail.isEmpty {
            configuration.defaultBillingDetails.email = userEmail
        }
        
        // 6. Créer le Payment Sheet
        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration
        )
        
        // 7. Présenter le Payment Sheet
        DispatchQueue.main.async {
            paymentSheet.present(from: viewController) { paymentResult in
                print("[StripeSubscriptionPaymentSheetView] Payment result: \(paymentResult)")
                switch paymentResult {
                case .completed:
                    print("[StripeSubscriptionPaymentSheetView] Payment completed")
                    onPaymentResult(true, nil)
                case .failed(let error):
                    print("[StripeSubscriptionPaymentSheetView] Payment failed: \(error.localizedDescription)")
                    onPaymentResult(false, error.localizedDescription)
                case .canceled:
                    print("[StripeSubscriptionPaymentSheetView] Payment canceled")
                    onPaymentResult(false, "Paiement annulé")
                @unknown default:
                    print("[StripeSubscriptionPaymentSheetView] Payment unknown error")
                    onPaymentResult(false, "Erreur inconnue")
                }
            }
        }
        */
        
        // Fallback: Afficher un message si le SDK n'est pas installé
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "SDK Stripe requis",
                message: "Veuillez installer le SDK Stripe PaymentSheet pour utiliser cette fonctionnalité.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                onPaymentResult(false, "SDK Stripe non installé")
            })
            viewController.present(alert, animated: true)
        }
        
        print("[StripeSubscriptionPaymentSheetView] makeUIViewController() - Fin")
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas de mise à jour nécessaire
    }
}




