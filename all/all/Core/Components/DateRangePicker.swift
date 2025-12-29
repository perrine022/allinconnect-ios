//
//  DateRangePicker.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct DateRangePicker: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @State private var isExpanded: Bool = false
    @State private var showStartDatePicker: Bool = false
    @State private var showEndDatePicker: Bool = false
    @State private var tempStartDate: Date = Date()
    @State private var tempEndDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Bouton "Offres à venir" qui ouvre/ferme les filtres
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.appRed)
                            .font(.system(size: 16))
                        
                        if let start = startDate, let end = endDate {
                            Text("Du \(formatDate(start)) au \(formatDate(end))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("Offres à venir")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bouton pour réinitialiser si des dates sont sélectionnées (en dehors du bouton principal)
                if (startDate != nil || endDate != nil) && !isExpanded {
                    Button(action: {
                        startDate = nil
                        endDate = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.system(size: 16))
                            .padding(.trailing, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Contenu des filtres (affiché seulement si expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 4)
                    
                    // Sélection de la date de début
                    Button(action: {
                        if let start = startDate {
                            tempStartDate = start
                        }
                        showStartDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.appRed)
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Date de début")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.8))
                                
                                Text(startDate != nil ? formatDate(startDate!) : "Sélectionner")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(startDate != nil ? .white : .gray.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Sélection de la date de fin
                    Button(action: {
                        if let end = endDate {
                            tempEndDate = end
                        } else if let start = startDate {
                            // Si on a une date de début, initialiser la date de fin à la même date
                            tempEndDate = start
                        }
                        showEndDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.appRed)
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Date de fin")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.8))
                                
                                Text(endDate != nil ? formatDate(endDate!) : "Sélectionner")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(endDate != nil ? .white : .gray.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Bouton Valider
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Valider")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Color.appRed)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.top, 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appDarkRed1.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appRed.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showStartDatePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "Date de début",
                        selection: $tempStartDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.appRed)
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Date de début")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annuler") {
                            showStartDatePicker = false
                        }
                        .foregroundColor(.appRed)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Valider") {
                            startDate = tempStartDate
                            // Si la date de fin est avant la nouvelle date de début, la réinitialiser
                            if let end = endDate, end < tempStartDate {
                                endDate = nil
                            }
                            showStartDatePicker = false
                            // Ne pas fermer le bloc ici, l'utilisateur peut vouloir sélectionner la date de fin
                        }
                        .foregroundColor(.appRed)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showEndDatePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "Date de fin",
                        selection: $tempEndDate,
                        in: (startDate ?? Date())...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.appRed)
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Date de fin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annuler") {
                            showEndDatePicker = false
                        }
                        .foregroundColor(.appRed)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Valider") {
                            endDate = tempEndDate
                            showEndDatePicker = false
                        }
                        .foregroundColor(.appRed)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        DateRangePicker(startDate: .constant(nil), endDate: .constant(nil))
            .padding()
    }
}

