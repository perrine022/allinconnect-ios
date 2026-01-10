//
//  QRCodeView.swift
//  all
//
//  Created by Perrine Honoré on 06/01/2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let urlString: String
    let size: CGFloat
    
    init(urlString: String, size: CGFloat = 200) {
        self.urlString = urlString
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let qrCodeImage = generateQRCode(from: urlString) {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                // Fallback si la génération échoue
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: size * 0.3))
                            .foregroundColor(.gray)
                    )
            }
            
            // Lien URL en dessous du QR code
            Text(urlString)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = Data(string.utf8)
        filter.message = data
        
        // Générer l'image avec une résolution appropriée
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Calculer le scale pour obtenir la taille désirée
        let scale = size / outputImage.extent.width
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCodeView(urlString: "https://allinconnect-form.vercel.app/?code=TEST123")
        .padding()
        .background(Color.white)
}

