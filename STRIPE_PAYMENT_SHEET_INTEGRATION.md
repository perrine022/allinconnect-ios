# Intégration Stripe Payment Sheet - Guide de câblage iOS

## ✅ Câblage implémenté selon les instructions backend

Ce document décrit le câblage complet du Payment Sheet Stripe côté iOS, implémenté selon les spécifications du backend.

## 📋 Étapes d'intégration

### Étape A : Récupérer le clientSecret

**Endpoint appelé** : `POST /api/v1/subscriptions/create-payment-intent`

**Body** :
```json
{
  "planId": 3
}
```

**Réponse attendue** :
```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "amount": 9.99,
  "currency": "eur"
}
```

**Implémentation** : 
- Fichier : `StripePaymentViewModel.swift`
- Méthode : `processPaymentWithStripeSheet(plan:)`
- Service : `SubscriptionsAPIService.createPaymentIntent(planId:)`

### Étape B : Configurer le Payment Sheet

**SDK requis** : Stripe Payment Sheet iOS SDK

**Configuration** :
1. Installer le SDK : `https://github.com/stripe/stripe-ios`
2. Sélectionner `StripePaymentSheet` dans les dépendances
3. Décommenter le code dans `StripeSubscriptionPaymentSheetView.swift`
4. Configurer la clé publique Stripe dans le fichier

**Implémentation** :
- Fichier : `StripeSubscriptionPaymentSheetView.swift`
- Le composant utilise uniquement le `clientSecret` (Customer optionnel)

### Étape C : Vérification du statut après paiement

**Logique implémentée** :

1. **Après `paymentSheet.present` renvoie `.completed`** :
   - Attendre 0.5 seconde pour que le webhook soit traité
   - Appeler `GET /api/v1/users/me/light`
   - Vérifier le champ `isMember` ou `isCardActive`

2. **Si le statut n'est pas à jour** :
   - Attendre 1 seconde
   - Réessayer jusqu'à 2 fois maximum
   - Afficher un message de succès si confirmé, sinon un message d'avertissement

**Implémentation** :
- Fichier : `PaymentStatusManager.swift`
- Méthode : `checkPaymentStatus(maxRetries:)`
- Service : `ProfileAPIService.getUserLight()`

## 🔧 Fichiers modifiés

### 1. `StripePaymentViewModel.swift`
- ✅ Ajout de `processPaymentWithStripeSheet(plan:)` (Étape A + B)
- ✅ Ajout de `handlePaymentSheetResult(success:error:)` (Étape C)
- ✅ Gestion du Payment Sheet avec `showPaymentSheet` et `paymentIntentClientSecret`
- ✅ Affichage du message de succès avec `showSuccessMessage`

### 2. `PaymentStatusManager.swift`
- ✅ Amélioration de `checkPaymentStatus()` avec retry automatique
- ✅ Vérification du statut via `GET /api/v1/users/me/light`
- ✅ Retry jusqu'à 2 fois avec délai de 1 seconde entre chaque tentative

### 3. `StripeSubscriptionPaymentSheetView.swift`
- ✅ Simplification pour utiliser uniquement le `clientSecret`
- ✅ Customer ID et Ephemeral Key rendus optionnels
- ✅ Support des paiements uniques sans Customer

### 4. `StripePaymentView.swift`
- ✅ Modification du bouton "Payer" pour utiliser le Payment Sheet
- ✅ Ajout du `.sheet` pour présenter le Payment Sheet
- ✅ Ajout de l'alerte de succès après confirmation du statut

## 🚀 Utilisation

### Pour le développeur iOS :

1. **Installer le SDK Stripe** :
   ```
   File → Add Package Dependencies
   URL: https://github.com/stripe/stripe-ios
   Version: Latest
   Sélectionner: StripePaymentSheet
   ```

2. **Configurer la clé publique Stripe** :
   - Ouvrir `StripeSubscriptionPaymentSheetView.swift`
   - Décommenter l'import `StripePaymentSheet`
   - Remplacer `"pk_test_VOTRE_CLE_PUBLIQUE_ICI"` par votre clé publique
   - Clé test : https://dashboard.stripe.com/test/apikeys
   - Clé live : https://dashboard.stripe.com/apikeys

3. **Activer le Payment Sheet** :
   - Dans `StripePaymentSheetPlaceholderView`, remplacer le placeholder par :
   ```swift
   StripeSubscriptionPaymentSheetView(
       paymentIntentClientSecret: clientSecret,
       onPaymentResult: onPaymentResult
   )
   ```

4. **Tester le flux complet** :
   - Sélectionner un plan d'abonnement
   - Cliquer sur "Payer"
   - Le Payment Sheet s'ouvre automatiquement
   - Après paiement réussi, le statut est vérifié automatiquement
   - Un message de succès s'affiche si le statut premium est confirmé

## 📝 Flux complet

```
1. Utilisateur sélectionne un plan
   ↓
2. Clic sur "Payer"
   ↓
3. Étape A : Appel POST /api/v1/subscriptions/create-payment-intent
   ↓
4. Récupération du clientSecret
   ↓
5. Étape B : Présentation du Payment Sheet avec le clientSecret
   ↓
6. Utilisateur complète le paiement
   ↓
7. Payment Sheet renvoie .completed
   ↓
8. Étape C : Attente 0.5s pour le webhook
   ↓
9. Appel GET /api/v1/users/me/light
   ↓
10. Vérification de isMember ou isCardActive
   ↓
11. Si non confirmé : Retry (max 2 fois) avec délai de 1s
   ↓
12. Affichage du message de succès ou d'avertissement
```

## ⚠️ Notes importantes

- **Webhooks Stripe** : Le backend doit écouter les webhooks Stripe pour activer le statut premium
- **Délai de traitement** : Le webhook peut prendre quelques millisecondes, d'où le retry automatique
- **Customer optionnel** : Pour les paiements uniques, le Customer Stripe n'est pas nécessaire
- **Apple Pay** : Configurer le `merchantId` dans `Info.plist` pour activer Apple Pay

## 🔍 Debugging

Les logs suivants sont disponibles pour le debugging :

- `[StripePaymentViewModel]` : Logs du ViewModel
- `[PaymentStatusManager]` : Logs de vérification du statut
- `[StripeSubscriptionPaymentSheetView]` : Logs du Payment Sheet

## ✅ Checklist d'activation

- [ ] SDK Stripe installé
- [ ] Clé publique Stripe configurée
- [ ] Code décommenté dans `StripeSubscriptionPaymentSheetView.swift`
- [ ] Placeholder remplacé dans `StripePaymentSheetPlaceholderView`
- [ ] Merchant ID Apple Pay configuré (optionnel)
- [ ] Backend configuré pour écouter les webhooks Stripe
- [ ] Endpoint `/api/v1/subscriptions/create-payment-intent` fonctionnel
- [ ] Endpoint `/api/v1/users/me/light` retourne `isMember` ou `isCardActive`












