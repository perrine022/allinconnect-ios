//
//  InvoicesViewModel.swift
//  all
//
//  Created by Perrine Honoré on 04/01/2026.
//

import Foundation
import Combine

@MainActor
class InvoicesViewModel: ObservableObject {
    @Published var invoices: [InvoiceResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let invoicesAPIService: InvoicesAPIService
    
    init(invoicesAPIService: InvoicesAPIService? = nil) {
        if let invoicesAPIService = invoicesAPIService {
            self.invoicesAPIService = invoicesAPIService
        } else {
            self.invoicesAPIService = InvoicesAPIService()
        }
    }
    
    func loadInvoices() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("[InvoicesViewModel] 📄 Chargement des factures...")
                invoices = try await invoicesAPIService.getInvoices()
                print("[InvoicesViewModel] ✅ \(invoices.count) factures chargées")
                isLoading = false
            } catch {
                print("[InvoicesViewModel] ❌ Erreur lors du chargement des factures: \(error)")
                errorMessage = "Erreur lors du chargement des factures: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func downloadInvoice(invoicePdfUrl: String) async throws -> Data {
        print("[InvoicesViewModel] 📥 Téléchargement du PDF depuis l'URL Stripe")
        return try await invoicesAPIService.downloadInvoicePDF(invoicePdfUrl: invoicePdfUrl)
    }
}

