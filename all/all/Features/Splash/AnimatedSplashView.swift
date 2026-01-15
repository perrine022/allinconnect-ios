//
//  AnimatedSplashView.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI

struct AnimatedSplashView: View {
    @State private var goNext = false
    @Binding var hasSeenTutorial: Bool
    @Binding var isLoggedIn: Bool
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        ZStack {
            // Fond noir uni
            Color.black
                .ignoresSafeArea()
            
            // Logo centré
            VStack {
                Spacer()
                
                // Logo simple au centre - taille réduite
                if let logoImage = UIImage(named: "logo") ?? UIImage(named: "AppIcon") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 120, maxHeight: 120)
                } else {
                    // Fallback avec logo textuel
                    VStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Text("ALL")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            ZStack {
                                Circle().fill(Color.red).frame(width: 14, height: 14)
                                Circle().fill(Color.red.opacity(0.6)).frame(width: 12, height: 12)
                                Circle().fill(Color.red.opacity(0.3)).frame(width: 10, height: 10)
                            }
                            Text("IN")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Text("Connect")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Passer à l'app après 2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                goNext = true
            }
        }
        .fullScreenCover(isPresented: $goNext) {
            AppContentView(
                hasSeenTutorial: $hasSeenTutorial,
                isLoggedIn: $isLoggedIn,
                locationService: locationService
            )
        }
    }
}

