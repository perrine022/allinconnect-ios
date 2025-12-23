//
//  AppState.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var selectedTab: TabItem = .home
    
    func navigateToTab(_ tab: TabItem) {
        selectedTab = tab
    }
}

