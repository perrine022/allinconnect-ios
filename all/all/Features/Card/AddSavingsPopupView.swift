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
    @State private var selectedDate: Date = Date()
    @State private var store: String = ""
    @FocusState private var focusedField: Field?
    
    var onSave: (Double, Date, String) -> Void
    
    enum Field {
        case amount, store
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
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .accentColor(.appGold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.appDarkRed1.opacity(0.6))
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
                
                // Bouton sauvegarder
                Button(action: {
                    if let amountValue = Double(amount), amountValue > 0, !store.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSave(amountValue, selectedDate, store.trimmingCharacters(in: .whitespaces))
                        isPresented = false
                    }
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
        return !store.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    AddSavingsPopupView(isPresented: .constant(true)) { amount, date, store in
        print("Saved: \(amount)€ at \(store) on \(date)")
    }
}

