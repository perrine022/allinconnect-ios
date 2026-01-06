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
    let totalPages: Int = 4
    
    static func hasSeenTutorial() -> Bool {
        // Vérifier si l'utilisateur a déjà vu le tutoriel
        return UserDefaults.standard.bool(forKey: "tutorial_completed")
    }
    
    func completeTutorial() {
        // Sauvegarder que le tutoriel a été complété
        UserDefaults.standard.set(true, forKey: "tutorial_completed")
    }
}

