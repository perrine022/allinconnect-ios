# Guide d'intégration Stripe pour iOS

## Problème "Access Denied"

L'erreur "Access Denied" sur `buy.stripe.com` peut venir de :
1. **Payment Link inexistant** : Le lien n'existe pas dans votre Dashboard Stripe
2. **Restrictions** : Le Payment Link a des restrictions (pays, montant, etc.)
3. **Mode test/production** : Vous utilisez un lien test mais êtes en production (ou inversement)
4. **Lien expiré** : Le Payment Link a expiré

## Solution recommandée : Stripe Payment Sheet

**Pourquoi Payment Sheet est meilleur :**
- ✅ Reste dans l'app (pas de Safari)
- ✅ Support Apple Pay natif
- ✅ Interface native iOS
- ✅ Plus sécurisé (PCI compliant)
- ✅ Meilleure UX

## Installation

### Option 1 : Stripe Payment Sheet (Recommandé)

#### 1. Ajouter le SDK Stripe

Dans Xcode :
1. File → Add Package Dependencies
2. URL : `https://github.com/stripe/stripe-ios`
3. Version : `23.27.0` ou plus récent
4. Sélectionner `StripePaymentSheet`

#### 2. Configuration backend

Votre backend doit créer un endpoint :

```java
POST /api/v1/subscriptions/create-payment-intent
Body: { "planId": 3 }
Response: {
  "clientSecret": "pi_xxx_secret_xxx",
  "amount": 9.99,
  "currency": "eur"
}
```

Le backend doit :
1. Récupérer le plan depuis la base de données
2. Créer un Payment Intent avec Stripe API
3. Retourner le `clientSecret`

#### 3. Configuration dans l'app

1. Récupérer votre **clé publique** depuis Stripe Dashboard
2. La configurer dans `StripePaymentSheetView.swift` (ligne 20)

### Option 2 : Corriger Payment Links (Plus simple, moins optimal)

#### Vérifications dans Stripe Dashboard :

1. **Créer un Payment Link** :
   - Dashboard → Payment Links → Create payment link
   - Sélectionner le produit/prix
   - Configurer les options
   - **Important** : Désactiver toutes les restrictions

2. **Vérifier les paramètres** :
   - Mode : Test ou Live (selon votre environnement)
   - Restrictions géographiques : Aucune
   - Limites de montant : Aucune

3. **Récupérer l'URL** :
   - L'URL ressemble à : `https://buy.stripe.com/test_xxxxxxxxxxxxx`
   - La partager avec votre backend

#### Configuration backend :

Votre endpoint `/subscriptions/payment-link/{planId}` doit retourner l'URL complète du Payment Link.

## Recommandation

**Utilisez Stripe Payment Sheet** car :
- Meilleure expérience utilisateur
- Plus professionnel
- Support Apple Pay automatique
- Pas de problème "Access Denied"

Le code est déjà préparé pour utiliser Payment Sheet en priorité, avec fallback sur Payment Links si nécessaire.












