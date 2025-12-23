//
//  FooterBar.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct FooterBar: View {
    @Binding var selectedTab: TabItem
    let onTabSelected: (TabItem) -> Void
    
    init(
        selectedTab: Binding<TabItem>,
        onTabSelected: @escaping (TabItem) -> Void
    ) {
        self._selectedTab = selectedTab
        self.onTabSelected = onTabSelected
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    onTabSelected(tab)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .appRed : Color(red: 0.7, green: 0.7, blue: 0.7))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .appRed : Color(red: 0.7, green: 0.7, blue: 0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appDarkRed1, // #1D0809
                    Color.appDarkRed2  // #421515
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.appBackground.ignoresSafeArea()
        
        FooterBar(selectedTab: .constant(.home)) { tab in
            print("Selected: \(tab)")
        }
    }
}

