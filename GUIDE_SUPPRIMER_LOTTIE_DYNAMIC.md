# Guide : Supprimer Lottie-Dynamic de Xcode

## Problème
L'erreur indique que Xcode cherche `Lottie-Dynamic.framework` qui n'existe pas. Il faut supprimer cette référence.

## Solution étape par étape

### Étape 1 : Ouvrir les paramètres du projet
1. Dans Xcode, cliquez sur le **projet "all"** (icône bleue en haut du Project Navigator à gauche)
2. Vous devriez voir les paramètres du projet au centre

### Étape 2 : Aller dans l'onglet "General"
1. En haut, vous verrez plusieurs onglets : **General**, **Signing & Capabilities**, **Resource Tags**, etc.
2. Cliquez sur **"General"**

### Étape 3 : Trouver la section "Frameworks, Libraries, and Embedded Content"
1. Faites défiler vers le bas dans la fenêtre centrale
2. Cherchez la section **"Frameworks, Libraries, and Embedded Content"**
3. Vous devriez voir une liste avec des frameworks comme :
   - Lottie
   - Lottie-Dynamic ← **C'EST CELUI-CI QU'IL FAUT SUPPRIMER**
   - StripePaymentSheet
   - Firebase...
   - etc.

### Étape 4 : Supprimer Lottie-Dynamic
1. Trouvez **"Lottie-Dynamic"** dans la liste
2. Cliquez dessus pour le sélectionner
3. Appuyez sur la touche **Suppr** (ou **Delete**) de votre clavier
4. OU cliquez sur le bouton **"-"** (moins) en bas de la liste
5. Confirmez la suppression si demandé

### Étape 5 : Vérifier que "Lottie" est toujours présent
1. Dans la même liste, vérifiez que **"Lottie"** (sans "-Dynamic") est toujours présent
2. Si "Lottie" n'est pas présent, il faudra le réajouter (voir étape 6)

### Étape 6 : Si "Lottie" n'est pas présent, l'ajouter
1. Cliquez sur le bouton **"+"** en bas de la liste "Frameworks, Libraries, and Embedded Content"
2. Une fenêtre s'ouvre avec les packages disponibles
3. Cherchez **"Lottie"** (sans "-Dynamic")
4. Sélectionnez-le
5. Cliquez sur **"Add"**

### Étape 7 : Nettoyer le build
1. Dans la barre de menu Xcode : **Product > Clean Build Folder**
   - OU utilisez le raccourci : **Cmd + Shift + K**
2. Attendez que le nettoyage soit terminé

### Étape 8 : Fermer et rouvrir Xcode (optionnel mais recommandé)
1. **Quittez complètement Xcode** (Cmd + Q)
2. **Rouvrez Xcode**
3. **Rouvrez votre projet**

### Étape 9 : Rebuild
1. Dans Xcode : **Product > Build** (Cmd + B)
2. L'erreur devrait être résolue !

## Alternative : Supprimer et réinstaller le package Lottie

Si les étapes ci-dessus ne fonctionnent pas :

### 1. Supprimer complètement le package Lottie
1. Cliquez sur le projet "all" (icône bleue)
2. Allez dans l'onglet **"Package Dependencies"** (en haut)
3. Trouvez **"lottie-ios"**
4. Cliquez dessus
5. Cliquez sur le bouton **"-"** pour le supprimer

### 2. Réinstaller Lottie
1. **File > Add Package Dependencies...**
2. Collez cette URL : `https://github.com/airbnb/lottie-ios`
3. Cliquez sur **"Add Package"**
4. **IMPORTANT** : Dans la fenêtre qui s'ouvre, sélectionnez **UNIQUEMENT "Lottie"** (pas "Lottie-Dynamic")
5. Cliquez sur **"Add Package"**

### 3. Nettoyer et rebuild
1. **Product > Clean Build Folder** (Cmd + Shift + K)
2. **Product > Build** (Cmd + B)

## Vérification finale

Après ces étapes, vous devriez avoir :
- ✅ "Lottie" dans "Frameworks, Libraries, and Embedded Content"
- ✅ "Lottie-Dynamic" **N'EST PAS** dans la liste
- ✅ Le projet compile sans erreur

## Si ça ne fonctionne toujours pas

1. Supprimez le dossier DerivedData :
   - Dans Xcode : **File > Settings** (ou **Preferences**)
   - Allez dans l'onglet **"Locations"**
   - Cliquez sur la flèche à côté de "Derived Data"
   - Supprimez le dossier de votre projet
   - Rebuild

2. Ou via le terminal :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/all-*
   ```


