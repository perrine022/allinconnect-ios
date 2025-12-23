# allinConnect iOS

Application iOS native développée en SwiftUI pour connecter les utilisateurs avec des professionnels locaux et bénéficier d'avantages exclusifs via le CLUB10.

**Développé par** : Perrine Honoré

## 📋 Table des matières

- [Architecture](#architecture)
- [Structure du projet](#structure-du-projet)
- [Technologies](#technologies)
- [Modèles de données](#modèles-de-données)
- [Composants réutilisables](#composants-réutilisables)
- [Fonctionnalités](#fonctionnalités)
- [Intégration Backend](#intégration-backend)
- [Installation](#installation)
- [Build & Run](#build--run)

## 🏗️ Architecture

L'application suit une architecture **MVVM (Model-View-ViewModel)** simple et modulaire :

```
┌─────────────┐
│    View     │  ← SwiftUI Views (HomeView, DetailsView, etc.)
└──────┬──────┘
       │
       │ @StateObject / @ObservedObject
       │
┌──────▼──────┐
│  ViewModel  │  ← Logique métier, état, filtres
└──────┬──────┘
       │
       │ Dependency Injection
       │
┌──────▼──────┐
│   Service   │  ← MockDataService (sera remplacé par API Service)
└──────┬──────┘
       │
┌──────▼──────┐
│    Model    │  ← Structures de données (Professional, Partner, Offer, User)
└─────────────┘
```

### Principes

- **Séparation des responsabilités** : Chaque couche a un rôle précis
- **Composants réutilisables** : Tous les composants UI sont dans `Core/Components`
- **Dependency Injection** : Les services sont injectés dans les ViewModels
- **Single Source of Truth** : Les ViewModels gèrent l'état de l'application

## 📁 Structure du projet

```
all/
├── Core/                          # Composants partagés
│   ├── Components/               # Composants UI réutilisables
│   │   ├── ActionButton.swift
│   │   ├── BadgeView.swift
│   │   ├── Club10Card.swift
│   │   ├── ContactRow.swift
│   │   ├── FilterButton.swift
│   │   ├── FilterSheet.swift
│   │   ├── FooterBar.swift        # Footer de navigation réutilisable
│   │   ├── InfoSection.swift
│   │   ├── NavigationButton.swift
│   │   ├── OfferCard.swift
│   │   ├── PartnerCard.swift
│   │   ├── ProfessionalCard.swift
│   │   ├── ProfileHeaderView.swift
│   │   ├── SearchBar.swift
│   │   ├── StatCard.swift
│   │   └── TabBarView.swift       # Navigation principale
│   ├── Extensions/
│   │   └── ViewExtensions.swift  # Extensions utilitaires (hideKeyboard, cornerRadius)
│   ├── Models/                    # Modèles de données
│   │   ├── Offer.swift
│   │   ├── Partner.swift
│   │   ├── Professional.swift
│   │   └── User.swift
│   ├── Services/
│   │   └── MockDataService.swift  # Service de données mockées (à remplacer par API)
│   └── Theme/
│       └── AppColors.swift        # Palette de couleurs de l'app
│
├── Features/                       # Fonctionnalités par feature
│   ├── Details/
│   │   └── DetailsView.swift      # Vue de détail d'un professionnel
│   ├── Home/
│   │   ├── HomeView.swift         # Vue principale d'accueil
│   │   └── HomeViewModel.swift    # ViewModel pour la logique métier
│   └── Profile/
│       └── ProfileView.swift      # Vue de profil utilisateur
│
└── allApp.swift                   # Point d'entrée de l'application
```

## 🛠️ Technologies

- **SwiftUI** : Framework UI déclaratif d'Apple
- **Swift 5.9+** : Langage de programmation
- **iOS 17.0+** : Version minimale supportée
- **MVVM** : Pattern architectural
- **NavigationStack** : Navigation moderne SwiftUI
- **Combine** : Framework réactif (préparé pour futures fonctionnalités)
- **Async/Await** : Prêt pour les appels réseau asynchrones

## 📊 Modèles de données

### Professional
Représente un professionnel partenaire de l'application.

```swift
struct Professional: Identifiable, Codable, Hashable {
    let id: UUID
    let firstName: String
    let lastName: String
    let profession: String
    let category: String
    let address: String
    let city: String
    let postalCode: String
    let phone: String?
    let email: String?
    let profileImageName: String
    let websiteURL: String?
    let instagramURL: String?
    let description: String?
    var isFavorite: Bool
}
```

### Partner
Représente un partenaire avec ses informations de notation et réduction.

```swift
struct Partner: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: String
    let city: String
    let postalCode: String
    let rating: Double
    let reviewCount: Int
    let discount: Int?
    let imageName: String
    var isFavorite: Bool
}
```

### Offer
Représente une offre promotionnelle.

```swift
struct Offer: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let businessName: String
    let validUntil: String
    let discount: String
    let imageName: String
    let isClub10: Bool
}
```

### User
Représente un utilisateur de l'application.

```swift
struct User: Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let username: String
    let bio: String
    let profileImageName: String
    let publications: Int
    let subscribers: Int
    let subscriptions: Int
}
```

## 🧩 Composants réutilisables

Tous les composants sont dans `Core/Components/` et peuvent être utilisés partout dans l'application :

### Navigation
- **FooterBar** : Barre de navigation en bas avec 5 onglets
- **TabBarView** : Conteneur principal avec navigation par onglets
- **NavigationButton** : Boutons de navigation (close, favorite)

### Formulaires & Recherche
- **SearchBar** : Barre de recherche avec icône et placeholder
- **FilterButton** : Bouton de filtre avec icône et valeur sélectionnée
- **FilterSheet** : Sheet modale pour sélectionner des filtres

### Cards & Affichage
- **ProfessionalCard** : Carte de professionnel pour les listes
- **PartnerCard** : Carte de partenaire avec note et réduction
- **OfferCard** : Carte d'offre promotionnelle
- **Club10Card** : Carte promotionnelle CLUB10
- **BadgeView** : Badge avec gradient personnalisable
- **StatCard** : Carte de statistique (nombre + label)

### Détails
- **ProfileHeaderView** : Header avec photo de profil et gradient
- **InfoSection** : Section d'information avec titre et icône
- **ContactRow** : Ligne de contact cliquable
- **ActionButton** : Bouton d'action avec gradient

### Utilitaires
- **ViewExtensions** : Extensions pour masquer le clavier, coins arrondis, etc.

## ✨ Fonctionnalités

### HomeView (Écran d'accueil)
- Logo "ALL IN" avec cercles concentriques
- Bouton promotionnel "L'app qui pense à toi"
- Champs de recherche : Ville, nom, activité
- Toggle pour activer/désactiver le rayon de recherche
- Checkbox pour filtrer uniquement les membres CLUB10
- Section "À ne pas louper" avec scroll horizontal des offres
- Carte "Pourquoi ta carte digitale ?"
- Section "Nos partenaires" avec liste verticale

### DetailsView (Fiche professionnel)
- Header avec photo de profil et gradient rouge
- Nom et prénom en style premium
- Badge de catégorie
- Sections d'information : Localisation, Contact, À propos
- Boutons d'action : Site Web, Instagram
- Bouton favori dans la barre de navigation

### ProfileView (Profil utilisateur)
- Header avec gradient violet
- Photo de profil chevauchant le header
- Nom, username, bio
- Statistiques : Publications, Abonnés, Abonnements
- Boutons : Modifier le profil, Partager

### Navigation
- Footer avec 5 onglets : Accueil, Ma Carte, Add (central), Espace Pro, Profil
- NavigationStack pour la navigation entre vues
- Navigation vers les détails des professionnels et partenaires

## 🔌 Intégration Backend

### Service actuel : MockDataService

Le service actuel utilise des données mockées. Pour intégrer le backend :

1. **Créer un nouveau service API** :

```swift
// Core/Services/APIService.swift
class APIService {
    private let baseURL = "http://localhost:3000/api" // À configurer
    
    func getProfessionals() async throws -> [Professional] {
        // Implémentation avec URLSession et async/await
    }
    
    func getPartners() async throws -> [Partner] {
        // Implémentation
    }
    
    func getOffers() async throws -> [Offer] {
        // Implémentation
    }
}
```

2. **Mettre à jour le ViewModel** :

```swift
@MainActor
class HomeViewModel: ObservableObject {
    private let apiService: APIService
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func loadData() async {
        do {
            professionals = try await apiService.getProfessionals()
            partners = try await apiService.getPartners()
            offers = try await apiService.getOffers()
        } catch {
            // Gestion des erreurs
        }
    }
}
```

3. **Remplacer MockDataService** dans les ViewModels par `APIService`

### Endpoints attendus

- `GET /api/professionals` - Liste des professionnels
- `GET /api/partners` - Liste des partenaires
- `GET /api/offers` - Liste des offres
- `GET /api/categories` - Liste des catégories
- `GET /api/cities` - Liste des villes
- `POST /api/favorites` - Ajouter/retirer des favoris

## 🎨 Design System

### Couleurs

Les couleurs sont définies dans `Core/Theme/AppColors.swift` :

```swift
extension Color {
    static let appRed = Color(red: 0.9, green: 0.1, blue: 0.1)
    static let appDarkRed1 = Color(red: 0.114, green: 0.031, blue: 0.035) // #1D0809
    static let appDarkRed2 = Color(red: 0.259, green: 0.082, blue: 0.082) // #421515
    static let appGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let appDarkGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let appBackground = Color.black
    // ...
}
```

### Typographie

- Titres : `.system(size: 32, weight: .bold, design: .rounded)`
- Sous-titres : `.system(size: 20, weight: .bold)`
- Corps : `.system(size: 16, weight: .regular)`
- Captions : `.system(size: 14, weight: .medium)`

## 📱 Installation

### Prérequis

- Xcode 15.0+
- iOS 17.0+ (simulateur ou appareil)
- Swift 5.9+

### Étapes

1. Cloner le repository :
```bash
git clone <repository-url>
cd allinconnect-ios
```

2. Ouvrir le projet dans Xcode :
```bash
open all/all.xcodeproj
```

3. Sélectionner un simulateur ou un appareil

4. Build et Run (⌘R)

## 🚀 Build & Run

### Via Xcode
1. Ouvrir `all/all.xcodeproj`
2. Sélectionner un target (simulateur ou appareil)
3. Presser ⌘R ou cliquer sur "Run"

### Via ligne de commande
```bash
cd all
xcodebuild -project all.xcodeproj -scheme all -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 📝 Notes techniques

### Gestion du clavier
- Le clavier se masque automatiquement lors du scroll
- Tap gesture pour masquer le clavier en dehors des champs
- `.scrollDismissesKeyboard(.interactively)` sur les ScrollView

### Performance
- Utilisation de `LazyVStack` pour les listes longues
- Images chargées de manière optimisée
- ViewModels avec `@MainActor` pour les mises à jour UI

### Accessibilité
- Labels accessibles sur tous les boutons
- Contrastes de couleurs respectés
- Support VoiceOver (à améliorer)

## 🔄 Évolutions futures

- [ ] Intégration complète avec le backend
- [ ] Authentification utilisateur
- [ ] Géolocalisation pour le rayon de recherche
- [ ] Push notifications
- [ ] Partage social
- [ ] Mode sombre/clair
- [ ] Tests unitaires et UI tests
- [ ] Analytics et crash reporting

## 📄 Licence

[À définir]

## 👥 Développement

**Développé par** : Perrine Honoré

---

**Version** : 1.0.0  
**Dernière mise à jour** : Décembre 2025

