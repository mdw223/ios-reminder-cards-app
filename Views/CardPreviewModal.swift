import SwiftUI

struct CardPreviewModal: View {
    @Binding var card: Card
    @Binding var isPresented: Bool
    let cardManager: CardManager
    
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var editingCardId: Int64? = nil
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Text(card.text)
                        .font(.system(size: 28, weight: .regular, design: .default))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        Button(action: {
                            hapticFeedback()
                            if let cardId = card.cardId {
                                _ = cardManager.toggleFavorite(cardId: cardId)
                                card.isFavorite.toggle()
                                cardManager.loadCards()
                            }
                        }) {
                            Image(systemName: card.isFavorite ? "star.fill" : "star")
                                .foregroundColor(card.isFavorite ? .yellow : .primary)
                                .font(.title3)
                        }
                        
                        Button(action: {
                            hapticFeedback()
                            // TODO: Notification settings
                        }) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.primary)
                                .font(.title3)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            hapticFeedback()
                            editingCardId = card.cardId
                            showingEdit = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.primary)
                                .font(.title3)
                        }
                        
                        Button(action: {
                            hapticFeedback()
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEdit) {
                CardEditView(
                    isPresented: $showingEdit,
                    cardId: editingCardId,
                    cardManager: cardManager
                )
            }
            .alert("Delete Card", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let cardId = card.cardId {
                        _ = cardManager.deleteCard(cardId: cardId)
                        isPresented = false
                    }
                }
            } message: {
                Text("Are you sure you want to delete this card? This action cannot be undone.")
            }
        }
    }
}

