//
//  UIImageExtensions.swift
//  all
//
//  Created by Perrine Honoré on 08/01/2026.
//

import UIKit

extension UIImage {
    /// Crop carré centré de l'image
    func centerCropSquare() -> UIImage? {
        guard let cg = self.cgImage else { return nil }
        let width = CGFloat(cg.width)
        let height = CGFloat(cg.height)
        let side = min(width, height)
        let x = (width - side) / 2
        let y = (height - side) / 2
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: side, height: side)) else { return nil }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Redimensionne l'image en carré de taille spécifiée
    func resizedSquare(to size: CGFloat) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // pour obtenir exactement size x size pixels
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
    }
    
    /// Compresse l'image en JPEG avec qualité spécifiée
    func jpegData(quality: CGFloat = 0.8) -> Data? {
        self.jpegData(compressionQuality: quality)
    }
    
    /// Pipeline complet : crop carré → resize → compress
    /// - Parameters:
    ///   - size: Taille finale en pixels (défaut: 1024)
    ///   - quality: Qualité JPEG (défaut: 0.8)
    /// - Returns: Data JPEG de l'image traitée
    func processForUpload(size: CGFloat = 1024, quality: CGFloat = 0.8) -> Data? {
        guard let cropped = self.centerCropSquare(),
              let resized = cropped.resizedSquare(to: size) else {
            return nil
        }
        return resized.jpegData(quality: quality)
    }
}

