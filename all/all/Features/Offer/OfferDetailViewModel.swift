//
//  OfferDetailViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class OfferDetailViewModel: ObservableObject {
    @Published var offer: Offer?
    @Published var partner: Partner?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var professionalId: Int? // ID du professionnel pour charger le partenaire
    
    private let offersAPIService: OffersAPIService
    private let partnersAPIService: PartnersAPIService
    private let dataService: MockDataService // Gardé pour le fallback
    
    init(
        offerId: Int? = nil,
        offer: Offer? = nil, // Pour les offres mockées ou déjà chargées
        offersAPIService: OffersAPIService? = nil,
        partnersAPIService: PartnersAPIService? = nil,
        dataService: MockDataService = MockDataService.shared
    ) {
        // Créer le service dans un contexte MainActor
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        
        if let partnersAPIService = partnersAPIService {
            self.partnersAPIService = partnersAPIService
        } else {
            self.partnersAPIService = PartnersAPIService()
        }
        
        self.dataService = dataService
        
        // Si on a déjà une offre, l'utiliser directement mais aussi charger depuis l'API si on a un apiId
        if let offer = offer {
            self.offer = offer
            // Essayer de charger le partenaire depuis les données mockées
            if let partnerId = offer.partnerId {
                self.partner = dataService.getPartnerById(id: partnerId)
            }
            // Si l'offre a un apiId, charger les détails depuis l'API pour obtenir le professionalId
            if let apiId = offer.apiId {
                loadOfferDetail(id: apiId)
            }
        } else if let offerId = offerId {
            // Sinon, charger depuis l'API
            loadOfferDetail(id: offerId)
        }
    }
    
    func loadOfferDetail(id: Int) {
        print("═══════════════════════════════════════════════════════════")
        print("📥 [OFFER DETAIL] loadOfferDetail() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("📥 [OFFER DETAIL] 📍 ID de l'offre: \(id)")
        print("📥 [OFFER DETAIL] 📞 Appel backend: GET /api/v1/offers/\(id)")
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Charger les détails de l'offre depuis l'API
                let offerResponse = try await offersAPIService.getOfferDetail(id: id)
                
                print("📥 [OFFER DETAIL] ✅ Réponse reçue du backend")
                print("📥 [OFFER DETAIL] 📋 Données de l'offre reçues:")
                print("   - ID: \(offerResponse.id)")
                print("   - Title: \(offerResponse.title)")
                print("   - Description: \(offerResponse.description)")
                print("   - Type: \(offerResponse.type ?? "nil")")
                print("   - StartDate: \(offerResponse.startDate ?? "nil")")
                print("   - EndDate: \(offerResponse.endDate ?? "nil")")
                print("   - Reduction: \(offerResponse.reduction ?? "nil")")
                print("   - ImageUrl: \(offerResponse.imageUrl ?? "nil")")
                
                // Log du professional
                print("📥 [OFFER DETAIL] 👤 Informations professionnel dans la réponse:")
                if let professionalId = offerResponse.professionalId {
                    print("   - ProfessionalId (direct): \(professionalId)")
                } else {
                    print("   - ProfessionalId (direct): nil")
                }
                if let professionalName = offerResponse.professionalName {
                    print("   - ProfessionalName: \(professionalName)")
                } else {
                    print("   - ProfessionalName: nil")
                }
                if let city = offerResponse.city {
                    print("   - City: \(city)")
                }
                if let category = offerResponse.category {
                    print("   - Category: \(category)")
                }
                // Ancien format (pour compatibilité)
                if let professional = offerResponse.professional {
                    print("   - Professional (objet): présent")
                    print("     - ID: \(professional.id ?? -1)")
                    print("     - FirstName: \(professional.firstName ?? "nil")")
                    print("     - LastName: \(professional.lastName ?? "nil")")
                } else {
                    print("   - Professional (objet): absent")
                }
                
                // Convertir en modèle Offer
                let loadedOffer = offerResponse.toOffer()
                print("📥 [OFFER DETAIL] 🔄 Conversion en modèle Offer:")
                print("   - Offer ID (UUID): \(loadedOffer.id)")
                print("   - Offer apiId: \(loadedOffer.apiId != nil ? "\(loadedOffer.apiId!)" : "nil")")
                print("   - Offer title: \(loadedOffer.title)")
                print("   - Offer businessName: \(loadedOffer.businessName)")
                print("   - Offer partnerId: \(loadedOffer.partnerId?.uuidString ?? "nil")")
                print("   - Offer validUntil: \(loadedOffer.validUntil)")
                print("   - Offer offerType: \(loadedOffer.offerType.rawValue)")
                print("   - Offer isClub10: \(loadedOffer.isClub10)")
                
                self.offer = loadedOffer
                print("📥 [OFFER DETAIL] 💾 Offer stocké dans viewModel.offer")
                
                // Si l'offre a un professionnel, charger le partenaire depuis l'API
                // Priorité : professionalId direct > professional.id (ancien format)
                let professionalId: Int?
                if let directProfessionalId = offerResponse.professionalId {
                    professionalId = directProfessionalId
                    print("📥 [OFFER DETAIL] 👤 ProfessionalId détecté (format direct): \(directProfessionalId)")
                } else if let professional = offerResponse.professional, let oldProfessionalId = professional.id {
                    professionalId = oldProfessionalId
                    print("📥 [OFFER DETAIL] 👤 ProfessionalId détecté (ancien format): \(oldProfessionalId)")
                } else {
                    professionalId = nil
                }
                
                if let professionalId = professionalId {
                    self.professionalId = professionalId
                    print("📥 [OFFER DETAIL] 💾 ProfessionalId stocké dans viewModel.professionalId")
                    
                    // Charger le partenaire complet depuis l'API
                    print("📥 [OFFER DETAIL] 📞 Chargement du partenaire depuis l'API...")
                    await loadPartner(professionalId: professionalId)
                } else {
                    print("📥 [OFFER DETAIL] ⚠️ Pas de professionalId disponible - Partenaire non chargé")
                }
                
                print("📥 [OFFER DETAIL] ✅ Chargement terminé avec succès")
                print("📥 [OFFER DETAIL] 📊 État final:")
                print("   - offer != nil: \(self.offer != nil)")
                print("   - partner != nil: \(self.partner != nil)")
                print("   - professionalId: \(self.professionalId != nil ? "\(self.professionalId!)" : "nil")")
                print("═══════════════════════════════════════════════════════════")
                
                isLoading = false
            } catch {
                print("📥 [OFFER DETAIL] ❌ Erreur lors du chargement des détails de l'offre")
                print("   - Erreur: \(error)")
                print("   - Erreur localisée: \(error.localizedDescription)")
                print("═══════════════════════════════════════════════════════════")
                
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadPartner(professionalId: Int) async {
        print("📥 [OFFER DETAIL] 👤 loadPartner() - Début")
        print("   - ProfessionalId: \(professionalId)")
        print("   - Appel backend: GET /api/v1/users/\(professionalId)")
        
        do {
            let professionalResponse = try await partnersAPIService.getProfessionalById(id: professionalId)
            print("📥 [OFFER DETAIL] ✅ Réponse partenaire reçue du backend")
            print("📥 [OFFER DETAIL] 📋 Données du partenaire reçues:")
            print("   - ID: \(professionalResponse.id)")
            print("   - Email: \(professionalResponse.email)")
            print("   - FirstName: \(professionalResponse.firstName)")
            print("   - LastName: \(professionalResponse.lastName)")
            print("   - City: \(professionalResponse.city ?? "nil")")
            print("   - Address: \(professionalResponse.address ?? "nil")")
            print("   - Profession: \(professionalResponse.profession ?? "nil")")
            print("   - Category: \(professionalResponse.category?.rawValue ?? "nil")")
            print("   - EstablishmentName: \(professionalResponse.establishmentName ?? "nil")")
            print("   - EstablishmentDescription: \(professionalResponse.establishmentDescription ?? "nil")")
            print("   - EstablishmentImageUrl: \(professionalResponse.establishmentImageUrl ?? "nil")")
            print("   - PhoneNumber: \(professionalResponse.phoneNumber ?? "nil")")
            print("   - Website: \(professionalResponse.website ?? "nil")")
            print("   - Instagram: \(professionalResponse.instagram ?? "nil")")
            
            let partner = professionalResponse.toPartner()
            print("📥 [OFFER DETAIL] 🔄 Conversion en modèle Partner:")
            print("   - Partner ID (UUID): \(partner.id)")
            print("   - Partner apiId: \(partner.apiId != nil ? "\(partner.apiId!)" : "nil")")
            print("   - Partner name: \(partner.name)")
            print("   - Partner category: \(partner.category)")
            print("   - Partner city: \(partner.city)")
            print("   - Partner address: \(partner.address)")
            print("   - Partner description: \(partner.description ?? "nil")")
            print("   - Partner isFavorite: \(partner.isFavorite)")
            
            self.partner = partner
            print("📥 [OFFER DETAIL] 💾 Partner stocké dans viewModel.partner")
        } catch {
            print("📥 [OFFER DETAIL] ❌ Erreur lors du chargement du partenaire")
            print("   - Erreur: \(error)")
            print("   - Erreur localisée: \(error.localizedDescription)")
            // Ne pas bloquer l'affichage de l'offre si le partenaire ne peut pas être chargé
        }
    }
    
    /// Récupère uniquement le professionalId depuis l'API sans recharger l'offre complète
    func getProfessionalId(offerId: Int) async -> Int? {
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [OFFER DETAIL] getProfessionalId() - Début")
        print("═══════════════════════════════════════════════════════════")
        print("🔍 [OFFER DETAIL] 📍 ID de l'offre passé: \(offerId)")
        print("🔍 [OFFER DETAIL] 📞 Appel backend: GET /api/v1/offers/\(offerId)")
        
        do {
            let offerResponse = try await offersAPIService.getOfferDetail(id: offerId)
            print("🔍 [OFFER DETAIL] ✅ Réponse reçue du backend")
            print("🔍 [OFFER DETAIL] 📥 ProfessionalId (direct): \(offerResponse.professionalId != nil ? "\(offerResponse.professionalId!)" : "nil")")
            print("🔍 [OFFER DETAIL] 📥 ProfessionalName: \(offerResponse.professionalName ?? "nil")")
            print("🔍 [OFFER DETAIL] 📥 Professional (objet): \(offerResponse.professional != nil ? "présent" : "absent")")
            
            // Priorité : professionalId direct > professional.id (ancien format)
            if let directProfessionalId = offerResponse.professionalId {
                print("🔍 [OFFER DETAIL] ✅ ProfessionalId récupéré (format direct): \(directProfessionalId)")
                print("═══════════════════════════════════════════════════════════")
                return directProfessionalId
            } else if let professional = offerResponse.professional, let oldProfessionalId = professional.id {
                print("🔍 [OFFER DETAIL] ✅ ProfessionalId récupéré (ancien format): \(oldProfessionalId)")
                print("═══════════════════════════════════════════════════════════")
                return oldProfessionalId
            } else {
                print("🔍 [OFFER DETAIL] ❌ Aucun professionalId disponible dans la réponse")
                print("═══════════════════════════════════════════════════════════")
                return nil
            }
        } catch {
            print("🔍 [OFFER DETAIL] ❌ Erreur lors de la récupération du professionalId: \(error)")
            print("🔍 [OFFER DETAIL] ❌ Erreur localisée: \(error.localizedDescription)")
            print("═══════════════════════════════════════════════════════════")
            return nil
        }
    }
}

