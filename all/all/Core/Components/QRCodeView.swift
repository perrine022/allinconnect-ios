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
    @State private var showCopiedMessage = false
    
    init(urlString: String, size: CGFloat = 200) {
        self.urlString = urlString
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Champ avec bouton de copie
            HStack(spacing: 8) {
                // Champ de texte avec le lien
                TextField("", text: .constant(urlString))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(true)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Bouton de copie
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedMessage ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                        if showCopiedMessage {
                            Text("Copié")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, showCopiedMessage ? 12 : 10)
                    .padding(.vertical, 10)
                    .background(showCopiedMessage ? Color.green : Color.red)
                    .cornerRadius(8)
                }
                .animation(.easeInOut(duration: 0.2), value: showCopiedMessage)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = urlString
        showCopiedMessage = true
        
        // Réinitialiser le message après 2 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
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

