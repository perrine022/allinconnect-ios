# Configuration du retour de paiement Stripe

## Vue d'ensemble

Pour que l'utilisateur revienne automatiquement dans l'app après le paiement Stripe et que l'app sache si le paiement a réussi, il faut configurer les **Universal Links** et les **URLs de retour** dans Stripe.

## ⚠️ IMPORTANT : Étapes à suivre

### 1. Dans Stripe Dashboard (OBLIGATOIRE)

1. Allez dans **Stripe Dashboard** → **Payment Links** → Sélectionnez votre lien (`test_9B614mbv4cH93KZ0cP87K01`)
2. Dans la section **"After payment"** :
   - **Success URL** : `https://votredomaine.com/payment-success?session_id={CHECKOUT_SESSION_ID}`
   - **Cancel URL** : `https://votredomaine.com/payment-failed`
   
   **Remplacez `votredomaine.com` par votre domaine réel** (ex: `allinconnect.com`)

### 2. Sur votre serveur web (OBLIGATOIRE)

Créez le fichier `.well-known/apple-app-site-association` à la racine de votre domaine (accessible en HTTPS) :

**URL complète** : `https://votredomaine.com/.well-known/apple-app-site-association`

**Contenu** (remplacez TEAM_ID par votre Team ID Apple) :
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.allinconnect.all",
        "paths": [
          "/payment-success*",
          "/payment-failed*"
        ]
      }
    ]
  }
}
```

**Important** :
- Le fichier doit être en JSON valide (pas de commentaires)
- Le Content-Type doit être `application/json`
- Accessible sans authentification
- En HTTPS uniquement

### 3. Dans Xcode (OBLIGATOIRE)

1. Ouvrez votre projet dans Xcode
2. Sélectionnez le target de l'app
3. Allez dans **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Ajoutez **Associated Domains**
6. Ajoutez : `applinks:votredomaine.com` (remplacez par votre domaine)

### 4. Comment ça fonctionne

1. L'utilisateur clique sur "Payer" dans l'app
2. Safari s'ouvre avec le lien Stripe
3. L'utilisateur complète le paiement
4. Stripe redirige vers `https://votredomaine.com/payment-success?session_id=xxx`
5. iOS détecte l'Universal Link et ouvre l'app automatiquement
6. `AppDelegate` intercepte l'URL et vérifie le statut du paiement
7. L'app affiche le résultat (succès/échec)

## Étapes de configuration

### 1. Configuration dans Stripe Dashboard

1. Allez dans **Stripe Dashboard** → **Payment Links** → Sélectionnez votre lien
2. Dans la section **"After payment"** :
   - **Success URL** : `https://votredomaine.com/payment-success?session_id={CHECKOUT_SESSION_ID}`
   - **Cancel URL** : `https://votredomaine.com/payment-failed`

   Remplacez `votredomaine.com` par votre domaine réel.

### 2. Configuration du serveur web (Backend)

Vous devez créer deux pages sur votre serveur web :

#### Page de succès : `/payment-success`
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Paiement réussi</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- Universal Link pour iOS -->
    <meta name="apple-itunes-app" content="app-id=VOTRE_APP_ID">
</head>
<body>
    <h1>Paiement réussi !</h1>
    <p>Vous allez être redirigé vers l'application...</p>
    <script>
        // Rediriger vers l'app après 2 secondes
        setTimeout(function() {
            // Essayer d'ouvrir l'app via Universal Link
            window.location.href = "https://votredomaine.com/payment-success?session_id=" + new URLSearchParams(window.location.search).get('session_id');
        }, 2000);
    </script>
</body>
</html>
```

#### Page d'échec : `/payment-failed`
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Paiement échoué</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>Paiement échoué</h1>
    <p>Vous allez être redirigé vers l'application...</p>
    <script>
        setTimeout(function() {
            window.location.href = "https://votredomaine.com/payment-failed";
        }, 2000);
    </script>
</body>
</html>
```

### 3. Configuration Universal Links (iOS)

#### 3.1. Créer le fichier `apple-app-site-association`

Sur votre serveur web, créez le fichier `.well-known/apple-app-site-association` à la racine :

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.allinconnect.all",
        "paths": [
          "/payment-success*",
          "/payment-failed*"
        ]
      }
    ]
  }
}
```

Remplacez `TEAM_ID` par votre Team ID Apple (visible dans Xcode → Signing & Capabilities).

**Important** :
- Le fichier doit être accessible via HTTPS
- Le fichier doit être en JSON valide (pas de commentaires)
- Le Content-Type doit être `application/json`

#### 3.2. Configurer dans Xcode

1. Ouvrez votre projet dans Xcode
2. Sélectionnez le target de l'app
3. Allez dans **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Ajoutez **Associated Domains**
6. Ajoutez : `applinks:votredomaine.com` (remplacez par votre domaine)

#### 3.3. Vérifier le fichier Info.plist

Assurez-vous que le fichier `Info.plist` contient :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>allinconnect</string>
        </array>
    </dict>
</array>
```

### 4. Configuration dans le code iOS

Le code iOS est déjà configuré dans :
- `AppDelegate.swift` : Gère les Universal Links
- `PaymentStatusManager.swift` : Vérifie le statut du paiement
- `StripePaymentView.swift` : Ouvre le lien Stripe

### 5. Vérification du statut du paiement

L'app vérifie automatiquement le statut du paiement via :
1. **Universal Link** : Quand Stripe redirige vers votre domaine
2. **API Backend** : Vérification de `isCardActive` et des paiements récents
3. **Notification** : `PaymentSuccess` ou `PaymentFailed` est postée

### 6. Webhook Stripe (Recommandé)

Pour une vérification plus fiable, configurez un webhook Stripe :

1. **Stripe Dashboard** → **Developers** → **Webhooks**
2. Ajoutez un endpoint : `https://votredomaine.com/api/stripe/webhook`
3. Sélectionnez les événements :
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`

4. Dans votre backend, traitez le webhook et mettez à jour le statut de l'abonnement
5. L'app vérifiera ensuite le statut via l'API `/users/me/light`

## Test

1. **Test en développement** :
   - Utilisez le lien Stripe test : `https://buy.stripe.com/test_...`
   - Utilisez une carte de test : `4242 4242 4242 4242`

2. **Vérifier les Universal Links** :
   - Ouvrez Safari sur votre iPhone
   - Tapez : `https://votredomaine.com/payment-success?session_id=test123`
   - L'app devrait s'ouvrir automatiquement

3. **Vérifier le retour depuis Stripe** :
   - Lancez un paiement depuis l'app
   - Complétez le paiement dans Stripe
   - L'app devrait se rouvrir automatiquement
   - Le statut du paiement devrait être vérifié

## Dépannage

- **L'app ne s'ouvre pas** : Vérifiez que le fichier `apple-app-site-association` est accessible et valide
- **Le statut n'est pas détecté** : Vérifiez que le backend traite bien les webhooks Stripe
- **Universal Links ne fonctionnent pas** : Vérifiez les Associated Domains dans Xcode

## Notes importantes

- Les Universal Links fonctionnent uniquement en production (pas en simulateur)
- Le domaine doit être en HTTPS
- Le fichier `apple-app-site-association` doit être accessible sans authentification
- Le webhook Stripe est la méthode la plus fiable pour confirmer un paiement

