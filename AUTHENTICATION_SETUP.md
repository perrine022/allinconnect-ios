# Configuration de l'Authentification - Front-end iOS

## ✅ Vérifications effectuées

### 1. Format du Header Authorization
**Status**: ✅ **CORRECT**
- Format utilisé : `Authorization: Bearer TOKEN` (avec espace après "Bearer")
- Localisation : `APIService.swift` ligne 22
- Code : `headers["Authorization"] = "Bearer \(token)"`

### 2. Stockage du Token
**Status**: ✅ **CORRECT**
- Stockage : `UserDefaults` via `AuthTokenManager`
- Sauvegarde lors de l'authentification :
  - `LoginViewModel.swift` ligne 62 : `AuthTokenManager.shared.saveToken(authResponse.token)`
  - `SignUpViewModel.swift` ligne 230 : `AuthTokenManager.shared.saveToken(authResponse.token)`
- Réutilisation : Le token est automatiquement ajouté à toutes les requêtes via `APIConfig.defaultHeaders`

### 3. Endpoint Favoris
**Status**: ✅ **CORRECT**
- Endpoint : `GET /api/v1/users/favorites`
- Localisation : `FavoritesAPIService.swift` ligne 30
- Méthode : `getFavorites()`

### 4. Endpoint Profil Light
**Status**: ✅ **CORRECT**
- Endpoint : `GET /api/v1/users/me/light`
- Localisation : `ProfileAPIService.swift` ligne 248
- Méthode : `getUserLight()`

## 📋 Détails techniques

### Flux d'authentification

1. **Connexion/Inscription** :
   - Endpoint : `POST /api/v1/auth/authenticate` ou `POST /api/v1/auth/register`
   - Réponse : `{ "token": "..." }`
   - Le token est sauvegardé via `AuthTokenManager.shared.saveToken(token)`

2. **Utilisation du token** :
   - Toutes les requêtes incluent automatiquement le header `Authorization: Bearer TOKEN`
   - Le token est récupéré depuis `UserDefaults` à chaque requête
   - Si le token n'existe pas, le header n'est pas ajouté (pour les endpoints publics)

### Gestion des erreurs 401

- Si une erreur 401 est reçue, elle est capturée et convertie en `APIError.unauthorized`
- Le message d'erreur est : "Non autorisé. Veuillez vous reconnecter."

### Logs de débogage

Des logs ont été ajoutés pour vérifier que le token est bien envoyé :
- `🔐 [APIService] Authorization header: Bearer ...` si le token est présent
- `⚠️ [APIService] Aucun token d'authentification trouvé` si le token est absent

## 🔍 Points à vérifier en cas d'erreur 401

1. **Vérifier que le token est bien sauvegardé** :
   ```swift
   if let token = AuthTokenManager.shared.getToken() {
       print("Token présent: \(token)")
   } else {
       print("Aucun token trouvé")
   }
   ```

2. **Vérifier le format du header** :
   - Le header doit être exactement : `Authorization: Bearer TOKEN`
   - Pas d'espace avant "Bearer"
   - Un espace après "Bearer"
   - Le token directement après l'espace

3. **Vérifier que le token n'est pas expiré** :
   - Les tokens JWT ont une durée de vie limitée
   - En cas d'expiration, une nouvelle authentification est nécessaire

4. **Vérifier les logs** :
   - Consulter les logs de l'app pour voir si le token est bien envoyé
   - Vérifier les logs du backend pour voir le header reçu

## 📝 Notes importantes

- Le token est stocké dans `UserDefaults` (pas dans le Keychain pour l'instant)
- Le token est automatiquement inclus dans toutes les requêtes API
- Les endpoints publics (authentification, inscription) n'ont pas besoin du token
- Les endpoints protégés nécessitent le token dans le header Authorization



