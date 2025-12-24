//
//  CustomSectorPicker.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CustomSectorPicker: View {
    let sectors: [String]
    @Binding var selectedSector: String
    var onSelectionChange: () -> Void
    @State private var isExpanded: Bool = false
    
    var filteredSectors: [String] {
        sectors.filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Champ principal
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 13))
                    
                    Text(selectedSector.isEmpty ? "Secteur..." : selectedSector)
                        .font(.system(size: 14))
                        .foregroundColor(selectedSector.isEmpty ? .gray.opacity(0.6) : .black)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Menu déroulant
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(filteredSectors.enumerated()), id: \.element) { index, sector in
                        Button(action: {
                            selectedSector = sector
                            onSelectionChange()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.system(size: 13))
                                    .opacity(0) // Invisible pour l'alignement
                                
                                Text(sector)
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                if selectedSector == sector {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appRed)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selectedSector == sector ? Color.gray.opacity(0.1) : Color.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < filteredSectors.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 34)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .zIndex(isExpanded ? 1 : 0)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack {
            CustomSectorPicker(
                sectors: ["", "Santé & bien être", "Beauté & Esthétique", "Food & plaisirs gourmands"],
                selectedSector: .constant(""),
                onSelectionChange: {}
            )
            .padding()
        }
    }
}
