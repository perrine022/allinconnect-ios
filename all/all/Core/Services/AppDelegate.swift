//
//  AppDelegate.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configurer Firebase
        FirebaseApp.configure()
        
        // Configurer Firebase Cloud Messaging
        Messaging.messaging().delegate = self
        
        // Configurer le delegate pour les notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - Universal Links / Deep Links
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Gérer les Universal Links
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        return handleUniversalLink(url: url)
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Gérer les deep links (URL scheme)
        return handleUniversalLink(url: url)
    }
    
    private func handleUniversalLink(url: URL) -> Bool {
        print("📱 Universal Link reçu: \(url.absoluteString)")
        
        // Vérifier si c'est un retour de paiement Stripe
        if url.absoluteString.contains("payment-success") || url.absoluteString.contains("payment_success") {
            // Extraire les paramètres de l'URL
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let sessionId = components?.queryItems?.first(where: { $0.name == "session_id" })?.value
            
            print("[AppDelegate] Paiement réussi - Session ID: \(sessionId ?? "N/A")")
            
            // Notifier que le paiement est terminé
            Task { @MainActor in
                // Attendre un peu pour que le backend traite le webhook
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                _ = await PaymentStatusManager.shared.checkPaymentStatus()
            }
            
            // Poster une notification pour afficher le résultat
            NotificationCenter.default.post(
                name: NSNotification.Name("StripePaymentReturned"),
                object: nil,
                userInfo: ["status": "success", "session_id": sessionId ?? ""]
            )
            
            return true
        } else if url.absoluteString.contains("payment-failed") || url.absoluteString.contains("payment_failed") {
            print("[AppDelegate] Paiement échoué")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("StripePaymentReturned"),
                object: nil,
                userInfo: ["status": "failed"]
            )
            
            return true
        }
        
        return false
    }
    
    // MARK: - Remote Notifications Registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Enregistrer le token avec Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Enregistrer aussi avec notre PushManager pour l'envoyer au backend
        Task { @MainActor in
            PushManager.shared.handleDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Afficher la notification même si l'app est au premier plan
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Gérer l'interaction avec la notification
        let userInfo = response.notification.request.content.userInfo
        
        // Vous pouvez extraire des données de la notification ici
        if let offerId = userInfo["offerId"] as? String {
            print("Notification tapped for offer: \(offerId)")
            // Naviguer vers l'offre si nécessaire
        }
        
        completionHandler()
    }
    
    // MARK: - Firebase Messaging Delegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Enregistrer le token FCM avec notre backend
        // Note: Firebase fournit le token FCM qui est différent du token APNS
        // Le backend doit accepter le token FCM pour les notifications Firebase
        if let fcmToken = fcmToken {
            Task { @MainActor in
                // Utiliser directement le token FCM (String) pour l'enregistrement
                // Le PushManager doit être adapté pour gérer les tokens FCM
                await PushManager.shared.registerFCMToken(fcmToken)
            }
        }
    }
}

