//
//  LottieView.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI
#if canImport(Lottie)
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.contentMode = .scaleAspectFit
        view.loopMode = loopMode
        view.clipsToBounds = true // Empêcher le débordement
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // S'assurer que la vue respecte les contraintes
        uiView.contentMode = .scaleAspectFit
        uiView.clipsToBounds = true
    }
}
#else
// Fallback si Lottie n'est pas disponible
struct LottieView: View {
    let name: String
    let loopMode: LottieLoopMode
    
    var body: some View {
        // Afficher une image statique en fallback
        if let image = UIImage(named: "logo") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 100))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
#endif

