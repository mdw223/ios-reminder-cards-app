import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    let cardId: Int64?
    let cardManager: CardManager
    
    @State private var cardText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    var isEditMode: Bool {
        cardId != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if cardText.isEmpty && !isTextEditorFocused {
                    Text("Write your reminder...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $cardText)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .padding(.horizontal, 4)
                    .focused($isTextEditorFocused)
                    .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditMode ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(cardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let cardId = cardId,
                   let card = cardManager.cards.first(where: { $0.cardId == cardId }) {
                    cardText = card.text
                }
                isTextEditorFocused = true
            }
        }
    }
    
    private func saveCard() {
        let trimmedText = cardText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if let cardId = cardId {
            // Update existing card
            _ = cardManager.updateCard(cardId: cardId, text: trimmedText)
        } else {
            // Create new card in default folder
            if let defaultFolderId = cardManager.getDefaultFolderId() {
                _ = cardManager.createCard(text: trimmedText, folderId: defaultFolderId)
            }
        }
        
        dismiss()
    }
}

