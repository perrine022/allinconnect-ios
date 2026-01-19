//
//  CreateOfferView.swift
//  all
//
//  Created by Perrine Honoré on 23/12/2025.
//

import SwiftUI
import PhotosUI

struct CreateOfferView: View {
    @StateObject private var viewModel = CreateOfferViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    var onOfferCreated: ((Offer) -> Void)?
    
    @State private var showCropView = false
    @State private var imageToCrop: UIImage?
    
    enum Field {
        case title, description, startDate, validUntil, discount
    }
    
    var body: some View {
        ZStack {
            // Background avec gradient : sombre en haut vers rouge en bas
            AppGradient.main
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
                            
                            ZStack(alignment: .topLeading) {
                                // Placeholder si description est vide
                                if viewModel.description.isEmpty {
                                    Text("Décrivez votre offre...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $viewModel.description)
                                    .focused($focusedField, equals: .description)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .scrollContentBackground(.hidden)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Forcer le focus sur le TextEditor
                                focusedField = .description
                                // Petit délai pour s'assurer que le focus est bien appliqué
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    focusedField = .description
                                }
                            }
                        }
                        
                        // Sélection d'image
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image de l'offre (optionnel)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            if let image = viewModel.selectedImage {
                                // Aperçu de l'image sélectionnée avec options
                                VStack(spacing: 12) {
                                    // Aperçu de l'image avec dimensions fixes (ratio 16:9)
                                    // Utiliser scaledToFit pour afficher exactement ce qui a été croppé
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width - 40, height: (UIScreen.main.bounds.width - 40) * 9 / 16)
                                        .clipped()
                                        .cornerRadius(12)
                                        .background(Color.black.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    // Boutons d'action
                                    HStack(spacing: 12) {
                                        // Bouton Modifier
                                        PhotosPicker(
                                            selection: $viewModel.selectedImageItem,
                                            matching: .images
                                        ) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "photo.badge.plus")
                                                    .font(.system(size: 14))
                                                Text("Modifier")
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.appGold)
                                            .cornerRadius(10)
                                        }
                                        
                                        // Bouton Supprimer
                                        Button(action: {
                                            viewModel.selectedImage = nil
                                            viewModel.selectedImageItem = nil
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 14))
                                                Text("Supprimer")
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            } else {
                                // Bouton pour ajouter une image
                                PhotosPicker(
                                    selection: $viewModel.selectedImageItem,
                                    matching: .images
                                ) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .foregroundColor(.gray.opacity(0.6))
                                            .font(.system(size: 24))
                                            .frame(width: 60, height: 60)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Ajouter une image")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.black)
                                            
                                            Text("Appuyez pour choisir une photo")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .onChange(of: viewModel.selectedImageItem) { oldValue, newValue in
                            // Réinitialiser le focus quand on sélectionne une image
                            focusedField = nil
                            Task {
                                if let newValue = newValue {
                                    if let data = try? await newValue.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            // Ouvrir l'écran de recadrage
                                            imageToCrop = uiImage
                                            showCropView = true
                                        }
                                    }
                                } else {
                                    await MainActor.run {
                                        viewModel.selectedImage = nil
                                    }
                                }
                            }
                        }
                        .sheet(isPresented: $showCropView) {
                            if let imageToCrop = imageToCrop {
                                NavigationView {
                                    ImageCropView(
                                        image: imageToCrop,
                                        cropRatio: 16.0 / 9.0, // Ratio 16:9 pour les offres
                                        onCrop: { croppedImage in
                                            viewModel.selectedImage = croppedImage
                                            showCropView = false
                                        },
                                        onCancel: {
                                            showCropView = false
                                            viewModel.selectedImageItem = nil
                                        }
                                    )
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Button("Fermer") {
                                                showCropView = false
                                                viewModel.selectedImageItem = nil
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Date de début
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date de début")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $viewModel.startDate, prompt: Text("JJ/MM/AAAA").foregroundColor(.gray.opacity(0.6)))
                                .focused($focusedField, equals: .startDate)
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(10)
                                .keyboardType(.numbersAndPunctuation)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .validUntil
                                }
                            
                            if !viewModel.startDate.isEmpty {
                                Text("Format: JJ/MM/AAAA (doit être après aujourd'hui)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                            }
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
                            
                            if !viewModel.validUntil.isEmpty {
                                Text("Format: JJ/MM/AAAA (doit être après la date de début)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
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
                    
                    // Message d'erreur
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                    }
                    
                    // Bouton publier
                    Button(action: {
                        hideKeyboard()
                        Task {
                            do {
                                let newOffer = try await viewModel.publishOffer()
                                // Passer l'offre créée au callback
                                onOfferCreated?(newOffer)
                                
                                // Poster une notification pour recharger les offres dans OffersView
                                NotificationCenter.default.post(name: NSNotification.Name("OfferCreated"), object: nil)
                                print("📢 [CreateOfferView] Notification 'OfferCreated' postée")
                                
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                print("Erreur lors de la création de l'offre: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Publication..." : "Publier l'offre")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background((viewModel.isValid && !viewModel.isLoading) ? Color.appGold : Color.gray.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .onTapGesture {
            // Réinitialiser le focus quand on tape ailleurs
            focusedField = nil
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

