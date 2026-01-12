# Intégration Stripe Payment Sheet pour iOS

## Problème actuel
L'erreur "Access Denied" sur Stripe Payment Links peut venir de :
- Payment Link mal configuré dans le Dashboard Stripe
- Restrictions géographiques ou de compte
- Payment Link en mode test mais accès depuis production

## Solution recommandée : Stripe Payment Sheet

**Avantages :**
- ✅ Reste dans l'app (pas besoin de Safari)
- ✅ Support Apple Pay natif
- ✅ Interface native iOS
- ✅ Plus sécurisé
- ✅ Meilleure UX

## Étapes d'installation

### 1. Ajouter le SDK Stripe iOS

Dans Xcode :
1. File → Add Package Dependencies
2. URL : `https://github.com/stripe/stripe-ios`
3. Version : Latest (23.x.x)
4. Ajouter `StripePaymentSheet` à votre target

### 2. Configuration backend

Votre backend doit créer un endpoint qui génère un Payment Intent :

```java
// Endpoint: POST /api/v1/subscriptions/create-payment-intent
// Body: { "planId": 3 }
// Response: { "clientSecret": "pi_xxx_secret_xxx", "amount": 9.99, "currency": "eur" }
```

### 3. Configuration dans l'app

1. Récupérer votre clé publique Stripe depuis le Dashboard
2. La configurer dans `StripePaymentSheetView.swift`

## Alternative simple : Corriger Payment Links

Si vous préférez garder Payment Links, vérifiez :
1. Le Payment Link existe dans votre Dashboard Stripe
2. Il n'y a pas de restrictions activées
3. Vous utilisez la bonne clé (test vs production)
















