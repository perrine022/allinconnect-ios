//
//  CreateOfferViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

@MainActor
class CreateOfferViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var startDate: String = ""
    @Published var validUntil: String = ""
    @Published var discount: String = ""
    @Published var offerType: OfferType = .offer
    @Published var isClub10: Bool = false
    @Published var imageName: String = "tag.fill"
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let offersAPIService: OffersAPIService
    
    init(offersAPIService: OffersAPIService? = nil) {
        // Créer le service dans un contexte MainActor
        if let offersAPIService = offersAPIService {
            self.offersAPIService = offersAPIService
        } else {
            self.offersAPIService = OffersAPIService()
        }
        
        // Effacer le message d'erreur quand les dates changent
        $startDate
            .dropFirst()
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
        
        $validUntil
            .dropFirst()
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    var isValid: Bool {
        // Vérifier que les champs obligatoires sont remplis
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              !description.trimmingCharacters(in: .whitespaces).isEmpty,
              !startDate.trimmingCharacters(in: .whitespaces).isEmpty,
              !validUntil.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        // Valider que les dates sont au bon format (format DD/MM/YYYY avec 10 caractères)
        // Format minimum : DD/MM/YYYY = 10 caractères
        guard startDate.count >= 10,
              validUntil.count >= 10 else {
            return false
        }
        
        // Vérifier que les dates peuvent être parsées (format valide)
        guard let startDateParsed = parseDate(startDate),
              let endDateParsed = parseDate(validUntil) else {
            return false
        }
        
        // Les dates doivent être valides (parsées correctement)
        // On ne vérifie plus si elles sont dans le futur pour permettre la publication
        // La validation stricte sera faite dans publishOffer()
        
        return true
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }
        return Calendar.current.startOfDay(for: date)
    }
    
    func publishOffer() async throws -> Offer {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        // Validation des dates avant de continuer
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        
        guard let startDateParsed = dateFormatter.date(from: startDate) else {
            errorMessage = "La date de début n'est pas au bon format (JJ/MM/AAAA)"
            throw NSError(domain: "CreateOfferError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Date de début invalide"])
        }
        
        guard let endDateParsed = dateFormatter.date(from: validUntil) else {
            errorMessage = "La date de fin n'est pas au bon format (JJ/MM/AAAA)"
            throw NSError(domain: "CreateOfferError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Date de fin invalide"])
        }
        
        // Vérifier que les dates sont après aujourd'hui
        let today = Calendar.current.startOfDay(for: Date())
        let startDateDay = Calendar.current.startOfDay(for: startDateParsed)
        let endDateDay = Calendar.current.startOfDay(for: endDateParsed)
        
        if startDateDay < today {
            errorMessage = "La date de début doit être après aujourd'hui"
            throw NSError(domain: "CreateOfferError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Date de début invalide"])
        }
        
        if endDateDay < today {
            errorMessage = "La date de fin doit être après aujourd'hui"
            throw NSError(domain: "CreateOfferError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Date de fin invalide"])
        }
        
        // Vérifier que la date de fin est après la date de début
        if endDateDay < startDateDay {
            errorMessage = "La date de fin doit être après la date de début"
            throw NSError(domain: "CreateOfferError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Dates invalides"])
        }
        
        // Convertir le type local en type API
        let apiType: String = offerType == .event ? "EVENEMENT" : "OFFRE"
        
        // Convertir les dates de DD/MM/YYYY à ISO 8601 (YYYY-MM-DDTHH:mm:ss)
        let endDate: String
        let startDateISO: String
        
        // Date de début : début de journée (00:00:00)
        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: startDateParsed)
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        if let startDateTime = Calendar.current.date(from: startComponents) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            startDateISO = isoFormatter.string(from: startDateTime)
        } else {
            // Fallback : format simple
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            startDateISO = simpleFormatter.string(from: startDateParsed) + "T00:00:00"
        }
        
        // Date de fin : fin de journée (23:59:59)
        var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: endDateParsed)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        if let endDateTime = Calendar.current.date(from: endComponents) {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            endDate = isoFormatter.string(from: endDateTime)
        } else {
            // Fallback : format simple
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            endDate = simpleFormatter.string(from: endDateParsed) + "T23:59:59"
        }
        
        // Convertir le discount en price si possible (extraire le nombre)
        let price: Double?
        if !discount.isEmpty {
            // Extraire les chiffres du discount (ex: "-50%" -> 50, "10€" -> 10)
            let numbers = discount.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            price = Double(numbers)
        } else {
            price = nil
        }
        
        // Log des données avant l'appel API
        print("📝 [CreateOffer] Préparation de la création d'offre:")
        print("   - Titre: \(title.trimmingCharacters(in: .whitespaces))")
        print("   - Description: \(description.trimmingCharacters(in: .whitespaces))")
        print("   - Prix: \(price?.description ?? "nil")")
        print("   - Date de début (ISO): \(startDateISO)")
        print("   - Date de fin (ISO): \(endDate)")
        print("   - Featured (CLUB10): \(isClub10)")
        print("   - Type: \(apiType)")
        
        // Appeler l'API pour créer l'offre
        let offerResponse = try await offersAPIService.createOffer(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            price: price,
            startDate: startDateISO,
            endDate: endDate,
            featured: isClub10, // featured = isClub10
            type: apiType
        )
        
        print("✅ [CreateOffer] Offre créée avec succès: ID=\(offerResponse.id)")
        
        // Convertir la réponse en modèle Offer
        return offerResponse.toOffer()
    }
}

