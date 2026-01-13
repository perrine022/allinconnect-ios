//
//  AnimatedSplashView.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI
#if canImport(Lottie)
import Lottie
#endif

struct AnimatedSplashView: View {
    @State private var goNext = false
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @Binding var hasSeenTutorial: Bool
    @Binding var isLoggedIn: Bool
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas (comme l'app)
            AppGradient.main
                .ignoresSafeArea()
            
            #if canImport(Lottie)
            // Animation Lottie si disponible
            LottieView(name: "splash", loopMode: .playOnce)
                .frame(width: 220, height: 220)
            #else
            // Animation manuelle en fallback
            if let logoImage = UIImage(named: "logo") ?? UIImage(named: "AppIcon") {
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
            } else {
                // Fallback avec logo textuel
                VStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("ALL")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        ZStack {
                            Circle().fill(Color.red).frame(width: 22, height: 22)
                            Circle().fill(Color.red.opacity(0.6)).frame(width: 19, height: 19)
                            Circle().fill(Color.red.opacity(0.3)).frame(width: 16, height: 16)
                        }
                        Text("IN")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text("Connect")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
            }
            #endif
        }
        .onAppear {
            #if canImport(Lottie)
            // Durée calée sur 120 frames à 60fps = 2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                goNext = true
            }
            #else
            // Animation manuelle : fade-in + zoom "pop"
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 1.1
                opacity = 1.0
            }
            
            // Respiration légère + micro rotation
            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                scale = 0.98
                rotation = -3
            }
            
            // Retour à la normale
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 1.0
                rotation = 0
            }
            
            // Fade-out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.25)) {
                    opacity = 0.0
                }
            }
            
            // Passer à l'app après 2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                goNext = true
            }
            #endif
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

