# Guide d'implémentation - Abonnement mensuel Stripe iOS

## Vue d'ensemble

Cette implémentation permet de gérer des abonnements mensuels Stripe dans l'application iOS en utilisant **Stripe PaymentSheet** (interface native iOS).

## Architecture

### Composants principaux

1. **BillingAPIService** - Service API pour communiquer avec le backend
2. **BillingViewModel** - ViewModel pour gérer la logique métier
3. **SubscribeView** - Écran d'abonnement
4. **ManageSubscriptionView** - Écran de gestion de l'abonnement
5. **StripeSubscriptionPaymentSheetView** - Wrapper SwiftUI pour PaymentSheet

## Installation

### 1. Installer le SDK Stripe iOS

Dans Xcode :

1. **File → Add Package Dependencies**
2. URL : `https://github.com/stripe/stripe-ios`
3. Version : Latest (23.x.x ou supérieur)
4. Sélectionner **StripePaymentSheet**
5. Cliquer sur **Add Package**

### 2. Configurer la clé publique Stripe

1. Récupérer votre clé publique depuis Stripe Dashboard :
   - **Test** : https://dashboard.stripe.com/test/apikeys
   - **Live** : https://dashboard.stripe.com/apikeys

2. Dans `StripeSubscriptionPaymentSheetView.swift`, décommenter et remplacer :
   ```swift
   StripeAPI.defaultPublishableKey = "pk_test_VOTRE_CLE_PUBLIQUE_ICI"
   ```

### 3. Configurer Apple Pay (optionnel mais recommandé)

#### 3.1. Dans Stripe Dashboard

1. Aller dans **Settings → Payment methods**
2. Activer **Apple Pay**
3. Configurer votre domaine et certificat

#### 3.2. Dans Xcode

1. Ouvrir `Info.plist`
2. Ajouter la clé `com.apple.developer.in-app-payments` :
   ```xml
   <key>com.apple.developer.in-app-payments</key>
   <array>
       <string>merchant.com.yourapp.merchantid</string>
   </array>
   ```
   ⚠️ Remplacer `merchant.com.yourapp.merchantid` par votre Merchant ID Apple Pay

3. Dans `StripeSubscriptionPaymentSheetView.swift`, le code détectera automatiquement le Merchant ID depuis `Info.plist`

#### 3.3. Dans Apple Developer Portal

1. Aller dans **Certificates, Identifiers & Profiles**
2. Créer un **Merchant ID** si nécessaire
3. Configurer les certificats Apple Pay

## Configuration Backend

### ⚠️ Note importante sur les endpoints

Le backend indique les endpoints comme `/api/billing/...`. Si votre baseURL dans `APIService.swift` contient déjà `/api/v1`, les endpoints relatifs `/billing/...` donneront `/api/v1/billing/...`.

**Si le backend utilise `/api/billing/...` (sans `/v1`)** :
- Option 1 : Modifier temporairement le baseURL pour billing uniquement
- Option 2 : Vérifier avec le backend si les endpoints sont bien `/api/v1/billing/...` ou `/api/billing/...`

### Endpoints requis

#### 1. POST `/api/billing/subscription/start`

Démarre le processus d'abonnement.

**Request** : Aucun body (utilise le JWT pour identifier l'utilisateur)

**Response** :
```json
{
  "customerId": "cus_xxxxx",
  "ephemeralKeySecret": "ek_test_xxxxx",
  "paymentIntentClientSecret": "pi_xxxxx_secret_xxxxx",
  "subscriptionId": "sub_xxxxx"
}
```

**Logique backend** :
1. Récupérer l'utilisateur depuis le JWT
2. Créer ou récupérer le Customer Stripe
3. Créer un Payment Intent avec `setup_future_usage: 'off_session'`
4. Créer une Ephemeral Key pour le Customer
5. Créer une Subscription Stripe (en statut `incomplete`)
6. Retourner les données nécessaires

#### 2. GET `/api/billing/subscription/status`

Récupère le statut de l'abonnement.

**Request** : Aucun body (utilise le JWT)

**Response** :
```json
{
  "premiumEnabled": true,
  "subscriptionStatus": "ACTIVE",
  "currentPeriodEnd": "2024-12-31T23:59:59Z"
}
```

**Logique backend** :
1. Récupérer l'utilisateur depuis le JWT
2. Récupérer la Subscription Stripe associée
3. Vérifier le statut (`ACTIVE`, `CANCELED`, `PAST_DUE`, etc.)
4. Retourner `premiumEnabled: true` si `subscriptionStatus === 'ACTIVE'`

#### 3. POST `/api/billing/portal`

Crée une session pour le Customer Portal Stripe.

**Request** : Aucun body (utilise le JWT)

**Response** :
```json
{
  "url": "https://billing.stripe.com/p/session/xxxxx"
}
```

**Logique backend** :
1. Récupérer l'utilisateur depuis le JWT
2. Récupérer le Customer Stripe ID
3. Créer une session Customer Portal avec Stripe API
4. Retourner l'URL de la session

### Webhooks Stripe (CRITIQUE)

⚠️ **L'activation premium se fait UNIQUEMENT via webhooks**. Le front-end ne modifie jamais l'état premium directement.

#### Webhooks à écouter

1. **`invoice.paid`** - Quand un paiement d'abonnement réussit
2. **`customer.subscription.updated`** - Quand une subscription change de statut
3. **`customer.subscription.deleted`** - Quand une subscription est annulée

#### Logique webhook (exemple Java/Spring)

```java
@PostMapping("/webhooks/stripe")
public ResponseEntity<String> handleStripeWebhook(@RequestBody String payload, 
                                                   @RequestHeader("Stripe-Signature") String sigHeader) {
    Event event = Webhook.constructEvent(payload, sigHeader, webhookSecret);
    
    switch (event.getType()) {
        case "invoice.paid":
            Invoice invoice = (Invoice) event.getDataObjectDeserializer().getObject().orElse(null);
            if (invoice != null && invoice.getSubscription() != null) {
                // Activer premium pour l'utilisateur
                String customerId = invoice.getCustomer();
                activatePremiumForCustomer(customerId);
            }
            break;
            
        case "customer.subscription.updated":
        case "customer.subscription.deleted":
            Subscription subscription = (Subscription) event.getDataObjectDeserializer().getObject().orElse(null);
            if (subscription != null) {
                String customerId = subscription.getCustomer();
                if ("active".equals(subscription.getStatus())) {
                    activatePremiumForCustomer(customerId);
                } else {
                    deactivatePremiumForCustomer(customerId);
                }
            }
            break;
    }
    
    return ResponseEntity.ok().build();
}
```

#### ⚠️ Idempotence obligatoire

Les webhooks peuvent être appelés plusieurs fois. Utiliser un système d'idempotence :

```java
// Exemple avec un cache Redis ou base de données
String eventId = event.getId();
if (isEventProcessed(eventId)) {
    return ResponseEntity.ok("Event already processed");
}
markEventAsProcessed(eventId);

// Traiter l'événement...
```

## Flux utilisateur

### 1. Abonnement

1. Utilisateur clique sur "Commencer l'abonnement mensuel"
2. App appelle `POST /api/billing/subscription/start`
3. Backend crée Customer, Payment Intent, Subscription
4. App reçoit `customerId`, `ephemeralKeySecret`, `paymentIntentClientSecret`, `subscriptionId`
5. App affiche PaymentSheet avec ces données
6. Utilisateur complète le paiement
7. Sur succès : App appelle `GET /api/billing/subscription/status` (après fermeture du PaymentSheet)
8. Backend vérifie le statut (peut être encore `incomplete` si webhook pas encore reçu)
9. Webhook `invoice.paid` active premium côté backend automatiquement
10. Prochain appel à `/status` retourne `premiumEnabled: true`

### 2. Gestion de l'abonnement

1. Utilisateur clique sur "Gérer la facturation"
2. App appelle `POST /api/billing/portal`
3. Backend crée une session Customer Portal
4. App ouvre l'URL dans SafariViewController
5. Utilisateur peut modifier/canceler depuis Stripe

## Sécurité

### ⚠️ Ne JAMAIS stocker de secrets localement

- ❌ Ne pas stocker `ephemeralKeySecret`
- ❌ Ne pas stocker `paymentIntentClientSecret`
- ❌ Ne pas stocker de clés API Stripe

### ✅ Stockage autorisé

- ✅ Cache optionnel `premiumEnabled` (UserDefaults)
- ⚠️ La source de vérité reste toujours `GET /api/billing/subscription/status`

## Gestion des erreurs

### Erreurs réseau

L'app affiche des messages user-friendly :
- "Erreur de connexion. Vérifiez votre connexion internet."
- "Impossible de démarrer l'abonnement. Veuillez réessayer."

### Erreurs de paiement

PaymentSheet gère automatiquement :
- Carte refusée
- Paiement annulé
- Erreur de réseau

L'app affiche le message d'erreur retourné par Stripe.

## Tests

### Mode Test Stripe

1. Utiliser des cartes de test : https://stripe.com/docs/testing
2. Exemple : `4242 4242 4242 4242` (expire n'importe quand, CVV n'importe quoi)

### Vérifications

1. ✅ PaymentSheet s'affiche correctement
2. ✅ Apple Pay apparaît si configuré
3. ✅ Paiement test réussit
4. ✅ Webhook active premium
5. ✅ `/status` retourne `premiumEnabled: true`
6. ✅ Customer Portal s'ouvre correctement

## Dépannage

### PaymentSheet ne s'affiche pas

1. Vérifier que le SDK Stripe est bien installé
2. Vérifier que `StripeAPI.defaultPublishableKey` est configuré
3. Vérifier les logs : `[StripeSubscriptionPaymentSheetView]`

### Apple Pay ne s'affiche pas

1. Vérifier que Merchant ID est configuré dans `Info.plist`
2. Vérifier que Apple Pay est activé dans Stripe Dashboard
3. Vérifier que l'appareil supporte Apple Pay

### Premium ne s'active pas

1. Vérifier que les webhooks sont bien configurés
2. Vérifier les logs webhooks dans Stripe Dashboard
3. Vérifier que l'idempotence fonctionne
4. Vérifier que `GET /status` est appelé après le paiement

## Notes importantes

### ⚠️ Ne pas utiliser Stripe Checkout

Cette implémentation utilise **PaymentSheet** (interface native iOS), pas Checkout (web).

### ⚠️ Le priceId vient uniquement du backend

Le front-end ne connaît jamais le `priceId` Stripe. Le backend le gère automatiquement.

### ⚠️ Activation premium uniquement via webhooks

Le front-end ne modifie jamais directement l'état premium. Il lit uniquement depuis `/status`.

### ⚠️ Idempotence webhook obligatoire

Les webhooks peuvent être appelés plusieurs fois. Implémenter un système d'idempotence.

## Support

Pour toute question :
- Documentation Stripe : https://stripe.com/docs/payments/accept-a-payment?platform=ios
- Documentation PaymentSheet : https://stripe.com/docs/payments/payment-sheet

