//
//  ImageCropView.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let cropSize: CGSize
    @Binding var croppedImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    var onCrop: ((UIImage) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let cropFrame = CGRect(
                x: (geometry.size.width - cropSize.width) / 2,
                y: (geometry.size.height - cropSize.height) / 2,
                width: cropSize.width,
                height: cropSize.height
            )
            
            ZStack {
                // Fond sombre
                Color.black.opacity(0.7)
                
                // Image avec zoom et pan
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .gesture(
                        SimultaneousGesture(
                            // Pinch to zoom
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1.0), 4.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    // Ajuster l'offset pour garder l'image dans les limites
                                    adjustOffset(geometry: geometry, cropFrame: cropFrame)
                                },
                            // Drag to pan
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    // Ajuster l'offset pour garder l'image dans les limites
                                    adjustOffset(geometry: geometry, cropFrame: cropFrame)
                                }
                        )
                    )
                
                // Overlay avec trou carré pour le crop
                ZStack {
                    // Masque sombre avec trou transparent
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .mask(
                            ZStack {
                                Rectangle()
                                Rectangle()
                                    .frame(width: cropSize.width, height: cropSize.height)
                                    .blendMode(.destinationOut)
                            }
                        )
                    
                    // Bordure du carré de crop
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropSize.width, height: cropSize.height)
                    
                    // Coins de crop
                    VStack {
                        HStack {
                            CropCorner(position: .topLeading)
                            Spacer()
                            CropCorner(position: .topTrailing)
                        }
                        Spacer()
                        HStack {
                            CropCorner(position: .bottomLeading)
                            Spacer()
                            CropCorner(position: .bottomTrailing)
                        }
                    }
                    .frame(width: cropSize.width, height: cropSize.height)
                }
            }
            .clipped()
            .onAppear {
                // Initialiser la position et le zoom pour centrer l'image
                initializeImagePosition(geometry: geometry, cropFrame: cropFrame)
            }
        }
    }
    
    private func initializeImagePosition(geometry: GeometryProxy, cropFrame: CGRect) {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let cropAspectRatio = cropSize.width / cropSize.height
        
        // Calculer le scale initial pour remplir le carré de crop
        if imageAspectRatio > cropAspectRatio {
            // Image plus large que le crop
            scale = cropSize.height / (geometry.size.height * (imageSize.height / imageSize.width))
        } else {
            // Image plus haute que le crop
            scale = cropSize.width / (geometry.size.width * (imageSize.width / imageSize.height))
        }
        
        // Ajouter un peu de marge
        scale = scale * 1.1
        
        // Centrer l'image
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
    
    private func adjustOffset(geometry: GeometryProxy, cropFrame: CGRect) {
        let scaledWidth = geometry.size.width * scale
        let scaledHeight = geometry.size.height * scale
        
        // Calculer les limites pour garder l'image dans le carré de crop
        let minX = cropFrame.minX - (scaledWidth - cropSize.width) / 2
        let maxX = cropFrame.maxX - (scaledWidth + cropSize.width) / 2
        let minY = cropFrame.minY - (scaledHeight - cropSize.height) / 2
        let maxY = cropFrame.maxY - (scaledHeight + cropSize.height) / 2
        
        offset.width = min(max(offset.width, maxX), minX)
        offset.height = min(max(offset.height, maxY), minY)
        lastOffset = offset
    }
    
    func performCrop(geometry: GeometryProxy) -> UIImage? {
        let cropFrame = CGRect(
            x: (geometry.size.width - cropSize.width) / 2,
            y: (geometry.size.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        )
        
        // Calculer la zone de crop dans l'image originale
        let imageSize = image.size
        let viewSize = geometry.size
        
        // Calculer le scale effectif de l'image affichée
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = viewSize.width / viewSize.height
        
        var displayWidth: CGFloat
        var displayHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            displayHeight = viewSize.height
            displayWidth = displayHeight * imageAspectRatio
        } else {
            displayWidth = viewSize.width
            displayHeight = displayWidth / imageAspectRatio
        }
        
        // Appliquer le scale
        displayWidth *= scale
        displayHeight *= scale
        
        // Calculer l'offset dans l'image originale
        let offsetX = (viewSize.width - displayWidth) / 2 + offset.width
        let offsetY = (viewSize.height - displayHeight) / 2 + offset.height
        
        // Convertir les coordonnées du crop dans l'image originale
        let cropX = (cropFrame.minX - offsetX) / displayWidth * imageSize.width
        let cropY = (cropFrame.minY - offsetY) / displayHeight * imageSize.height
        let cropWidth = cropSize.width / displayWidth * imageSize.width
        let cropHeight = cropSize.height / displayHeight * imageSize.height
        
        // Effectuer le crop
        let cropRect = CGRect(
            x: max(0, cropX),
            y: max(0, cropY),
            width: min(cropWidth, imageSize.width - max(0, cropX)),
            height: min(cropHeight, imageSize.height - max(0, cropY))
        )
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            croppedImage = cropped
            onCrop?(cropped)
            return cropped
        }
        return nil
    }
}

struct CropCorner: View {
    enum Position {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
    
    let position: Position
    
    var body: some View {
        VStack {
            HStack {
                if position == .topLeading || position == .bottomLeading {
                    cornerShape
                } else {
                    Spacer()
                }
                if position == .topTrailing || position == .bottomTrailing {
                    cornerShape
                }
            }
            if position == .bottomLeading || position == .bottomTrailing {
                Spacer()
            }
        }
    }
    
    private var cornerShape: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 3)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3, height: 20)
            }
        }
    }
}

#Preview {
    if let sampleImage = UIImage(systemName: "photo") {
        ImageCropView(
            image: sampleImage,
            cropSize: CGSize(width: 300, height: 300),
            croppedImage: .constant(nil)
        )
    } else {
        Text("No preview image")
    }
}

