# All In Connect iOS

Application iOS native développée en SwiftUI pour connecter les utilisateurs avec des professionnels locaux et bénéficier d'avantages exclusifs via le CLUB10.

**Développé par** : Perrine Honoré

## 🏗️ Architecture

Architecture **MVVM** (Model-View-ViewModel) avec séparation claire des responsabilités :

- **Views** : SwiftUI Views (HomeView, PartnerDetailView, OffersView, CardView, ProfileView)
- **ViewModels** : Logique métier et gestion d'état
- **Services** : MockDataService (à remplacer par API Service)
- **Models** : Structures de données (Professional, Partner, Offer, User, Review)

## 📁 Structure

```
all/
├── Core/
│   ├── Components/        # Composants UI réutilisables
│   ├── Models/           # Modèles de données
│   ├── Services/         # Services (MockDataService)
│   ├── Theme/            # Couleurs et design system
│   └── AppState.swift    # État global de l'app
│
└── Features/             # Fonctionnalités par feature
    ├── Home/             # Page d'accueil
    ├── Offers/           # Liste des offres
    ├── Partner/          # Détail partenaire
    ├── Offer/            # Détail offre
    ├── Card/             # Ma Carte
    └── Profile/          # Profil utilisateur
```

## 🛠️ Technologies

- **SwiftUI** : Framework UI déclaratif
- **Swift 5.0+** : Langage de programmation
- **iOS 17.6+** : Version minimale supportée
- **NavigationStack** : Navigation moderne
- **Combine** : Framework réactif
- **MVVM** : Pattern architectural

## ✨ Fonctionnalités principales

- **Recherche** : Filtres par ville, activité, rayon de recherche, CLUB10
- **Offres** : Liste des offres en cours avec filtres
- **Partenaires** : Fiches détaillées avec avis et offres
- **Ma Carte** : Carte digitale, statistiques, parrainage
- **Profil** : Gestion du profil, favoris, paramètres

## 🎨 Design System

Couleurs principales définies dans `Core/Theme/AppColors.swift` :
- Rouge : `#1D0809`, `#421515`
- Or : `appGold`
- Noir : Background principal

## 📱 Installation

1. Ouvrir le projet dans Xcode :
```bash
cd all
open all.xcodeproj
```

2. Sélectionner un simulateur ou appareil iOS 17.6+

3. Build et Run (⌘R)

## 🔌 Backend

Actuellement utilise `MockDataService` avec des données mockées. Pour intégrer le backend :

1. Créer `APIService` dans `Core/Services/`
2. Remplacer `MockDataService` par `APIService` dans les ViewModels
3. Configurer l'URL de base dans `APIService`

## 📝 Informations

- **Version** : 1.0 (2)
- **Bundle ID** : `com.allinconnect.all`
- **Display Name** : All In Connect
- **Dernière mise à jour** : Décembre 2025

---

**Développé par** : Perrine Honoré
