# Documentation Backend - Recherche de Professionnels et Paramètres Utilisateur

## 📋 Résumé des améliorations

Le backend a été amélioré pour rendre la recherche de professionnels plus intelligente et utiliser automatiquement les données du profil utilisateur. Voici ce qui a changé :

---

## 1. Champ `postalCode` (Code Postal)

### ✅ Statut : **100% Opérationnel**

Le bug de la colonne manquante `postal_code` est résolu. Le front-end peut désormais :

- ✅ **Envoyer le `postalCode`** lors de la création ou de la mise à jour du profil
- ✅ **Récupérer le `postalCode`** dans les réponses d'API (`UserProfile`, `UserMeResponse`, etc.)

### Implémentation iOS

Le champ `postalCode` a été ajouté dans :
- `RegistrationRequest` (inscription)
- `UpdateProfileRequest` (mise à jour du profil)
- `UserMeResponse` (récupération du profil complet)

**Exemple d'utilisation :**
```swift
// Lors de l'inscription
let registrationRequest = RegistrationRequest(
    firstName: "John",
    lastName: "Doe",
    email: "john@example.com",
    password: "password",
    postalCode: "69001", // ✅ Nouveau champ
    // ... autres champs
)

// Lors de la mise à jour du profil
let updateRequest = UpdateProfileRequest(
    postalCode: "69001", // ✅ Nouveau champ
    // ... autres champs
)
```

---

## 2. Logique de Recherche Intelligente (`searchProfessionals`)

### 🎯 Nouvelle logique de tri automatique

La recherche est devenue plus "intelligente" et utilise les données de l'utilisateur connecté :

### A. Géolocalisation prioritaire
**Si le front-end envoie `lat` (latitude) et `lon` (longitude) dans la requête :**
- ✅ Le backend trie automatiquement les résultats **par distance** (du plus proche au plus loin)
- ✅ Les résultats sont filtrés par rayon si `radius` est fourni

**Exemple :**
```swift
// Recherche avec géolocalisation
let professionals = try await partnersAPIService.searchProfessionals(
    latitude: 45.7640,  // Lyon
    longitude: 4.8357,
    radius: 10.0        // 10 km
)
// ✅ Résultats triés par distance automatiquement
```

### B. Auto-complétion par le profil utilisateur
**Si le front-end n'envoie PAS de coordonnées :**
- ✅ Le backend regarde automatiquement dans le profil de l'utilisateur connecté
- ✅ Il utilise la `latitude`/`longitude` du profil si disponible
- ✅ Il trie les résultats par distance en utilisant ces coordonnées

**Exemple :**
```swift
// Recherche sans coordonnées - le backend utilise le profil utilisateur
let professionals = try await partnersAPIService.searchProfessionals(
    city: "Lyon",
    category: .foodPlaisirsGourmands
)
// ✅ Le backend utilise automatiquement lat/lon du profil utilisateur si disponible
```

### C. Algorithme de tri (Fallback)
**Si aucune coordonnée n'est disponible** (ni dans la requête, ni dans le profil) :

Le tri se fait par **pertinence** dans cet ordre :
1. ✅ Correspondance exacte avec la ville recherchée
2. ✅ Correspondance avec la ville du profil utilisateur
3. ✅ Correspondance avec le code postal (`postalCode`) du profil utilisateur

**Exemple :**
```swift
// Recherche sans coordonnées et sans ville dans la requête
let professionals = try await partnersAPIService.searchProfessionals(
    category: .santeBienEtre
)
// ✅ Le backend utilise le postalCode du profil pour trier les résultats
```

---

## 3. Rayon de recherche (`radius`)

### 🎯 Nouveau comportement avec fallback

**Si un `radius` est fourni :**
- ✅ Le backend filtre les pros aux alentours dans le rayon spécifié
- ✅ **NOUVEAU** : Si aucun pro n'est trouvé dans le rayon (ex: rayon trop petit), le backend renvoie quand même les résultats les plus proches au lieu d'une liste vide
- ✅ Le tri par distance est conservé même si les résultats dépassent le rayon

**Exemple :**
```swift
// Recherche avec rayon de 5 km
let professionals = try await partnersAPIService.searchProfessionals(
    latitude: 45.7640,
    longitude: 4.8357,
    radius: 5.0  // 5 km
)
// ✅ Si aucun pro dans 5 km, retourne les plus proches quand même
```

---

## 4. Paramètre `name` (Recherche globale)

### 🔍 Recherche multi-champs

Le paramètre `name` est **global** et cherche une correspondance partielle (insensible à la casse) dans :

- ✅ Le **prénom** du pro
- ✅ Le **nom** du pro
- ✅ Le **nom de l'établissement**
- ✅ La **ville**

**Exemple :**
```swift
// Recherche "boulangerie" trouvera :
// - Les pros avec "Boulangerie" dans leur nom/prénom
// - Les établissements nommés "Boulangerie du coin"
// - Les pros situés à "Boulangerie-sur-Mer"
let professionals = try await partnersAPIService.searchProfessionals(
    name: "boulangerie"
)
```

---

## 📝 Résumé pour le développeur front-end

### ✅ Ce qui est déjà implémenté dans iOS

1. ✅ **Envoi de `postalCode`** : Le code envoie maintenant le `postalCode` lors de l'inscription et de la mise à jour du profil
2. ✅ **Récupération de `postalCode`** : Le `postalCode` est récupéré depuis l'API et stocké dans `UserMeResponse`
3. ✅ **Recherche avec géolocalisation** : Le code envoie déjà `lat`, `lon`, et `radius` quand la géolocalisation est disponible
4. ✅ **Paramètre `name`** : Le code peut déjà utiliser le paramètre `name` pour la recherche

### 🎯 Avantages de la nouvelle logique backend

**Vous n'avez pas besoin de "forcer" les coordonnées** si l'utilisateur a déjà complété son profil :
- ✅ Le backend s'occupe automatiquement d'utiliser les coordonnées du profil
- ✅ Le backend utilise le `postalCode` pour améliorer le tri des résultats

**Pour une recherche précise autour de la position GPS actuelle** (mobile) :
- ✅ Envoyez `lat`, `lon` et `radius` pour une recherche par géolocalisation précise
- ✅ Les résultats seront triés par distance automatiquement

### 📍 Endpoint utilisé

```
GET /api/v1/users/professionals/search
```

**Paramètres disponibles :**
- `city` (String, optionnel) : Ville de recherche
- `category` (String, optionnel) : Catégorie (ex: "FOOD_PLAISIRS")
- `name` (String, optionnel) : Recherche globale dans nom/prénom/établissement/ville
- `lat` (Double, optionnel) : Latitude pour géolocalisation
- `lon` (Double, optionnel) : Longitude pour géolocalisation
- `radius` (Double, optionnel) : Rayon de recherche en km

**Comportement backend :**
1. Si `lat`/`lon` fournis → Tri par distance avec ces coordonnées
2. Sinon, si coordonnées dans le profil utilisateur → Tri par distance avec profil
3. Sinon → Tri par pertinence (ville exacte → ville profil → postalCode profil)

---

## 🔧 Code iOS actuel

Le code iOS utilise déjà ces fonctionnalités dans :
- `PartnersAPIService.searchProfessionals()` : Envoie les paramètres de géolocalisation
- `PartnersListViewModel.loadPartners()` : Utilise la géolocalisation si disponible
- `HomeViewModel.loadPartners()` : Utilise la géolocalisation si disponible

**Aucune modification nécessaire** - le code est déjà compatible avec les nouvelles fonctionnalités backend ! 🎉

