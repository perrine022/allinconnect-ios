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
import StripePaymentSheet

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
        
        // 1. Configurer la clé publique Stripe
        // Clé publique de test fournie par le backend
        StripeAPI.defaultPublishableKey = "pk_test_51SiVbTC2niFYoaySD4zt1bKI5Z6m3bcmedZGBZIU3jGCaMTaI6D6sHcW7dnd0ywxTbfswQpV1njEkg2D69vxDCEc00c46UdWsb"
        
        // 2. Créer la configuration du Payment Sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "AllinConnect"
        
        // 3. Configurer le Customer avec l'ephemeral key (pour les abonnements récurrents)
        if let customerId = customerId, let ephemeralKeySecret = ephemeralKeySecret {
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKeySecret
            )
            print("[StripeSubscriptionPaymentSheetView] Customer configuré: \(customerId)")
        }
        
        // 4. Activer Apple Pay si disponible
        // IMPORTANT: Configurer votre merchantId dans Info.plist si vous voulez Apple Pay
        // Ajouter : <key>com.apple.developer.in-app-payments</key>
        //           <array><string>merchant.com.yourapp.merchantid</string></array>
        if let merchantId = Bundle.main.object(forInfoDictionaryKey: "ApplePayMerchantId") as? String,
           !merchantId.isEmpty {
            configuration.applePay = .init(
                merchantId: merchantId,
                merchantCountryCode: "FR"
            )
            print("[StripeSubscriptionPaymentSheetView] Apple Pay activé avec merchantId: \(merchantId)")
        }
        
        // 5. Préremplir l'email si disponible
        if let userEmail = UserDefaults.standard.string(forKey: "user_email"), !userEmail.isEmpty {
            configuration.defaultBillingDetails.email = userEmail
            print("[StripeSubscriptionPaymentSheetView] Email prérempli: \(userEmail)")
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
        
        print("[StripeSubscriptionPaymentSheetView] makeUIViewController() - Fin")
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas de mise à jour nécessaire
    }
}




