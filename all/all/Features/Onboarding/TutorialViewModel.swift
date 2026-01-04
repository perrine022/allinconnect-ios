//
//  TutorialViewModel.swift
//  all
//
//  Created by Perrine Honoré on 26/12/2025.
//

import Foundation
import Combine

@MainActor
class TutorialViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let totalPages: Int = 5
    
    static func hasSeenTutorial() -> Bool {
        // Toujours retourner false pour forcer l'affichage du tutoriel
        return false
    }
    
    func completeTutorial() {
        // Ne plus sauvegarder pour forcer l'affichage à chaque fois
        // UserDefaults.standard.set(true, forKey: "tutorial_completed")
    }
}

