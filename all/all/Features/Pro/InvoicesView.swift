//
//  InvoicesView.swift
//  all
//
//  Created by Perrine Honoré on 04/01/2026.
//

import SwiftUI
import QuickLook
import UIKit

struct InvoicesView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InvoicesViewModel()
    @State private var selectedInvoicePDF: URL?
    @State private var showPDFPreview = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Titre avec bouton retour
                            HStack {
                                // Bouton retour
                                Button(action: {
                                    dismiss()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Retour")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                Text("Factures")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Espace invisible pour équilibrer le bouton retour
                                Color.clear
                                    .frame(width: 80)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Indicateur de chargement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            }
                            
                            // Message d'erreur
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Liste des factures
                            if !viewModel.invoices.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.invoices) { invoice in
                                        InvoiceCard(invoice: invoice) {
                                            if let invoicePdf = invoice.invoicePdf {
                                                Task {
                                                    await downloadAndShowInvoice(invoicePdfUrl: invoicePdf)
                                                }
                                            } else {
                                                // Si pas de PDF, ouvrir l'URL hébergée dans le navigateur
                                                if let hostedUrl = invoice.hostedInvoiceUrl, let url = URL(string: hostedUrl) {
                                                    UIApplication.shared.open(url)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else if !viewModel.isLoading && viewModel.errorMessage == nil {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text("Aucune facture disponible")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 40)
                            }
                            
                            // Espace pour le footer
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {
                            dismiss()
                        })
                    }
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadInvoices()
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfURL = selectedInvoicePDF {
                PDFPreviewView(url: pdfURL)
            }
        }
    }
    
    private func downloadAndShowInvoice(invoicePdfUrl: String) async {
        do {
            let pdfData = try await viewModel.downloadInvoice(invoicePdfUrl: invoicePdfUrl)
            
            // Extraire l'ID de la facture depuis l'URL pour le nom du fichier
            let invoiceId = invoicePdfUrl.components(separatedBy: "/").last?.components(separatedBy: ".").first ?? "invoice"
            
            // Sauvegarder temporairement le PDF
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("invoice_\(invoiceId).pdf")
            try pdfData.write(to: tempURL)
            
            await MainActor.run {
                selectedInvoicePDF = tempURL
                showPDFPreview = true
            }
        } catch {
            print("[InvoicesView] ❌ Erreur lors du téléchargement: \(error)")
        }
    }
}

struct InvoiceCard: View {
    let invoice: InvoiceResponse
    let onDownload: () -> Void
    
    var body: some View {
        Button(action: onDownload) {
            HStack(spacing: 16) {
                // Icône facture
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                
                // Informations facture
                VStack(alignment: .leading, spacing: 6) {
                    Text("Facture \(invoice.invoiceNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(invoice.formattedDate)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(invoice.formattedStatus)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(invoice.status.lowercased() == "paid" ? .green : .orange)
                }
                
                Spacer()
                
                // Montant
                VStack(alignment: .trailing, spacing: 4) {
                    Text(invoice.formattedAmount)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(Color.appDarkRed1.opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

#Preview {
    NavigationStack {
        InvoicesView()
            .environmentObject(AppState())
    }
}

