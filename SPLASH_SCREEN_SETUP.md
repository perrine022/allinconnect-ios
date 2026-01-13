# Configuration du Splash Screen Animé avec Lottie

## 📋 Étapes d'installation

### 1. Installer Lottie via Swift Package Manager

1. Ouvrez Xcode
2. Allez dans **File > Add Packages...**
3. Collez cette URL : `https://github.com/airbnb/lottie-ios`
4. Cliquez sur **Add Package**
5. Sélectionnez la version la plus récente
6. Assurez-vous que le package est ajouté à la target "all"

### 2. Ajouter les fichiers au projet Xcode

#### A) Fichier splash.json
1. Dans Xcode, faites un clic droit sur le dossier `Resources` (ou créez-le si nécessaire)
2. Sélectionnez **Add Files to "all"...**
3. Naviguez vers `all/all/Resources/splash.json`
4. ✅ Cochez **"Copy items if needed"**
5. ✅ Assurez-vous que la target "all" est sélectionnée
6. Cliquez sur **Add**

#### B) Dossier Images avec logo.png
1. Dans Xcode, faites un clic droit sur le dossier `Resources`
2. Sélectionnez **Add Files to "all"...**
3. Naviguez vers `all/all/Resources/Images/`
4. ✅ Cochez **"Create folder references"** (dossier bleu, pas jaune)
5. ✅ Cochez **"Copy items if needed"**
6. ✅ Assurez-vous que la target "all" est sélectionnée
7. Cliquez sur **Add**

⚠️ **IMPORTANT** : Le dossier `Images` doit être un **Folder Reference** (dossier bleu), pas un **Group** (dossier jaune). Cela permet à Lottie de trouver l'image `logo.png` à l'intérieur.

### 3. Vérification

Après l'installation, vous devriez avoir :
- ✅ Package Lottie installé
- ✅ `splash.json` dans le bundle
- ✅ Dossier `Images/` (bleu) avec `logo.png` à l'intérieur

### 4. Structure finale attendue

```
all/
├── Resources/
│   ├── splash.json          ← Fichier d'animation Lottie
│   └── Images/              ← Folder Reference (bleu)
│       └── logo.png         ← Logo 1024x1024
```

## 🎬 Fonctionnement

Le splash screen s'affiche automatiquement au démarrage de l'app :
- **Durée** : 2 secondes (120 frames à 60fps)
- **Animation** : 
  - Fade-in + zoom "pop" (0→0.2s)
  - Respiration légère + micro rotation (0.2→1.5s)
  - Fade-out (1.75→2.0s)
- **Background** : Gradient de l'app (sombre vers rouge)

Après l'animation, l'app passe automatiquement à `AppContentView` (tutoriel, login, ou app principale selon l'état).

## 🔧 Dépannage

### Si l'animation ne s'affiche pas :
1. Vérifiez que Lottie est bien installé dans le projet
2. Vérifiez que `splash.json` est dans le bundle (visible dans le navigateur de fichiers Xcode)
3. Vérifiez que le dossier `Images` est un **Folder Reference** (bleu), pas un Group
4. Vérifiez que `logo.png` est bien dans `Images/`

### Si l'image ne s'affiche pas dans l'animation :
1. Vérifiez que `logo.png` fait bien 1024x1024 pixels
2. Vérifiez que le chemin dans `splash.json` correspond : `"u": "Images/"` et `"p": "logo.png"`

