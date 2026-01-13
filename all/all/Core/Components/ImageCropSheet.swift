//
//  ImageCropSheet.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import SwiftUI

struct ImageCropSheet: View {
    @Binding var isPresented: Bool
    let image: UIImage
    let cropSize: CGSize
    @Binding var croppedImage: UIImage?
    @State private var currentImage: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var geometrySize: CGSize = .zero
    
    init(isPresented: Binding<Bool>, image: UIImage, cropSize: CGSize, croppedImage: Binding<UIImage?>) {
        self._isPresented = isPresented
        self.image = image
        self.cropSize = cropSize
        self._croppedImage = croppedImage
        self._currentImage = State(initialValue: image)
    }
    
    var body: some View {
        NavigationView {
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
                    Image(uiImage: currentImage)
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
                    geometrySize = geometry.size
                    initializeImagePosition(geometry: geometry, cropFrame: cropFrame)
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    geometrySize = newValue
                }
            }
            .overlay(alignment: .bottom) {
                // Boutons d'action
                HStack(spacing: 16) {
                    // Bouton Annuler
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Annuler")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(12)
                    }
                    
                    // Bouton Valider
                    Button(action: {
                        // Effectuer le crop avant de fermer
                        let cropFrame = CGRect(
                            x: (geometrySize.width - cropSize.width) / 2,
                            y: (geometrySize.height - cropSize.height) / 2,
                            width: cropSize.width,
                            height: cropSize.height
                        )
                        if let cropped = performCrop(geometrySize: geometrySize, cropFrame: cropFrame) {
                            croppedImage = cropped
                        }
                        isPresented = false
                    }) {
                        Text("Valider")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.appGold)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Ajuster l'image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func initializeImagePosition(geometry: GeometryProxy, cropFrame: CGRect) {
        let imageSize = currentImage.size
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
        let imageSize = currentImage.size
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
    
    private func performCrop(geometrySize: CGSize, cropFrame: CGRect) -> UIImage? {
        let imageSize = currentImage.size
        let viewSize = geometrySize
        
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
        
        if let cgImage = currentImage.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: currentImage.scale, orientation: currentImage.imageOrientation)
        }
        return nil
    }
}

