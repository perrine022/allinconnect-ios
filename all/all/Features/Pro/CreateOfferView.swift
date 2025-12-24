//
//  CreateOfferView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI

struct CreateOfferView: View {
    @StateObject private var viewModel = CreateOfferViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    var onOfferCreated: ((Offer) -> Void)?
    
    enum Field {
        case title, description, validUntil, discount
    }
    
    var body: some View {
        ZStack {
            // Background avec gradient
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Titre
                    Text("Créer une offre")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Formulaire
                    VStack(spacing: 20) {
                        // Titre de l'offre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titre de l'offre")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.title, prompt: Text("Ex: -50% sur l'abonnement").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .title)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .description
                                }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextEditor(text: $viewModel.description)
                                .focused($focusedField, equals: .description)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .scrollContentBackground(.hidden)
                        }
                        
                        // Date de validité
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Valable jusqu'au")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.validUntil, prompt: Text("JJ/MM/AAAA").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .validUntil)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                                .keyboardType(.numbersAndPunctuation)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .discount
                                }
                        }
                        
                        // Réduction
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Réduction (optionnel)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.discount, prompt: Text("Ex: -50%").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .discount)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        // Type d'offre
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type d'offre")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.offerType = .offer
                                }) {
                                    HStack {
                                        Text("Offre")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(viewModel.offerType == .offer ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.offerType == .offer ? Color.appGold : Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    viewModel.offerType = .event
                                }) {
                                    HStack {
                                        Text("Événement")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(viewModel.offerType == .event ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.offerType == .event ? Color.appRed : Color.appDarkRed1.opacity(0.6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Checkbox CLUB10
                        Button(action: {
                            viewModel.isClub10.toggle()
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(viewModel.isClub10 ? Color.appRed : Color.clear)
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.white, lineWidth: 1.5)
                                        )
                                    
                                    if viewModel.isClub10 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                }
                                
                                Image(systemName: "star.fill")
                                    .foregroundColor(.appGold)
                                    .font(.system(size: 14))
                                
                                Text("Offre réservée aux membres CLUB10")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.appDarkRed1.opacity(0.6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Bouton publier
                    Button(action: {
                        hideKeyboard()
                        let newOffer = viewModel.publishOffer()
                        // Passer l'offre créée au callback
                        onOfferCreated?(newOffer)
                        dismiss()
                    }) {
                        Text("Publier l'offre")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.isValid ? Color.appGold : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationButton(icon: "arrow.left", action: { dismiss() })
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateOfferView()
    }
}

