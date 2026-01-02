//
//  FilterSheet.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct FilterSheet: View {
    let title: String
    let items: [String]
    let selectedItem: String
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    ForEach(items, id: \.self) { item in
                        Button(action: {
                            onSelect(item)
                        }) {
                            HStack {
                                Text(item)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                Spacer()
                                if item == selectedItem {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.appCoral)
                                }
                            }
                        }
                        .listRowBackground(Color.appDarkGray.opacity(0.3))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        isPresented = false
                    }
                    .foregroundColor(.appCoral)
                }
            }
        }
    }
}

#Preview {
    FilterSheet(
        title: "Catégorie",
        items: ["Toutes", "Beauté", "Alimentation", "Automobile"],
        selectedItem: "Toutes",
        isPresented: .constant(true),
        onSelect: { _ in }
    )
}








