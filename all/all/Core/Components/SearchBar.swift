//
//  SearchBar.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Rechercher..."
    var onTextChange: ((String) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
                .foregroundColor(.white)
                .tint(.appCoral)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: text) { _, newValue in
                    onTextChange?(newValue)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appDarkGray.opacity(0.6))
        .cornerRadius(10)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        SearchBar(
            text: .constant(""),
            placeholder: "Rechercher un professionnel..."
        )
        .padding()
    }
}











