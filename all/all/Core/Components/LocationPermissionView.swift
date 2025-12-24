//
//  LocationPermissionView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @ObservedObject var locationService: LocationService
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icône de localisation
            ZStack {
                Circle()
                    .fill(Color.appRed.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.appRed)
            }
            .padding(.top, 20)
            
            // Titre
            Text("Activer la géolocalisation")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text("All In Connect a besoin de votre localisation pour vous proposer les offres et partenaires les plus proches de vous.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
            
            // Bouton activer
            Button(action: {
                locationService.requestLocationPermission()
            }) {
                Text("Activer la géolocalisation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appGold)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            
            // Bouton plus tard
            Button(action: onDismiss) {
                Text("Plus tard")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 30)
        .background(Color.appDarkRed1.opacity(0.95))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 30)
    }
}

