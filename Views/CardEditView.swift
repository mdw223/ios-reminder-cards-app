import SwiftUI

struct CardEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    let cardId: Int64?
    let cardManager: CardManager
    let folderManager: FolderManager
    
    @State private var cardText: String = ""
    @State private var selectedFolderIds: Set<Int64> = []
    @FocusState private var isTextEditorFocused: Bool
    
    var isEditMode: Bool {
        cardId != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                .frame(height: 200)
                
                Divider()
                
                List {
                    Section("Add to Folders") {
                        ForEach(folderManager.folders, id: \.folderId) { folder in
                            if let folderId = folder.folderId {
                                HStack {
                                    Text(folder.title)
                                    
                                    Spacer()
                                    
                                    if folder.isDefault {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.secondary)
                                    } else {
                                        Toggle("", isOn: Binding(
                                            get: { selectedFolderIds.contains(folderId) },
                                            set: { isOn in
                                                if isOn {
                                                    selectedFolderIds.insert(folderId)
                                                } else {
                                                    selectedFolderIds.remove(folderId)
                                                }
                                            }
                                        ))
                                    }
                                }
                                .disabled(folder.isDefault)
                            }
                        }
                    }
                }
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
                folderManager.loadFolders()
                
                if let cardId = cardId,
                   let card = cardManager.cards.first(where: { $0.cardId == cardId }) {
                    cardText = card.text
                    
                    // Load existing folder associations
                    selectedFolderIds = Set(folderManager.getFoldersForCard(cardId: cardId))
                } else {
                    // New card - default folder is always selected
                    if let defaultFolder = folderManager.folders.first(where: { $0.isDefault }),
                       let defaultFolderId = defaultFolder.folderId {
                        selectedFolderIds.insert(defaultFolderId)
                    }
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
            
            // Update folder associations
            let currentFolders = Set(folderManager.getFoldersForCard(cardId: cardId))
            let foldersToAdd = selectedFolderIds.subtracting(currentFolders)
            let foldersToRemove = currentFolders.subtracting(selectedFolderIds)
            
            for folderId in foldersToAdd {
                _ = folderManager.addCardToFolder(cardId: cardId, folderId: folderId)
            }
            
            for folderId in foldersToRemove {
                // Don't remove from default folder
                if let folder = folderManager.folders.first(where: { $0.folderId == folderId }),
                   !folder.isDefault {
                    _ = folderManager.removeCardFromFolder(cardId: cardId, folderId: folderId)
                }
            }
        } else {
            // Create new card - add to all selected folders
            if let defaultFolderId = cardManager.getDefaultFolderId() {
                if let newCard = cardManager.createCard(text: trimmedText, folderId: defaultFolderId) {
                    if let newCardId = newCard.cardId {
                        // Add to additional selected folders
                        for folderId in selectedFolderIds where folderId != defaultFolderId {
                            _ = folderManager.addCardToFolder(cardId: newCardId, folderId: folderId)
                        }
                    }
                }
            }
        }
        
        dismiss()
    }
}

