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
    var showProfileBadge: Bool = false
    
    init(
        selectedTab: Binding<TabItem>,
        onTabSelected: @escaping (TabItem) -> Void,
        showProfileBadge: Bool = false
    ) {
        self._selectedTab = selectedTab
        self.onTabSelected = onTabSelected
        self.showProfileBadge = showProfileBadge
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                    onTabSelected(tab)
                }) {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .red : Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .red : Color(red: 0.7, green: 0.7, blue: 0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        
                        // Badge rouge sur l'onglet profil
                        if tab == .profile && showProfileBadge {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -2)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 0)
        .padding(.top, 6)
        .padding(.bottom, 8)
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

