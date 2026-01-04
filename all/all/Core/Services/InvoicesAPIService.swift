//
//  InvoicesAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Invoice Response Model (Stripe)
struct InvoiceResponse: Codable, Identifiable {
    let id: String // ID Stripe (ex: "in_1St...")
    let amountPaid: Int // Montant en centimes
    let status: String // "paid", "open", "void", "uncollectible", etc.
    let hostedInvoiceUrl: String? // URL pour afficher dans un navigateur
    let invoicePdf: String? // URL du PDF à télécharger
    let created: Int // Timestamp Unix
    let currency: String // "eur", "usd", etc.
    let number: String? // Numéro de facture (ex: "ABC1234-001")
    
    enum CodingKeys: String, CodingKey {
        case id
        case amountPaid
        case status
        case hostedInvoiceUrl
        case invoicePdf
        case created
        case currency
        case number
    }
    
    // Helper pour formater la date depuis le timestamp Unix
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(created))
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    // Helper pour formater le montant (convertir centimes en euros)
    var formattedAmount: String {
        let amountInEuros = Double(amountPaid) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: amountInEuros)) ?? String(format: "%.2f€", amountInEuros)
    }
    
    // Helper pour formater le statut en français
    var formattedStatus: String {
        switch status.lowercased() {
        case "paid":
            return "Payée"
        case "open":
            return "Ouverte"
        case "void":
            return "Annulée"
        case "uncollectible":
            return "Impayable"
        case "draft":
            return "Brouillon"
        default:
            return status.capitalized
        }
    }
    
    // Helper pour obtenir le numéro de facture ou l'ID
    var invoiceNumber: String {
        number ?? id
    }
}

// MARK: - Invoices API Service
@MainActor
class InvoicesAPIService: ObservableObject {
    private let apiService: APIServiceProtocol
    
    init(apiService: APIServiceProtocol? = nil) {
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = APIService.shared
        }
    }
    
    // MARK: - Get All Invoices (utilisateur connecté)
    func getInvoices() async throws -> [InvoiceResponse] {
        print("[InvoicesAPIService] 📞 Appel GET /api/v1/billing/invoices")
        let invoices: [InvoiceResponse] = try await apiService.request(
            endpoint: "/billing/invoices",
            method: .get,
            parameters: nil,
            headers: nil
        )
        print("[InvoicesAPIService] ✅ Factures récupérées: \(invoices.count) factures")
        return invoices
    }
    
    // MARK: - Download Invoice PDF (depuis l'URL Stripe)
    func downloadInvoicePDF(invoicePdfUrl: String) async throws -> Data {
        print("[InvoicesAPIService] 📥 Téléchargement du PDF depuis: \(invoicePdfUrl)")
        
        guard let url = URL(string: invoicePdfUrl) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Les URLs Stripe sont publiques, pas besoin d'authentification
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            print("[InvoicesAPIService] ✅ PDF téléchargé avec succès (\(data.count) bytes)")
            return data
        case 401:
            throw APIError.unauthorized(reason: nil)
        case 404:
            throw APIError.notFound
        default:
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["message"]
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
}

