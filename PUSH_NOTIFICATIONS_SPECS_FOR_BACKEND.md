# 📱 Spécifications Techniques - Notifications Push iOS

**Document pour le développeur Backend**  
**Date:** Décembre 2025  
**Application:** ALL IN Connect iOS

---

## 📋 Table des matières

1. [Enregistrement du Token Push](#1-enregistrement-du-token-push)
2. [Gestion des Préférences de Notifications](#2-gestion-des-préférences-de-notifications)
3. [Format des Notifications Push](#3-format-des-notifications-push)
4. [Navigation Automatique](#4-navigation-automatique)
5. [Environnements (SANDBOX/PRODUCTION)](#5-environnements-sandboxproduction)
6. [Exemples de Requêtes](#6-exemples-de-requêtes)

---

## 1. Enregistrement du Token Push

### 1.1 Endpoint

```
POST /api/v1/push/register
```

### 1.2 Headers Requis

```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
Accept: application/json
```

### 1.3 Body (JSON)

```json
{
  "token": "LE_TOKEN_APNS_ICI",
  "platform": "IOS",
  "environment": "SANDBOX"  // ou "PRODUCTION"
}
```

### 1.4 Détails Techniques

- **Token APNs**: Le token est envoyé comme une chaîne hexadécimale (ex: `"a1b2c3d4e5f6..."`)
- **Platform**: Toujours `"IOS"` pour cette application
- **Environment**: 
  - `"SANDBOX"` en mode DEBUG (développement/test)
  - `"PRODUCTION"` en mode RELEASE (production)
- **Authentification**: Le token JWT de l'utilisateur est requis dans le header `Authorization`

### 1.5 Quand le Token est Envoyé

Le front-end envoie automatiquement le token dans ces cas :
1. **Au démarrage de l'app** si l'utilisateur est déjà connecté
2. **Après la connexion** de l'utilisateur
3. **Quand le token change** (iOS peut régénérer le token)

### 1.6 Réponse Attendue

- **Status Code**: `200` ou `201` pour succès
- **Body**: Peut être vide ou contenir un message de confirmation

### 1.7 Support Firebase Cloud Messaging (FCM)

Le front-end supporte aussi Firebase Cloud Messaging. Si Firebase est configuré, le token FCM peut être envoyé à la place du token APNs. Le backend doit accepter les deux types de tokens.

---

## 2. Gestion des Préférences de Notifications

### 2.1 Récupérer les Préférences

**Endpoint:**
```
GET /api/v1/notification-preferences
```

**Headers:**
```
Authorization: Bearer {JWT_TOKEN}
Accept: application/json
```

**Réponse Attendue (JSON):**
```json
{
  "notifyNewOffers": true,
  "notifyNewProNearby": true,
  "notifyLocalEvents": true,
  "notificationRadius": 10,
  "preferredCategories": [
    "SANTE_BIEN_ETRE",
    "BEAUTE_ESTHETIQUE",
    "FOOD_PLAISIRS",
    "LOISIRS_DIVERTISSEMENTS",
    "SERVICE_PRATIQUES",
    "ENTRE_PROS"
  ]
}
```

### 2.2 Sauvegarder les Préférences

**Endpoint:**
```
PUT /api/v1/notification-preferences
```

**Headers:**
```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
Accept: application/json
```

**Body (JSON):**
```json
{
  "notifyNewOffers": true,
  "notifyNewProNearby": true,
  "notifyLocalEvents": true,
  "notificationRadius": 10,
  "preferredCategories": [
    "SANTE_BIEN_ETRE",
    "BEAUTE_ESTHETIQUE",
    "FOOD_PLAISIRS"
  ]
}
```

### 2.3 Détails des Champs

| Champ | Type | Description |
|-------|------|-------------|
| `notifyNewOffers` | `Boolean` | Notifier pour les nouvelles offres |
| `notifyNewProNearby` | `Boolean` | Notifier pour les nouveaux professionnels à proximité |
| `notifyLocalEvents` | `Boolean` | Notifier pour les événements locaux |
| `notificationRadius` | `Integer` | Rayon en kilomètres (5-50 km) |
| `preferredCategories` | `Array<String>` | Liste des catégories préférées (voir ci-dessous) |

### 2.4 Catégories Disponibles

Les catégories doivent correspondre exactement à ces valeurs (en majuscules avec underscores) :

- `"SANTE_BIEN_ETRE"` - Santé & bien être
- `"BEAUTE_ESTHETIQUE"` - Beauté & Esthétique
- `"FOOD_PLAISIRS"` - Food & plaisirs gourmands
- `"LOISIRS_DIVERTISSEMENTS"` - Loisirs & Divertissements
- `"SERVICE_PRATIQUES"` - Service & pratiques
- `"ENTRE_PROS"` - Entre pros

### 2.5 Comportement du Front-end

- **Sauvegarde automatique**: Le front-end sauvegarde automatiquement les préférences à chaque modification (avec un debounce de 300ms pour éviter trop d'appels)
- **Chargement au démarrage**: Les préférences sont chargées automatiquement au démarrage de l'app
- **Synchronisation**: Les préférences sont synchronisées avec le backend en temps réel

---

## 3. Format des Notifications Push

### 3.1 Structure Générale du Payload

Le backend doit envoyer des notifications avec le format APNs standard :

```json
{
  "aps": {
    "alert": {
      "title": "Titre de la notification",
      "body": "Message de la notification"
    },
    "sound": "default",
    "badge": 1
  },
  "offerId": 123,              // Pour une offre (optionnel)
  "professionalId": 456,       // Pour un professionnel (optionnel)
  "type": "EVENT"              // Optionnel, pour distinguer les événements
}
```

### 3.2 Types de Notifications Supportées

#### A. Notification pour une Offre

```json
{
  "aps": {
    "alert": {
      "title": "Nouvelle offre",
      "body": "Découvre cette nouvelle offre près de chez toi !"
    },
    "sound": "default",
    "badge": 1
  },
  "offerId": 123
}
```

**Comportement Front-end:**
- Affiche la notification
- Quand l'utilisateur tape dessus, navigue vers `OfferDetailView(offerId: 123)`
- Change automatiquement vers l'onglet "Offres"

#### B. Notification pour un Événement Local

```json
{
  "aps": {
    "alert": {
      "title": "Nouvel événement",
      "body": "Un événement se déroule près de chez toi !"
    },
    "sound": "default",
    "badge": 1
  },
  "offerId": 456,
  "type": "EVENT"
}
```

**Comportement Front-end:**
- Même comportement qu'une offre, mais avec `type: "EVENT"` pour distinguer
- Navigue vers `OfferDetailView(offerId: 456)` avec le type événement

#### C. Notification pour un Nouveau Professionnel

```json
{
  "aps": {
    "alert": {
      "title": "Nouvel établissement",
      "body": "Un nouveau professionnel a rejoint ta zone !"
    },
    "sound": "default",
    "badge": 1
  },
  "professionalId": 789
}
```

**Comportement Front-end:**
- Affiche la notification
- Quand l'utilisateur tape dessus, navigue vers `PartnerDetailViewFromId(professionalId: 789)`
- Change automatiquement vers l'onglet "Accueil"

### 3.3 Support des Types de Données

Le front-end accepte les IDs comme **Int** ou **String** :

```json
// ✅ Accepté
{ "offerId": 123 }
{ "offerId": "123" }
{ "professionalId": 456 }
{ "professionalId": "456" }
```

### 3.4 Affichage en Foreground

Le front-end affiche les notifications même quand l'app est ouverte (foreground) :
- **iOS 14+**: Banner en haut de l'écran
- **iOS < 14**: Alert classique
- Le son et le badge sont aussi activés

---

## 4. Navigation Automatique

### 4.1 Flux de Navigation

Quand l'utilisateur tape sur une notification :

1. **AppDelegate** reçoit la notification via `didReceive response`
2. Extrait `offerId` ou `professionalId` du payload
3. Poste une notification interne `PushNotificationTapped`
4. **TabBarView** écoute cette notification
5. Change d'onglet si nécessaire
6. Navigue vers la vue détaillée correspondante

### 4.2 Mapping des Notifications

| Type de Notification | Champ dans Payload | Navigation |
|---------------------|-------------------|------------|
| Offre | `offerId` | `OfferDetailView(offerId)` |
| Événement | `offerId` + `type: "EVENT"` | `OfferDetailView(offerId)` |
| Professionnel | `professionalId` | `PartnerDetailViewFromId(professionalId)` |

---

## 5. Environnements (SANDBOX/PRODUCTION)

### 5.1 Détection de l'Environnement

Le front-end envoie automatiquement l'environnement dans la requête d'enregistrement du token :

- **DEBUG mode** (`#if DEBUG`): `"SANDBOX"`
- **RELEASE mode**: `"PRODUCTION"`

### 5.2 Utilisation par le Backend

Le backend doit utiliser l'environnement pour :
- Envoyer les notifications via le bon certificat APNs
- Utiliser le bon endpoint APNs (sandbox ou production)
- Logger correctement les notifications selon l'environnement

---

## 6. Exemples de Requêtes

### 6.1 Enregistrer un Token Push

```bash
curl -X POST http://127.0.0.1:8080/api/v1/push/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "a1b2c3d4e5f6789012345678901234567890abcdef",
    "platform": "IOS",
    "environment": "SANDBOX"
  }'
```

### 6.2 Récupérer les Préférences

```bash
curl -X GET http://127.0.0.1:8080/api/v1/notification-preferences \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Accept: application/json"
```

### 6.3 Sauvegarder les Préférences

```bash
curl -X PUT http://127.0.0.1:8080/api/v1/notification-preferences \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notifyNewOffers": true,
    "notifyNewProNearby": true,
    "notifyLocalEvents": true,
    "notificationRadius": 15,
    "preferredCategories": [
      "SANTE_BIEN_ETRE",
      "FOOD_PLAISIRS"
    ]
  }'
```

### 6.4 Envoyer une Notification Test (via Backend)

Le backend doit utiliser l'API APNs pour envoyer une notification. Exemple de payload à envoyer à APNs :

```json
{
  "aps": {
    "alert": {
      "title": "Test Notification",
      "body": "Ceci est une notification de test"
    },
    "sound": "default",
    "badge": 1
  },
  "offerId": 123
}
```

**Note:** Le backend doit utiliser le token APNs enregistré via `/push/register` pour envoyer la notification.

---

## 7. Logique de Filtrage des Notifications

### 7.1 Respect des Préférences Utilisateur

Le backend doit vérifier les préférences de l'utilisateur avant d'envoyer une notification :

1. **Pour une nouvelle offre:**
   - Vérifier `notifyNewOffers == true`
   - Vérifier la distance (`notificationRadius`)
   - Vérifier les catégories préférées (`preferredCategories`)

2. **Pour un nouveau professionnel:**
   - Vérifier `notifyNewProNearby == true`
   - Vérifier la distance (`notificationRadius`)
   - Vérifier les catégories préférées (`preferredCategories`)

3. **Pour un événement local:**
   - Vérifier `notifyLocalEvents == true`
   - Vérifier la distance (`notificationRadius`)

### 7.2 Géolocalisation

Le front-end envoie la géolocalisation de l'utilisateur lors des recherches. Le backend doit utiliser cette information pour :
- Filtrer les notifications par distance
- Prioriser les notifications proches de l'utilisateur

---

## 8. Points Importants pour le Backend

### ✅ À Faire

- ✅ Accepter les tokens APNs et FCM
- ✅ Stocker l'environnement (SANDBOX/PRODUCTION) avec chaque token
- ✅ Respecter les préférences utilisateur avant d'envoyer
- ✅ Utiliser le bon certificat APNs selon l'environnement
- ✅ Envoyer les IDs comme Int ou String (les deux sont acceptés)
- ✅ Inclure `offerId` ou `professionalId` dans le payload
- ✅ Inclure `type: "EVENT"` pour les événements

### ❌ À Éviter

- ❌ Envoyer des notifications si l'utilisateur a désactivé le type correspondant
- ❌ Ignorer le rayon de notification (`notificationRadius`)
- ❌ Ignorer les catégories préférées (`preferredCategories`)
- ❌ Envoyer des notifications sans `offerId` ou `professionalId` (la navigation ne fonctionnera pas)

---

## 9. Tests sur Simulateur iOS

### 9.1 Limitations

⚠️ **Important:** Les notifications push ne fonctionnent **PAS** sur le simulateur iOS standard.

### 9.2 Solutions pour Tester

1. **Tester sur un appareil physique** (recommandé)
2. **Utiliser Firebase Console** pour envoyer des notifications de test
3. **Appeler directement l'endpoint backend** qui envoie les notifications

### 9.3 Exemple de Test via Backend

Le backend peut exposer un endpoint de test (ex: `POST /api/v1/push/test`) qui envoie une notification à l'utilisateur connecté :

```bash
curl -X POST http://127.0.0.1:8080/api/v1/push/test \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "OFFER",
    "offerId": 123,
    "title": "Test",
    "body": "Notification de test"
  }'
```

---

## 10. Résumé des Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/push/register` | Enregistrer un token push |
| `GET` | `/api/v1/notification-preferences` | Récupérer les préférences |
| `PUT` | `/api/v1/notification-preferences` | Sauvegarder les préférences |

---

## 11. Support et Contact

Pour toute question technique, référez-vous à ce document ou contactez l'équipe iOS.

**Dernière mise à jour:** Décembre 2025



