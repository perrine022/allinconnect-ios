# 📋 Audit des Notifications Push FCM - iOS SwiftUI

**Date:** 2026-01-08  
**Statut:** ✅ Conforme aux bonnes pratiques (après corrections)

---

## ✅ Points Conformes (Déjà en place)

### 1. Architecture de base
- ✅ **Firebase configuré** dans `AppDelegate.didFinishLaunchingWithOptions`
- ✅ **MessagingDelegate** et **UNUserNotificationCenterDelegate** implémentés
- ✅ **GoogleService-Info.plist** présent dans le projet
- ✅ **@UIApplicationDelegateAdaptor** utilisé dans `allApp.swift`

### 2. Gestion des tokens
- ✅ **Token APNs** passé à Firebase via `Messaging.messaging().apnsToken`
- ✅ **Token FCM** récupéré via `messaging(_:didReceiveRegistrationToken:)`
- ✅ **Envoi au backend** via `PushManager.registerTokenWithBackend()`
- ✅ **Stockage local** des tokens (FCM et APNs)
- ✅ **Enregistrement après login** automatique

### 3. Affichage des notifications
- ✅ **Notifications en foreground** affichées (banner/sound/badge)
- ✅ **Notifications en background** gérées correctement

### 4. Navigation depuis les notifications
- ✅ **NotificationCenter** utilisé pour le routing
- ✅ **Navigation vers offres/événements** fonctionnelle
- ✅ **Navigation vers professionnels** fonctionnelle
- ✅ **Support des formats Int et String** pour les IDs

---

## 🔧 Améliorations Apportées (Conformité au guide)

### 1. ✅ Utilisation de async/await (iOS 15+)
**Avant:** Utilisation de `completionHandler` (ancienne API)
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
```

**Après:** Utilisation de `async/await` (moderne, recommandée)
```swift
@available(iOS 15.0, *)
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions
```

**Note:** Fallback pour iOS < 15 maintenu pour compatibilité.

### 2. ✅ Ajout du deviceId dans l'enregistrement
**Avant:** Pas de deviceId envoyé au backend
```swift
let requestBody: [String: Any] = [
    "token": token,
    "platform": "IOS",
    "environment": environment
]
```

**Après:** deviceId ajouté (recommandé par le guide)
```swift
let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
let requestBody: [String: Any] = [
    "token": token,
    "platform": "IOS",
    "environment": environment,
    "deviceId": deviceId
]
```

### 3. ✅ Support du format recommandé "screen" + "entityId"
**Avant:** Support uniquement des formats legacy (`offerId`, `professionalId`)

**Après:** Support du format recommandé + rétrocompatibilité
```swift
// Format recommandé (prioritaire)
if let screen = userInfo["screen"] as? String,
   let entityId = userInfo["entityId"] as? String {
    switch screen {
    case "offer_detail", "event_detail":
        // Navigation vers offre
    case "professional_detail", "partner_detail":
        // Navigation vers professionnel
    case "order_detail":
        // TODO: Implémenter si nécessaire
    case "message_thread":
        // TODO: Implémenter si nécessaire
    }
}

// Format legacy (rétrocompatibilité)
if let offerId = userInfo["offerId"] as? Int {
    // Navigation vers offre
}
```

### 4. ✅ Demande de permission dans AppDelegate
**Avant:** Demande uniquement dans `AppContentView`

**Après:** Demande dans `AppDelegate.didFinishLaunchingWithOptions` (recommandé)
```swift
private func requestNotificationPermission(_ application: UIApplication) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if granted {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
}
```

**Note:** La demande dans `AppContentView` reste pour garantir la permission si l'app démarre sans AppDelegate.

---

## 📊 Comparaison avec le Guide Fourni

| Point du Guide | Statut | Notes |
|----------------|--------|-------|
| FirebaseApp.configure() | ✅ | Fait dans AppDelegate |
| Messaging.messaging().delegate = self | ✅ | Fait |
| UNUserNotificationCenter.current().delegate = self | ✅ | Fait |
| Permission demandée | ✅ | Fait dans AppDelegate |
| APNs token → Firebase | ✅ | `Messaging.messaging().apnsToken = deviceToken` |
| FCM token récupéré | ✅ | `messaging(_:didReceiveRegistrationToken:)` |
| Token envoyé au backend | ✅ | Via PushManager |
| deviceId inclus | ✅ | **Ajouté** |
| Format "screen" + "entityId" | ✅ | **Ajouté** (avec rétrocompatibilité) |
| async/await pour willPresent | ✅ | **Ajouté** (iOS 15+) |
| async/await pour didReceive | ✅ | **Ajouté** (iOS 15+) |
| Navigation via NotificationCenter | ✅ | Fait |
| Affichage en foreground | ✅ | Banner/sound/badge |

---

## 🎯 Format de Payload Recommandé (Backend)

Le backend peut maintenant envoyer deux formats :

### Format Moderne (Recommandé)
```json
{
  "aps": {
    "alert": {
      "title": "Nouvelle offre",
      "body": "Découvrez notre nouvelle promotion !"
    },
    "sound": "default",
    "badge": 1
  },
  "screen": "offer_detail",
  "entityId": "123",
  "type": "OFFER"
}
```

**Screens supportés:**
- `"offer_detail"` ou `"event_detail"` → Navigation vers `OfferDetailView`
- `"professional_detail"` ou `"partner_detail"` → Navigation vers `PartnerDetailView`
- `"order_detail"` → TODO: À implémenter si nécessaire
- `"message_thread"` → TODO: À implémenter si nécessaire

### Format Legacy (Rétrocompatibilité)
```json
{
  "aps": { ... },
  "offerId": 123,
  "type": "OFFER"
}
```
ou
```json
{
  "aps": { ... },
  "professionalId": 456
}
```

**Note:** Les deux formats sont supportés pour garantir la compatibilité avec le backend existant.

---

## 🔍 Points d'Attention

### 1. Double demande de permission
La permission est demandée à la fois dans :
- `AppDelegate.didFinishLaunchingWithOptions` (recommandé)
- `AppContentView.initializePushNotifications()` (sécurité)

**Impact:** iOS gère automatiquement les demandes multiples (ne redemande pas si déjà accordée).

### 2. Navigation vers OrderDetailView / MessageThreadView
Ces écrans ne sont pas encore implémentés. Le code est prêt pour les supporter quand ils seront créés.

### 3. Tests sur simulateur
⚠️ **Important:** Les notifications push ne fonctionnent **pas** sur le simulateur iOS. Il faut tester sur un **device réel**.

---

## ✅ Conclusion

L'implémentation est maintenant **conforme aux bonnes pratiques** recommandées :

1. ✅ Utilisation de `async/await` pour les delegates (iOS 15+)
2. ✅ `deviceId` inclus dans l'enregistrement du token
3. ✅ Support du format recommandé `screen` + `entityId`
4. ✅ Demande de permission dans `AppDelegate`
5. ✅ Rétrocompatibilité maintenue avec les formats existants

**Tous les points du guide ont été implémentés ou étaient déjà en place.**

---

## 📝 Fichiers Modifiés

1. **`all/all/Core/Services/AppDelegate.swift`**
   - Ajout de `requestNotificationPermission()`
   - Migration vers `async/await` pour `willPresent` et `didReceive`
   - Simplification de la gestion du payload (passage direct à TabBarView)

2. **`all/all/Core/Services/PushManager.swift`**
   - Ajout de `deviceId` dans `registerTokenWithBackend()`

3. **`all/all/Core/Components/TabBarView.swift`**
   - Support du format `screen` + `entityId`
   - Maintien de la rétrocompatibilité avec les formats legacy

---

**Statut Final:** ✅ **CONFORME AUX BONNES PRATIQUES**

