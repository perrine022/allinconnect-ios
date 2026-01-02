//
//  InvoicesAPIService.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import Foundation
import Combine

// MARK: - Invoice Response Model
struct InvoiceResponse: Codable, Identifiable {
    let id: Int
    let invoiceNumber: String
    let date: String // Format ISO ou YYYY-MM-DD
    let amount: Double
    let status: String? // "PAID", "PENDING", etc.
    
    enum CodingKeys: String, CodingKey {
        case id
        case invoiceNumber = "invoiceNumber"
        case date
        case amount
        case status
    }
    
    // Helper pour formater la date
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let dateObj = dateFormatter.date(from: date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy"
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: dateObj)
        }
        
        // Essayer avec format ISO
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        if let dateObj = isoFormatter.date(from: date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy"
            displayFormatter.locale = Locale(identifier: "fr_FR")
            return displayFormatter.string(from: dateObj)
        }
        
        return date
    }
    
    // Helper pour formater le montant
    var formattedAmount: String {
        String(format: "%.2f€", amount)
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
    
    // MARK: - Get All Invoices
    func getInvoices() async throws -> [InvoiceResponse] {
        print("[InvoicesAPIService] 📞 Appel GET /api/v1/invoices")
        let invoices: [InvoiceResponse] = try await apiService.request(
            endpoint: "/invoices",
            method: .get,
            parameters: nil,
            headers: nil
        )
        print("[InvoicesAPIService] ✅ Factures récupérées: \(invoices.count) factures")
        return invoices
    }
    
    // MARK: - Download Invoice PDF
    func downloadInvoicePDF(invoiceId: Int) async throws -> Data {
        print("[InvoicesAPIService] 📥 Téléchargement PDF facture ID: \(invoiceId)")
        
        guard let url = URL(string: "\(APIConfig.baseURL)/invoices/\(invoiceId)/download") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Ajouter l'Authorization header
        if let token = AuthTokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Accepter PDF
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")
        
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

