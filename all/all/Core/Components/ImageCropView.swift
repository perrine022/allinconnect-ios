//
//  ImageCropView.swift
//  all
//
//  Created by Perrine Honoré on 17/01/2026.
//

import SwiftUI

/// Composant de recadrage d'image avec cadre fixe, pan et pinch
struct ImageCropView: View {
    let image: UIImage
    let cropRatio: CGFloat // Ratio largeur/hauteur (ex: 0.8 pour 4:5)
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var minScale: CGFloat = 1.0
    
    // Dimensions du cadre de crop et de la vue (pour le calcul du crop)
    @State private var cropFrame: CGRect = .zero
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaInsets = geometry.safeAreaInsets
            let availableWidth = geometry.size.width - 40
            let availableHeight = geometry.size.height - safeAreaInsets.top - safeAreaInsets.bottom - 120
            
            // Calculer la taille du cadre de crop selon le ratio
            let cropWidth: CGFloat = {
                if cropRatio > 0 {
                    // Ratio personnalisé (ex: 4:5 = 0.8)
                    if availableWidth / cropRatio <= availableHeight {
                        return availableWidth
                    } else {
                        return availableHeight * cropRatio
                    }
                } else {
                    // Carré
                    return min(availableWidth, availableHeight)
                }
            }()
            
            let cropHeight: CGFloat = {
                if cropRatio > 0 {
                    // Ratio personnalisé (ex: 4:5 = 0.8)
                    if availableWidth / cropRatio <= availableHeight {
                        return availableWidth / cropRatio
                    } else {
                        return availableHeight
                    }
                } else {
                    // Carré
                    return min(availableWidth, availableHeight)
                }
            }()
            
            let cropFrameCalculated = CGRect(
                x: (geometry.size.width - cropWidth) / 2,
                y: safeAreaInsets.top + (availableHeight - cropHeight) / 2,
                width: cropWidth,
                height: cropHeight
            )
            
            // Mettre à jour le cropFrame stocké
            let _ = {
                DispatchQueue.main.async {
                    cropFrame = cropFrameCalculated
                    viewSize = geometry.size
                }
            }()
            
            ZStack {
                // Fond sombre
                Color.black.opacity(0.95)
                    .ignoresSafeArea()
                
                // Image avec transformations
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                
                // Overlay avec trou pour le crop
                ZStack {
                    // Masque sombre avec trou transparent
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .mask(
                            ZStack {
                                Rectangle()
                                Rectangle()
                                    .frame(width: cropWidth, height: cropHeight)
                                    .blendMode(.destinationOut)
                            }
                        )
                    
                    // Bordure du cadre de crop
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropWidth, height: cropHeight)
                    
                    // Coins de crop
                    CropCornerView(width: cropWidth, height: cropHeight)
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
                        let newScale = scale * delta
                        // Bloquer sous minScale pour que l'image couvre toujours le cadre
                        scale = max(newScale, minScale)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        // Clamper l'offset après le zoom pour éviter les vides
                        clampOffset(geometry: geometry, cropFrame: cropFrame)
                        lastOffset = offset
                    }
            )
            .simultaneousGesture(
                // Gesture de déplacement (pan)
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Accumuler la translation depuis la dernière position
                        let newOffset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                        offset = newOffset
                    }
                    .onEnded { _ in
                        // Clamper l'offset à la fin du drag (sans recentrer)
                        clampOffset(geometry: geometry, cropFrame: cropFrame)
                        // Sauvegarder la position finale comme nouvelle position de départ
                        lastOffset = offset
                    }
            )
            .onAppear {
                cropFrame = cropFrameCalculated
                viewSize = geometry.size
                initializeImagePosition(geometry: geometry, cropFrame: cropFrameCalculated)
            }
            .onChange(of: geometry.size) { _, newSize in
                let newCropFrame = CGRect(
                    x: (newSize.width - cropWidth) / 2,
                    y: safeAreaInsets.top + (availableHeight - cropHeight) / 2,
                    width: cropWidth,
                    height: cropHeight
                )
                cropFrame = newCropFrame
                viewSize = newSize
                initializeImagePosition(geometry: geometry, cropFrame: newCropFrame)
            }
        }
        .overlay(alignment: .bottom) {
            // Boutons d'action
            HStack(spacing: 16) {
                // Bouton Annuler
                Button(action: onCancel) {
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
    }
    
    // MARK: - Initialization
    
    private func initializeImagePosition(geometry: GeometryProxy, cropFrame: CGRect) {
        // Normaliser l'image pour avoir orientation .up
        let normalizedImage = image.normalized()
        let imageSize = normalizedImage.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Calculer la taille de l'image avec scaledToFit dans la vue
        let viewWidth = geometry.size.width
        let viewHeight = geometry.size.height
        let viewAspectRatio = viewWidth / viewHeight
        
        var baseDisplayWidth: CGFloat
        var baseDisplayHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            baseDisplayWidth = viewWidth
            baseDisplayHeight = baseDisplayWidth / imageAspectRatio
        } else {
            baseDisplayHeight = viewHeight
            baseDisplayWidth = baseDisplayHeight * imageAspectRatio
        }
        
        // Calculer le scale minimum pour que l'image couvre toujours le cropRect
        let scaleForWidth = cropFrame.width / baseDisplayWidth
        let scaleForHeight = cropFrame.height / baseDisplayHeight
        minScale = max(scaleForWidth, scaleForHeight)
        
        // Initialiser avec un scale suffisamment supérieur au minimum pour permettre le mouvement
        // Utiliser un facteur plus important pour garantir qu'il y a de la marge
        scale = max(minScale * 1.2, minScale + 0.1)
        
        // Initialiser l'offset à zéro (image centrée)
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
    
    // MARK: - Constraints
    
    /// Clampe l'offset pour que l'image couvre toujours le cropRect, sans recentrer
    private func clampOffset(geometry: GeometryProxy, cropFrame: CGRect) {
        guard cropFrame.width > 0 && cropFrame.height > 0 else { return }
        
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewWidth = geometry.size.width
        let viewHeight = geometry.size.height
        let viewAspectRatio = viewWidth / viewHeight
        
        // Calculer la taille de base de l'image affichée (scaledToFit)
        var baseDisplayWidth: CGFloat
        var baseDisplayHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            baseDisplayWidth = viewWidth
            baseDisplayHeight = baseDisplayWidth / imageAspectRatio
        } else {
            baseDisplayHeight = viewHeight
            baseDisplayWidth = baseDisplayHeight * imageAspectRatio
        }
        
        // Appliquer le scale actuel
        let scaledDisplayWidth = baseDisplayWidth * scale
        let scaledDisplayHeight = baseDisplayHeight * scale
        
        // Calculer les limites de déplacement
        // L'image transformée doit toujours contenir le cropRect
        // maxOffset = (scaledSize - cropSize) / 2
        let maxOffsetX = max(0, (scaledDisplayWidth - cropFrame.width) / 2)
        let maxOffsetY = max(0, (scaledDisplayHeight - cropFrame.height) / 2)
        
        // Clamper l'offset directement (pas de recentrage)
        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        
        // S'assurer que le scale ne descend jamais sous minScale
        if scale < minScale {
            scale = minScale
            // Recalculer les limites après changement de scale
            let newScaledDisplayWidth = baseDisplayWidth * scale
            let newScaledDisplayHeight = baseDisplayHeight * scale
            let newMaxOffsetX = max(0, (newScaledDisplayWidth - cropFrame.width) / 2)
            let newMaxOffsetY = max(0, (newScaledDisplayHeight - cropFrame.height) / 2)
            offset.width = min(max(offset.width, -newMaxOffsetX), newMaxOffsetX)
            offset.height = min(max(offset.height, -newMaxOffsetY), newMaxOffsetY)
        }
    }
    
    // MARK: - Crop
    
    private func validateCrop() {
        guard let cropped = performCrop() else {
            onCancel()
            return
        }
        onCrop(cropped)
    }
    
    private func performCrop() -> UIImage? {
        // Normaliser l'image d'abord
        let normalizedImage = image.normalized()
        
        // Obtenir les dimensions réelles de l'image
        guard let cgImage = normalizedImage.cgImage else {
            return nil
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Utiliser la taille de la vue stockée
        guard viewSize.width > 0 && viewSize.height > 0 else {
            return nil
        }
        
        let viewAspectRatio = viewSize.width / viewSize.height
        
        var baseDisplayWidth: CGFloat
        var baseDisplayHeight: CGFloat
        
        if imageAspectRatio > viewAspectRatio {
            baseDisplayWidth = viewSize.width
            baseDisplayHeight = baseDisplayWidth / imageAspectRatio
        } else {
            baseDisplayHeight = viewSize.height
            baseDisplayWidth = baseDisplayHeight * imageAspectRatio
        }
        
        // Appliquer le scale actuel
        let scaledDisplayWidth = baseDisplayWidth * scale
        let scaledDisplayHeight = baseDisplayHeight * scale
        
        // Position de l'image dans la vue (centrée + offset)
        let imageDisplayX = (viewSize.width - scaledDisplayWidth) / 2 + offset.width
        let imageDisplayY = (viewSize.height - scaledDisplayHeight) / 2 + offset.height
        
        // Convertir le cropRect de la vue vers les coordonnées de l'image affichée
        let cropRectInDisplayedImage = CGRect(
            x: cropFrame.minX - imageDisplayX,
            y: cropFrame.minY - imageDisplayY,
            width: cropFrame.width,
            height: cropFrame.height
        )
        
        // Convertir vers les pixels de l'image originale
        let scaleX = imageSize.width / scaledDisplayWidth
        let scaleY = imageSize.height / scaledDisplayHeight
        
        let cropRectInOriginal = CGRect(
            x: cropRectInDisplayedImage.minX * scaleX,
            y: cropRectInDisplayedImage.minY * scaleY,
            width: cropRectInDisplayedImage.width * scaleX,
            height: cropRectInDisplayedImage.height * scaleY
        )
        
        // S'assurer que le rect est dans les limites de l'image
        let clampedRect = CGRect(
            x: max(0, cropRectInOriginal.minX),
            y: max(0, cropRectInOriginal.minY),
            width: min(cropRectInOriginal.width, imageSize.width - max(0, cropRectInOriginal.minX)),
            height: min(cropRectInOriginal.height, imageSize.height - max(0, cropRectInOriginal.minY))
        )
        
        // Effectuer le crop
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: normalizedImage.scale, orientation: .up)
    }
}

// MARK: - Crop Corner View

struct CropCornerView: View {
    let width: CGFloat
    let height: CGFloat
    let cornerLength: CGFloat = 20
    let cornerThickness: CGFloat = 3
    
    var body: some View {
        ZStack {
            // Coin haut gauche
            VStack {
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerLength, height: cornerThickness)
                    Spacer()
                }
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerThickness, height: cornerLength)
                    Spacer()
                }
                Spacer()
            }
            
            // Coin haut droit
            VStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerLength, height: cornerThickness)
                }
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerThickness, height: cornerLength)
                }
                Spacer()
            }
            
            // Coin bas gauche
            VStack {
                Spacer()
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerThickness, height: cornerLength)
                    Spacer()
                }
                HStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerLength, height: cornerThickness)
                    Spacer()
                }
            }
            
            // Coin bas droit
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerThickness, height: cornerLength)
                }
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: cornerLength, height: cornerThickness)
                }
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - UIImage Extension for Normalization

extension UIImage {
    /// Normalise l'image pour avoir une orientation .up
    func normalized() -> UIImage {
        // Si l'image est déjà en orientation .up, retourner directement
        if imageOrientation == .up {
            return self
        }
        
        // Créer un contexte graphique avec la taille de l'image
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        // Dessiner l'image dans le contexte (ce qui la normalise automatiquement)
        draw(in: CGRect(origin: .zero, size: size))
        
        // Récupérer l'image normalisée
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}



