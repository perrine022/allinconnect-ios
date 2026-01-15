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
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    init(isPresented: Binding<Bool>, image: UIImage, cropSize: CGSize, croppedImage: Binding<UIImage?>) {
        self._isPresented = isPresented
        self.image = image
        self.cropSize = cropSize
        self._croppedImage = croppedImage
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let safeAreaInsets = geometry.safeAreaInsets
                let availableWidth = geometry.size.width
                let availableHeight = geometry.size.height - safeAreaInsets.top - safeAreaInsets.bottom - 120
                
                // Cadre carré de crop centré
                let cropFrameSize = min(availableWidth - 40, availableHeight - 40)
                let cropFrame = CGRect(
                    x: (availableWidth - cropFrameSize) / 2,
                    y: (availableHeight - cropFrameSize) / 2 + safeAreaInsets.top,
                    width: cropFrameSize,
                    height: cropFrameSize
                )
                
                ZStack {
                    // Fond sombre
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                    
                    // Image avec zoom et pan
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    
                    // Overlay avec trou carré pour le crop
                    ZStack {
                        // Masque sombre avec trou transparent
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .mask(
                                ZStack {
                                    Rectangle()
                                    Rectangle()
                                        .frame(width: cropFrameSize, height: cropFrameSize)
                                        .blendMode(.destinationOut)
                                }
                            )
                        
                        // Bordure du carré de crop
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropFrameSize, height: cropFrameSize)
                        
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
                        .frame(width: cropFrameSize, height: cropFrameSize)
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(
                    // Gesture de zoom (pinch)
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = min(max(scale * delta, 0.5), 5.0)
                            scale = newScale
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            constrainOffset(geometry: geometry, cropFrame: cropFrame, cropSize: cropFrameSize)
                            lastOffset = offset
                        }
                )
                .simultaneousGesture(
                    // Gesture de déplacement (drag)
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = newOffset
                        }
                        .onEnded { _ in
                            constrainOffset(geometry: geometry, cropFrame: cropFrame, cropSize: cropFrameSize)
                            lastOffset = offset
                        }
                )
                .onAppear {
                    initializeImagePosition(geometry: geometry, cropSize: cropFrameSize)
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
                        validateCrop()
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
    
    // MARK: - Initialization
    private func initializeImagePosition(geometry: GeometryProxy, cropSize: CGFloat) {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = geometry.size.width / geometry.size.height
        
        // Calculer la taille de l'image avec scaledToFit
        var baseDisplayWidth: CGFloat
        var baseDisplayHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            baseDisplayWidth = geometry.size.width
            baseDisplayHeight = baseDisplayWidth / imageAspectRatio
        } else {
            baseDisplayHeight = geometry.size.height
            baseDisplayWidth = baseDisplayHeight * imageAspectRatio
        }
        
        // Calculer le scale minimum pour remplir le carré de crop
        let scaleForWidth = cropSize / baseDisplayWidth
        let scaleForHeight = cropSize / baseDisplayHeight
        let minScale = max(scaleForWidth, scaleForHeight)
        
        // Ajouter un peu de marge pour permettre le mouvement
        scale = minScale * 1.2
        
        // Centrer l'image
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
    
    // MARK: - Constraints
    private func constrainOffset(geometry: GeometryProxy, cropFrame: CGRect, cropSize: CGFloat) {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewWidth = geometry.size.width
        let viewHeight = geometry.size.height
        
        // Calculer la taille réelle de l'image affichée (avec scaledToFit)
        var baseDisplayWidth: CGFloat
        var baseDisplayHeight: CGFloat
        
        let viewAspectRatio = viewWidth / viewHeight
        
        if imageAspectRatio > viewAspectRatio {
            baseDisplayWidth = viewWidth
            baseDisplayHeight = baseDisplayWidth / imageAspectRatio
        } else {
            baseDisplayHeight = viewHeight
            baseDisplayWidth = baseDisplayHeight * imageAspectRatio
        }
        
        // Appliquer le scale
        let scaledDisplayWidth = baseDisplayWidth * scale
        let scaledDisplayHeight = baseDisplayHeight * scale
        
        // Calculer le centre de l'image
        let imageCenterX = viewWidth / 2 + offset.width
        let imageCenterY = viewHeight / 2 + offset.height
        
        // Calculer les limites pour que le carré de crop reste rempli
        let cropCenterX = cropFrame.midX
        let cropCenterY = cropFrame.midY
        
        let minImageCenterX = cropCenterX - (scaledDisplayWidth / 2 - cropSize / 2)
        let maxImageCenterX = cropCenterX + (scaledDisplayWidth / 2 - cropSize / 2)
        let minImageCenterY = cropCenterY - (scaledDisplayHeight / 2 - cropSize / 2)
        let maxImageCenterY = cropCenterY + (scaledDisplayHeight / 2 - cropSize / 2)
        
        // Clamper le centre de l'image
        let constrainedCenterX = min(max(imageCenterX, maxImageCenterX), minImageCenterX)
        let constrainedCenterY = min(max(imageCenterY, maxImageCenterY), minImageCenterY)
        
        // Convertir en offset
        offset.width = constrainedCenterX - viewWidth / 2
        offset.height = constrainedCenterY - viewHeight / 2
    }
    
    // MARK: - Crop & Process
    private func validateCrop() {
        // Calculer le rectangle de crop dans les coordonnées de l'image originale
        guard let cropped = performCrop() else {
            isPresented = false
            return
        }
        
        // Pipeline : crop → resize 1024x1024
        // La compression JPEG sera faite au moment de l'upload
        if let resized = cropped.resizedSquare(to: 1024) {
            croppedImage = resized
        } else {
            // Fallback : utiliser l'image croppée directement
            croppedImage = cropped
        }
        
        isPresented = false
    }
    
    private func performCrop() -> UIImage? {
        let imageSize = image.size
        let viewSize = UIScreen.main.bounds.size
        
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
        
        // Calculer le carré de crop (centré sur l'écran)
        let cropSize = min(viewSize.width - 40, viewSize.height - 160)
        let cropFrame = CGRect(
            x: (viewSize.width - cropSize) / 2,
            y: (viewSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )
        
        // Convertir les coordonnées du crop dans l'image originale
        let offsetX = (viewSize.width - displayWidth) / 2
        let offsetY = (viewSize.height - displayHeight) / 2
        
        let cropX = (cropFrame.minX - offsetX - offset.width) / displayWidth * imageSize.width
        let cropY = (cropFrame.minY - offsetY - offset.height) / displayHeight * imageSize.height
        let cropWidth = cropSize / displayWidth * imageSize.width
        let cropHeight = cropSize / displayHeight * imageSize.height
        
        // Effectuer le crop
        let cropRect = CGRect(
            x: max(0, cropX),
            y: max(0, cropY),
            width: min(cropWidth, imageSize.width - max(0, cropX)),
            height: min(cropHeight, imageSize.height - max(0, cropY))
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
