//
//  ImageZoomView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct ImageZoomView: View {
    let imageUrl: String?
    let profileImageName: String
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Image avec zoom et pan
            Group {
                if let imageUrl = ImageURLHelper.buildImageURL(from: imageUrl),
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let delta = value / lastScale
                                                lastScale = value
                                                scale = min(max(scale * delta, 1.0), 4.0)
                                            }
                                            .onEnded { _ in
                                                lastScale = 1.0
                                                if scale < 1.0 {
                                                    withAnimation {
                                                        scale = 1.0
                                                        offset = .zero
                                                        lastOffset = .zero
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                lastOffset = offset
                                            }
                                    )
                                )
                        case .failure:
                            Image(systemName: profileImageName)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.5))
                        @unknown default:
                            Image(systemName: profileImageName)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                } else {
                    Image(systemName: profileImageName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bouton fermer
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            // Double tap pour réinitialiser le zoom
            withAnimation {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
    }
}
