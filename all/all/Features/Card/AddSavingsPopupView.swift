//
//  AddSavingsPopupView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct AddSavingsPopupView: View {
    @Binding var isPresented: Bool
    @State private var amount: String = ""
    @State private var date: String = ""
    @State private var store: String = ""
    @State private var description: String = ""
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: Field?
    
    var onSave: (Double, Date, String, String?) -> Void
    
    // Pour l'édition
    var editingEntry: SavingsEntry? = nil
    
    enum Field {
        case amount, date, store, description
    }
    
    var body: some View {
        ZStack {
            // Fond plein écran avec gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.appDarkRed2,
                    Color.appDarkRed1,
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec drag indicator
                VStack(spacing: 8) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 8)
                    
                    // En-tête avec titre et bouton fermer
                    HStack {
                        Text(editingEntry == nil ? "Ajouter une économie" : "Modifier l'économie")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 24)
                
                // Contenu scrollable
                ScrollView {
                    VStack(spacing: 24) {
                        // Formulaire
                        VStack(spacing: 20) {
                            // Montant
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Montant (€)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    TextField("0.00", text: $amount)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.black)
                                        .font(.system(size: 18, weight: .medium))
                                        .focused($focusedField, equals: .amount)
                                        .onChange(of: amount) { oldValue, newValue in
                                            // Valider que ce sont uniquement des chiffres et des points
                                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                            if filtered != newValue {
                                                amount = filtered
                                            }
                                        }
                                    
                                    Text("€")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Date
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Date")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("DD/MM/YYYY", text: $date)
                                    .keyboardType(.numbersAndPunctuation)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .focused($focusedField, equals: .date)
                                    .onChange(of: date) { oldValue, newValue in
                                        // Filtrer pour garder uniquement les chiffres
                                        let digitsOnly = newValue.filter { $0.isNumber }
                                        
                                        // Limiter à 8 chiffres (DDMMYYYY)
                                        let limited = String(digitsOnly.prefix(8))
                                        
                                        // Formater avec les slashes
                                        var formatted = ""
                                        for (index, char) in limited.enumerated() {
                                            if index == 2 || index == 4 {
                                                formatted += "/"
                                            }
                                            formatted += String(char)
                                        }
                                        
                                        date = formatted
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            
                            // Magasin
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Magasin")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Nom du magasin", text: $store)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .focused($focusedField, equals: .store)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            
                            // Description (optionnelle)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Description (optionnelle)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Description de l'économie", text: $description, axis: .vertical)
                                    .lineLimit(4...8)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .focused($focusedField, equals: .description)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Message d'erreur
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                        }
                        
                        // Bouton sauvegarder
                        Button(action: {
                        // Valider le montant
                        guard let amountValue = Double(amount), amountValue > 0 else {
                            errorMessage = "Montant invalide"
                            return
                        }
                        
                        // Utiliser la date actuelle si non remplie
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy"
                        dateFormatter.locale = Locale(identifier: "fr_FR")
                        
                        let dateValue: Date
                        if date.isEmpty {
                            dateValue = Date()
                        } else if let parsedDate = dateFormatter.date(from: date) {
                            dateValue = parsedDate
                        } else {
                            errorMessage = "Date invalide. Format attendu: DD/MM/YYYY"
                            return
                        }
                        
                        // Utiliser "Non spécifié" si le magasin n'est pas rempli
                        let storeName = store.trimmingCharacters(in: .whitespaces).isEmpty ? "Non spécifié" : store.trimmingCharacters(in: .whitespaces)
                        
                        errorMessage = nil
                        let descriptionText = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
                            onSave(amountValue, dateValue, storeName, descriptionText)
                            isPresented = false
                        }) {
                            Text(editingEntry == nil ? "Ajouter" : "Modifier")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isValid ? Color.appGold : Color.gray.opacity(0.5))
                                .cornerRadius(12)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Initialiser les champs si on édite une entrée
            if let entry = editingEntry {
                amount = String(format: "%.2f", entry.amount)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                dateFormatter.locale = Locale(identifier: "fr_FR")
                date = dateFormatter.string(from: entry.date)
                store = entry.store
                description = entry.description ?? ""
            }
        }
    }
    
    private var isValid: Bool {
        // Le bouton est activé dès qu'on a un montant valide
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return true
    }
}

#Preview {
    AddSavingsPopupView(isPresented: .constant(true)) { amount, date, store, description in
        print("Saved: \(amount)€ at \(store) on \(date) - \(description ?? "no description")")
    }
}

