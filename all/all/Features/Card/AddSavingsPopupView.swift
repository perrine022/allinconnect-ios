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
    @State private var errorMessage: String? = nil
    @FocusState private var focusedField: Field?
    
    var onSave: (Double, Date, String) -> Void
    
    enum Field {
        case amount, date, store
    }
    
    var body: some View {
        ZStack {
            // Overlay sombre
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup
            VStack(spacing: 24) {
                // En-tête
                HStack {
                    Text("Ajouter une économie")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Color.appDarkRed1.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Formulaire
                VStack(spacing: 20) {
                    // Montant
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Montant (€)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            TextField("", text: $amount, prompt: Text("0.00").foregroundColor(.gray.opacity(0.6)))
                                .keyboardType(.decimalPad)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .focused($focusedField, equals: .amount)
                                .onChange(of: amount) { oldValue, newValue in
                                    // Valider que ce sont uniquement des chiffres et des points
                                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                    if filtered != newValue {
                                        amount = filtered
                                    }
                                }
                            
                            Text("€")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("", text: $date, prompt: Text("DD/MM/YYYY").foregroundColor(.gray.opacity(0.6)))
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    // Magasin
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Magasin")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("", text: $store, prompt: Text("Nom du magasin").foregroundColor(.gray.opacity(0.6)))
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                            .focused($focusedField, equals: .store)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                
                // Message d'erreur
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                // Bouton sauvegarder
                Button(action: {
                    // Valider le montant
                    guard let amountValue = Double(amount), amountValue > 0 else {
                        errorMessage = "Montant invalide"
                        return
                    }
                    
                    // Valider la date (format DD/MM/YYYY)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    dateFormatter.locale = Locale(identifier: "fr_FR")
                    
                    guard let dateValue = dateFormatter.date(from: date) else {
                        errorMessage = "Date invalide. Format attendu: DD/MM/YYYY"
                        return
                    }
                    
                    // Valider le magasin
                    guard !store.trimmingCharacters(in: .whitespaces).isEmpty else {
                        errorMessage = "Nom du magasin requis"
                        return
                    }
                    
                    errorMessage = nil
                    onSave(amountValue, dateValue, store.trimmingCharacters(in: .whitespaces))
                    isPresented = false
                }) {
                    Text("Ajouter")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValid ? Color.appGold : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appDarkRed2)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.appGold.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 30)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        
        // Valider le format de date DD/MM/YYYY
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        guard dateFormatter.date(from: date) != nil else {
            return false
        }
        
        return !store.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    AddSavingsPopupView(isPresented: .constant(true)) { amount, date, store in
        print("Saved: \(amount)€ at \(store) on \(date)")
    }
}

