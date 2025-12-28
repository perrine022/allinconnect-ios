//
//  AppColors.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

extension Color {
    // Couleurs principales
    static let appCoral = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let appRed = Color(red: 0.9, green: 0.1, blue: 0.1)
    static let appDarkRed = Color(red: 0.7, green: 0.05, blue: 0.05)
    
    // Couleurs hex personnalisées
    static let appDarkRed1 = Color(red: 0.114, green: 0.031, blue: 0.035) // #1D0809
    static let appDarkRed2 = Color(red: 0.259, green: 0.082, blue: 0.082) // #421515
    
    // Couleur sombre pour le nouveau gradient (bleu foncé/noir)
    static let appDarkBlue = Color(red: 0.05, green: 0.05, blue: 0.15) // Bleu très foncé
    static let appDark = Color(red: 0.0, green: 0.0, blue: 0.0) // Noir pur
    
    static let appPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let appMagenta = Color(red: 0.8, green: 0.2, blue: 0.6)
    static let appDarkMagenta = Color(red: 0.5, green: 0.1, blue: 0.4)
    static let appDarkPurple = Color(red: 0.3, green: 0.1, blue: 0.4)
    static let appGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let appDarkGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let appBackground = Color.black
    static let appCardBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let appTextSecondary = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let appOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
}

// MARK: - App Gradient Helper
struct AppGradient {
    /// Gradient principal de l'app : sombre en haut vers rouge en bas
    static var main: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.appDarkBlue,      // Bleu très foncé en haut
                Color.appDark,          // Noir
                Color.appDarkRed1,      // Rouge très foncé
                Color.appDarkRed2       // Rouge foncé en bas
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Gradient de test : rouge arrive à la moitié de l'écran et s'intensifie
    static var testIntense: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.appDarkBlue, location: 0.0),      // Bleu très foncé en haut (0%)
                .init(color: Color.appDark, location: 0.2),          // Noir (20%)
                .init(color: Color.appDarkRed1, location: 0.5),      // Rouge très foncé (50% - milieu de l'écran)
                .init(color: Color.appDarkRed2, location: 0.7),      // Rouge foncé (70%)
                .init(color: Color.appRed, location: 1.0)           // Rouge intense en bas (100%)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

