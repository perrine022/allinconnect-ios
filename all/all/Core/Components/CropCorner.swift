//
//  CropCorner.swift
//  all
//
//  Created by Perrine Honoré on 17/01/2026.
//

import SwiftUI

/// Composant pour afficher les coins du cadre de recadrage
enum CropCornerPosition {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

struct CropCorner: View {
    let position: CropCornerPosition
    let cornerLength: CGFloat = 20
    let cornerThickness: CGFloat = 3
    
    var body: some View {
        Group {
            switch position {
            case .topLeading:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerLength, height: cornerThickness)
                        Spacer()
                    }
                    HStack(alignment: .top, spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerThickness, height: cornerLength)
                        Spacer()
                    }
                }
                
            case .topTrailing:
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .top, spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerLength, height: cornerThickness)
                    }
                    HStack(alignment: .top, spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerThickness, height: cornerLength)
                    }
                }
                
            case .bottomLeading:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerThickness, height: cornerLength)
                        Spacer()
                    }
                    HStack(alignment: .bottom, spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerLength, height: cornerThickness)
                        Spacer()
                    }
                }
                
            case .bottomTrailing:
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerThickness, height: cornerLength)
                    }
                    HStack(alignment: .bottom, spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: cornerLength, height: cornerThickness)
                    }
                }
            }
        }
    }
}
