//
//  FilterButton.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct FilterButton: View {
    let icon: String
    let title: String
    let selectedValue: String?
    let placeholder: String
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        selectedValue: String? = nil,
        placeholder: String = "",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.selectedValue = selectedValue
        self.placeholder = placeholder
        self.action = action
    }
    
    var displayText: String {
        if let selectedValue = selectedValue, selectedValue != placeholder {
            return selectedValue
        }
        return title
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(displayText)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.appDarkGray.opacity(0.6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    HStack {
        FilterButton(
            icon: "line.3.horizontal.decrease.circle",
            title: "Catégorie",
            selectedValue: nil,
            placeholder: "Toutes",
            action: {}
        )
        
        FilterButton(
            icon: "mappin.circle",
            title: "Ville",
            selectedValue: "Paris",
            placeholder: "Toutes",
            action: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}











