//
//  ManageSubscriptionsView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import UIKit

struct ManageSubscriptionsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManageSubscriptionsViewModel()
    @State private var showCancelAlert = false
    @State private var modifySubscriptionNavigationId: UUID?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background avec gradient : sombre en haut vers rouge en bas
                    AppGradient.main
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Titre
                            HStack {
                                Text("Gérer mes abonnements")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Indicateur de chargement
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding()
                            }
                            
                            // Abonnement actuel
                            if viewModel.currentSubscriptionPlan != nil {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 18))
                                        
                                        Text("Abonnement actuel")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    VStack(spacing: 12) {
                                        HStack {
                                            Text("Formule")
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Spacer()
                                            
                                            Text(viewModel.currentFormula)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.red)
                                        }
                                        
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                        
                                        HStack {
                                            Text("Montant")
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Spacer()
                                            
                                            Text(viewModel.currentAmount.isEmpty ? "N/A" : viewModel.currentAmount)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        if !viewModel.nextPaymentDate.isEmpty {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                            
                                            HStack {
                                                Text("Prochain paiement")
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Spacer()
                                                
                                                Text(viewModel.nextPaymentDate)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        if !viewModel.commitmentUntil.isEmpty {
                                            Divider()
                                                .background(Color.white.opacity(0.1))
                                            
                                            HStack {
                                                Text("Valable jusqu'au")
                                                    .font(.system(size: 14, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Spacer()
                                                
                                                Text(viewModel.commitmentUntil)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.appDarkRed1.opacity(0.8))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // Message d'erreur
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Message de succès
                            if let successMessage = viewModel.billingViewModel.successMessage {
                                Text(successMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Section Mes factures (uniquement pour les pros)
                            // Déterminer si l'utilisateur est pro
                            let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
                            let isPro = userTypeString == "PRO"
                            
                            if isPro {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 18))
                                        
                                        Text("Mes factures")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    if viewModel.isLoadingInvoices {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else if viewModel.invoices.isEmpty {
                                        Text("Aucune facture disponible")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.vertical, 12)
                                    } else {
                                        VStack(spacing: 12) {
                                            ForEach(viewModel.invoices) { invoice in
                                                InvoiceRow(
                                                    invoice: invoice,
                                                    isDownloading: viewModel.isDownloadingInvoice,
                                                    onDownload: {
                                                        Task {
                                                            await viewModel.downloadInvoice(invoiceId: invoice.id)
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    
                                    if let invoiceError = viewModel.invoiceErrorMessage {
                                        Text(invoiceError)
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                                .padding(16)
                                .background(Color.appDarkRed1.opacity(0.8))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Boutons d'action (uniquement si l'utilisateur a un abonnement actif et non résilié)
                            // Vérifier que l'abonnement n'est pas déjà résilié
                            let isSubscriptionCancelled = viewModel.subscriptionStatus == "CANCELLED" || 
                                                          viewModel.subscriptionStatus == "CANCELED"
                            
                            if viewModel.currentSubscriptionPlan != nil && !isSubscriptionCancelled {
                                VStack(spacing: 12) {
                                    // Bouton Modifier mon abonnement
                                    Button(action: {
                                        modifySubscriptionNavigationId = UUID()
                                    }) {
                                        Text("Modifier mon abonnement")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.appGold)
                                            .cornerRadius(12)
                                    }
                                    
                                    // Bouton Résilier mon abonnement
                                    Button(action: {
                                        showCancelAlert = true
                                    }) {
                                        Text("Résilier mon abonnement")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.red, lineWidth: 1.5)
                                            )
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Message si pas d'abonnement
                            if viewModel.currentSubscriptionPlan == nil && !viewModel.isLoading {
                                VStack(spacing: 12) {
                                    Text("Aucun abonnement actif")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Vous n'avez pas d'abonnement en cours. Choisissez un plan pour commencer.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(Color.appDarkRed1.opacity(0.6))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadSubscriptionData()
            // Charger les factures si l'utilisateur est pro
            let userTypeString = UserDefaults.standard.string(forKey: "user_type") ?? "CLIENT"
            if userTypeString == "PRO" {
                await viewModel.loadInvoices()
            }
        }
        .alert("Résilier l'abonnement", isPresented: $showCancelAlert) {
            Button("Annuler", role: .cancel) { }
            Button("À la fin de la période", role: .none) {
                Task {
                    await viewModel.cancelSubscription(atPeriodEnd: true)
                }
            }
            Button("Immédiatement", role: .destructive) {
                Task {
                    await viewModel.cancelSubscription(atPeriodEnd: false)
                }
            }
        } message: {
            Text("Choisissez le type de résiliation :\n\n• À la fin de la période : Vous gardez l'accès jusqu'à la fin de la période payée.\n• Immédiatement : L'accès sera coupé tout de suite.")
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let fileURL = viewModel.downloadedInvoiceURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
        .navigationDestination(item: $modifySubscriptionNavigationId) { _ in
            ModifySubscriptionView(currentPlanId: viewModel.currentSubscriptionPlan?.id)
                .environmentObject(appState)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Invoice Row Component
struct InvoiceRow: View {
    let invoice: InvoiceResponse
    let isDownloading: Bool
    let onDownload: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône facture
            Image(systemName: "doc.text.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color.red.opacity(0.2))
                .clipShape(Circle())
            
            // Informations de la facture
            VStack(alignment: .leading, spacing: 4) {
                Text("Facture \(invoice.invoiceNumber)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(invoice.formattedDate)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(invoice.formattedAmount)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Bouton télécharger
            Button(action: onDownload) {
                if isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
            }
            .disabled(isDownloading)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ManageSubscriptionsView()
            .environmentObject(AppState())
    }
}

