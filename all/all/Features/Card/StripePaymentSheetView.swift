//
//  StripePaymentSheetView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//
//  IMPORTANT: Pour utiliser Stripe Payment Sheet :
//  1. Dans Xcode : File → Add Package Dependencies
//  2. URL : https://github.com/stripe/stripe-ios
//  3. Version : Latest (23.x.x)
//  4. Sélectionner StripePaymentSheet
//  5. Décommentez le code ci-dessous et configurez votre clé publique
//

import SwiftUI
import UIKit

// Décommentez cette ligne une fois le SDK Stripe installé :
// import StripePaymentSheet

struct StripePaymentSheetView: UIViewControllerRepresentable {
    let clientSecret: String
    let onPaymentResult: (Bool, String?) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // TODO: Une fois le SDK Stripe installé, décommentez ce code :
        /*
        // 1. Récupérer votre clé publique depuis Stripe Dashboard
        //    Test : https://dashboard.stripe.com/test/apikeys
        //    Live : https://dashboard.stripe.com/apikeys
        StripeAPI.defaultPublishableKey = "pk_test_VOTRE_CLE_PUBLIQUE_ICI"
        
        // 2. Créer la configuration du Payment Sheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "All In Connect"
        
        // 3. Préremplir l'email si disponible
        if let userEmail = UserDefaults.standard.string(forKey: "user_email"), !userEmail.isEmpty {
            configuration.defaultBillingDetails.email = userEmail
        }
        
        // 4. Créer le Payment Sheet
        let paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        // 5. Présenter le Payment Sheet
        DispatchQueue.main.async {
            paymentSheet.present(from: viewController) { paymentResult in
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
        */
        
        // Pour l'instant, l'app utilisera Payment Links en fallback
        // Cette vue sera utilisée une fois le SDK installé
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas de mise à jour nécessaire
    }
}
