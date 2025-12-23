//
//  MockDataService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    func getProfessionals() -> [Professional] {
        return [
            Professional(
                firstName: "Marc",
                lastName: "Dubois",
                profession: "Coiffeur Expert",
                category: "Beauté & Bien-être",
                address: "15 Rue de la République",
                city: "Paris",
                postalCode: "75001",
                phone: "+33 1 23 45 67 89",
                email: "marc.dubois@example.com",
                profileImageName: "person.circle.fill",
                websiteURL: "https://example.com",
                instagramURL: "https://instagram.com/marcdubois",
                description: "Coiffeur expert avec plus de 10 ans d'expérience. Spécialisé dans les coupes modernes et les colorations.",
                isFavorite: false
            ),
            Professional(
                firstName: "Sophie",
                lastName: "Martin",
                profession: "Boulangère Artisanale",
                category: "Alimentation",
                address: "28 Avenue Victor Hugo",
                city: "Lyon",
                postalCode: "69001",
                phone: "+33 4 12 34 56 78",
                email: "sophie.martin@example.com",
                profileImageName: "person.circle.fill",
                websiteURL: "https://example.com",
                instagramURL: "https://instagram.com/sophiemartin",
                description: "Boulangère artisanale passionnée par les produits bio et locaux. Pain au levain naturel et viennoiseries maison.",
                isFavorite: true
            ),
            Professional(
                firstName: "Pierre",
                lastName: "Lefebvre",
                profession: "Mécanicien Auto",
                category: "Automobile",
                address: "42 Boulevard Gambetta",
                city: "Marseille",
                postalCode: "13001",
                phone: "+33 4 91 23 45 67",
                email: "pierre.lefebvre@example.com",
                profileImageName: "person.circle.fill",
                websiteURL: "https://example.com",
                instagramURL: "https://instagram.com/pierrelefebvre",
                description: "Mécanicien automobile certifié. Réparation et entretien de tous types de véhicules. Devis gratuits.",
                isFavorite: false
            ),
            Professional(
                firstName: "Claire",
                lastName: "Rousseau",
                profession: "Coach Yoga & Bien-être",
                category: "Beauté & Bien-être",
                address: "7 Place du Capitole",
                city: "Toulouse",
                postalCode: "31000",
                phone: "+33 5 61 23 45 67",
                email: "claire.rousseau@example.com",
                profileImageName: "person.circle.fill",
                websiteURL: "https://example.com",
                instagramURL: "https://instagram.com/clairerousseau",
                description: "Coach certifiée en yoga et bien-être. Cours individuels et collectifs. Approche holistique de la santé.",
                isFavorite: true
            )
        ]
    }
    
    func getCategories() -> [String] {
        return ["Toutes", "Beauté & Bien-être", "Alimentation", "Automobile", "Santé", "Éducation"]
    }
    
    func getCities() -> [String] {
        return ["Toutes", "Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes"]
    }
    
    func getOffers() -> [Offer] {
        return getAllOffers()
    }
    
    private static let fitFormeId = UUID()
    private static let gameZoneId = UUID()
    
    func getPartners() -> [Partner] {
        return [
            Partner(
                id: MockDataService.fitFormeId,
                name: "Fit & Forme Studio",
                category: "Sport & Santé",
                address: "28 Avenue Victor Hugo",
                city: "Lyon",
                postalCode: "69001",
                phone: "04 78 12 34 56",
                email: "contact@fitforme.fr",
                website: "https://fitforme.fr",
                instagram: "https://instagram.com/fitforme",
                description: "Salle de sport moderne avec équipements de dernière génération.",
                rating: 4.7,
                reviewCount: 48,
                discount: 10,
                imageName: "figure.strengthtraining.traditional",
                headerImageName: "figure.strengthtraining.traditional",
                isFavorite: true
            ),
            Partner(
                name: "Belle & Zen Spa",
                category: "Esthétique",
                address: "15 Rue de la République",
                city: "Lyon",
                postalCode: "69007",
                phone: "04 78 23 45 67",
                email: "contact@belletzen.fr",
                website: "https://belletzen.fr",
                instagram: "https://instagram.com/belletzen",
                description: "Spa de bien-être et esthétique avec soins relaxants.",
                rating: 4.9,
                reviewCount: 72,
                discount: 10,
                imageName: "sparkles",
                headerImageName: "sparkles",
                isFavorite: false
            ),
            Partner(
                name: "Le Comptoir Gourmand",
                category: "Food",
                address: "42 Boulevard Gambetta",
                city: "Lyon",
                postalCode: "69002",
                phone: "04 78 34 56 78",
                email: "contact@comptoirgourmand.fr",
                website: "https://comptoirgourmand.fr",
                instagram: "https://instagram.com/comptoirgourmand",
                description: "Restaurant gastronomique avec produits locaux et de saison.",
                rating: 4.5,
                reviewCount: 156,
                discount: 10,
                imageName: "fork.knife",
                headerImageName: "fork.knife",
                isFavorite: true
            ),
            Partner(
                id: MockDataService.gameZoneId,
                name: "GameZone VR",
                category: "Divertissement",
                address: "120 Cours Lafayette",
                city: "Lyon",
                postalCode: "69003",
                phone: "04 78 00 00 04",
                email: "info@gamezonevr.fr",
                website: "https://gamezonevr.fr",
                instagram: "https://instagram.com/gamezonevr",
                description: "Centre de réalité virtuelle avec plus de 50 jeux et expériences. Escape games VR, simulateurs et anniversaires.",
                rating: 4.8,
                reviewCount: 89,
                discount: nil,
                imageName: "gamecontroller.fill",
                headerImageName: "gamecontroller.fill",
                isFavorite: false
            )
        ]
    }
    
    func getAllOffers() -> [Offer] {
        return [
            Offer(
                title: "-50% sur l'abonnement",
                description: "Profitez de 50% de réduction sur votre premier mois d'abonnement ! Accès illimité à la salle, cours collectifs inclus.",
                businessName: "Fit & Forme Studio",
                validUntil: "22/01/2026",
                discount: "-50%",
                imageName: "figure.strengthtraining.traditional",
                offerType: .offer,
                isClub10: true,
                partnerId: MockDataService.fitFormeId
            ),
            Offer(
                title: "Cours Découverte GRATUIT",
                description: "Venez essayer un cours collectif gratuitement ! Découvrez nos différentes disciplines et trouvez celle qui vous convient.",
                businessName: "Fit & Forme Studio",
                validUntil: "21/01/2026",
                discount: "GRATUIT",
                imageName: "figure.run",
                offerType: .offer,
                isClub10: true,
                partnerId: MockDataService.fitFormeId
            ),
            Offer(
                title: "Tournoi VR Battle Royale",
                description: "Participez à notre tournoi de réalité virtuelle ! Inscription gratuite, lots à gagner.",
                businessName: "GameZone VR",
                validUntil: "13/1/2026",
                discount: "",
                imageName: "gamecontroller.fill",
                offerType: .event,
                partnerId: MockDataService.gameZoneId
            ),
            Offer(
                title: "2h pour le prix d'1h",
                description: "Profitez de 2 heures de jeu pour le prix d'une seule heure ! Offre valable tous les jours.",
                businessName: "GameZone VR",
                validUntil: "6/1/2026",
                discount: "",
                imageName: "gamecontroller.fill",
                offerType: .offer,
                partnerId: MockDataService.gameZoneId
            ),
            Offer(
                title: "Escape Game VR -25%",
                description: "Réduction de 25% sur tous nos escape games en réalité virtuelle. Parfait pour les groupes !",
                businessName: "GameZone VR",
                validUntil: "17/1/2026",
                discount: "-25%",
                imageName: "gamecontroller.fill",
                offerType: .offer,
                partnerId: MockDataService.gameZoneId
            )
        ]
    }
    
    func getOffersForPartner(partnerId: UUID) -> [Offer] {
        return getAllOffers().filter { $0.partnerId == partnerId }
    }
}

