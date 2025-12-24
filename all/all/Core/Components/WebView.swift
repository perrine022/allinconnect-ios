//
//  WebView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

struct StripePaymentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = true
    
    // URL Stripe - à remplacer par votre vrai lien Stripe Checkout
    // Exemple: "https://buy.stripe.com/votre-lien-checkout"
    // Ou votre propre page de paiement intégrée avec Stripe Elements
    private let stripeURL = URL(string: "https://buy.stripe.com/test")! // TODO: Remplacer par votre vrai lien Stripe
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()
                    
                    // WebView
                    WebView(url: stripeURL, isLoading: $isLoading)
                        .opacity(isLoading ? 0 : 1)
                    
                    // Loading indicator
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appGold))
                                .scaleEffect(1.5)
                            
                            Text("Chargement...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                // Footer Bar - toujours visible
                VStack {
                    Spacer()
                    FooterBar(selectedTab: $appState.selectedTab) { tab in
                        appState.navigateToTab(tab, dismiss: {})
                    }
                    .frame(width: geometry.size.width)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle("Paiement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        StripePaymentView()
            .environmentObject(AppState())
    }
}

