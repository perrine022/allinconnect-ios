//
//  PartnerDetailViewModel.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine
import UIKit

@MainActor
class PartnerDetailViewModel: ObservableObject {
    @Published var partner: Partner
    @Published var currentOffers: [Offer] = []
    @Published var reviews: [Review] = []
    
    private let dataService: MockDataService
    
    init(partner: Partner, dataService: MockDataService = MockDataService.shared) {
        self.partner = partner
        self.dataService = dataService
        loadData()
    }
    
    func loadData() {
        // Charger les offres en cours pour ce partenaire
        currentOffers = dataService.getOffersForPartner(partnerId: partner.id)
        
        // Charger les avis (pour l'instant vide)
        reviews = []
    }
    
    func toggleFavorite() {
        partner.isFavorite.toggle()
    }
    
    func callPartner() {
        guard let phone = partner.phone,
              let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openEmail() {
        guard let email = partner.email,
              let url = URL(string: "mailto:\(email)") else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openWebsite() {
        guard let website = partner.website,
              let url = URL(string: website) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func openInstagram() {
        guard let instagram = partner.instagram,
              let url = URL(string: instagram) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

