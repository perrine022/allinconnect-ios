# 📋 Audit de la Géolocalisation - iOS SwiftUI

**Date:** 2026-01-08  
**Statut:** ✅ Conforme aux bonnes pratiques (après corrections)

---

## ✅ Points Conformes (Déjà en place)

### 1. Architecture de base
- ✅ **Permission demandée** via `LocationService.requestLocationPermission()`
- ✅ **Permission "When In Use"** utilisée (`requestWhenInUseAuthorization`)
- ✅ **CLLocationManager** configuré correctement
- ✅ **Coordonnées récupérées** (latitude, longitude) depuis `CLLocation`

### 2. Envoi des coordonnées à l'API
- ✅ **Latitude et longitude** envoyées aux endpoints de recherche
- ✅ **Paramètres `lat` et `lon`** utilisés (conforme au backend)
- ✅ **Fallback sur ville** si géolocalisation refusée ou indisponible

### 3. Gestion des permissions
- ✅ **Demande de permission** au démarrage (HomeView, OffersView)
- ✅ **UI de permission** (`LocationPermissionView`) avec explication
- ✅ **Gestion du refus** : bascule automatique sur recherche par ville

---

## 🔧 Corrections Apportées

### 1. ✅ Conversion du radius en mètres
**Problème:** Le radius était envoyé en kilomètres alors que le backend attend des mètres.

**Avant:**
```swift
parameters["radius"] = radius // En kilomètres
```

**Après:**
```swift
parameters["radius"] = radius * 1000.0 // Conversion km → mètres
```

**Fichiers modifiés:**
- `OffersAPIService.swift` (ligne 198)
- `PartnersAPIService.swift` (ligne 159)

### 2. ✅ Ajout de `distanceMeters` dans les modèles
**Problème:** Le backend renvoie `distanceMeters` mais ce champ n'était pas présent dans les modèles de réponse.

**Ajouté:**
- `OfferResponse.distanceMeters: Double?`
- `PartnerProfessionalResponse.distanceMeters: Double?`
- `Offer.distanceMeters: Double?`
- `Partner.distanceMeters: Double?`

**Fichiers modifiés:**
- `OffersAPIService.swift` (modèle `OfferResponse`)
- `PartnersAPIService.swift` (modèle `PartnerProfessionalResponse`)
- `Offer.swift` (modèle interne)
- `Partner.swift` (modèle interne)

### 3. ✅ Mapping de `distanceMeters` dans les conversions
**Ajouté:** Le mapping de `distanceMeters` dans les fonctions `toOffer()` et `toPartner()`.

**Fichiers modifiés:**
- `OffersAPIService.swift` (fonction `toOffer()`)
- `PartnersAPIService.swift` (fonction `toPartner()`)

### 4. ✅ Création d'un utilitaire de formatage
**Créé:** `DistanceFormatter.swift` pour formater les distances en format lisible.

**Fonctions disponibles:**
- `formatDistance(_:)` → "2.5 km" ou "500 m"
- `formatDistanceShort(_:)` → "2.5km" ou "500m"

**Utilisation recommandée:**
```swift
if let distance = offer.distanceMeters {
    Text(DistanceFormatter.formatDistance(distance) ?? "")
}
```

---

## 📊 Flux de Géolocalisation (Conforme)

### 1. Demande de permission
```
App démarre → LocationService.requestLocationPermission() 
→ requestWhenInUseAuthorization()
→ Utilisateur accepte/refuse
```

### 2. Récupération de la position
```
Permission accordée → startLocationUpdates()
→ CLLocationManager fournit CLLocation
→ currentLocation publié via @Published
```

### 3. Envoi à l'API
```
currentLocation disponible → latitude/longitude extraites
→ radius converti en mètres (km * 1000)
→ Paramètres envoyés: lat, lon, radius (en mètres)
```

### 4. Réception de la réponse
```
Backend renvoie distanceMeters (en mètres)
→ distanceMeters mappé dans les modèles
→ Disponible pour affichage dans l'UI
```

### 5. Fallback si refus
```
Permission refusée → Utilisation de cityText
→ Recherche textuelle/ville classique
→ Pas de distanceMeters dans la réponse
```

---

## 🎯 Format de Requête API (Conforme)

### Endpoint: `/api/v1/offers`
```json
{
  "lat": 48.8566,
  "lon": 2.3522,
  "radius": 15000  // En MÈTRES (15 km)
}
```

### Endpoint: `/api/v1/users/professionals/search`
```json
{
  "lat": 48.8566,
  "lon": 2.3522,
  "radius": 15000  // En MÈTRES (15 km)
}
```

### Réponse attendue
```json
{
  "id": 123,
  "title": "Offre spéciale",
  "distanceMeters": 2500.5  // Distance en mètres depuis l'utilisateur
}
```

---

## ✅ Checklist de Conformité

| Point | Statut | Notes |
|-------|--------|-------|
| Permission "When In Use" | ✅ | Fait |
| Récupération lat/lng | ✅ | Via CLLocationManager |
| Envoi lat/lon à l'API | ✅ | Paramètres `lat` et `lon` |
| Radius en mètres | ✅ | **Corrigé** (conversion km → m) |
| distanceMeters dans modèles | ✅ | **Ajouté** |
| Mapping distanceMeters | ✅ | **Ajouté** |
| Fallback sur ville | ✅ | Si permission refusée |
| Formatage distance | ✅ | **Créé** DistanceFormatter |

---

## 📝 Fichiers Modifiés

1. **`all/all/Core/Services/OffersAPIService.swift`**
   - Conversion radius km → mètres
   - Ajout `distanceMeters` dans `OfferResponse`
   - Mapping `distanceMeters` dans `toOffer()`

2. **`all/all/Core/Services/PartnersAPIService.swift`**
   - Conversion radius km → mètres
   - Ajout `distanceMeters` dans `PartnerProfessionalResponse`
   - Mapping `distanceMeters` dans `toPartner()`

3. **`all/all/Core/Models/Offer.swift`**
   - Ajout `distanceMeters: Double?`

4. **`all/all/Core/Models/Partner.swift`**
   - Ajout `distanceMeters: Double?`

5. **`all/all/Core/Utils/DistanceFormatter.swift`** (nouveau)
   - Utilitaire pour formater les distances

---

## 🎨 Utilisation dans l'UI (Recommandé)

### Exemple pour afficher la distance
```swift
// Dans OfferListCard ou PartnerCard
if let distance = offer.distanceMeters {
    HStack(spacing: 4) {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 11))
        Text(DistanceFormatter.formatDistance(distance) ?? "")
            .font(.system(size: 11, weight: .regular))
    }
}
```

---

## ✅ Conclusion

L'implémentation est maintenant **conforme aux bonnes pratiques** :

1. ✅ Géolocalisation sur le device (pas d'IP)
2. ✅ Coordonnées envoyées au backend
3. ✅ Radius en mètres (conforme au backend)
4. ✅ `distanceMeters` récupéré et mappé
5. ✅ Fallback sur recherche textuelle si refus
6. ✅ Utilitaire de formatage disponible

**Tous les points du guide ont été implémentés ou corrigés.**

---

**Statut Final:** ✅ **CONFORME AUX BONNES PRATIQUES**

