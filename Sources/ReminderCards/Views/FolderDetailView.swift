import SwiftUI

struct FolderDetailView: View {
    @State var folder: Folder
    @StateObject private var cardManager = CardManager()
    @StateObject private var folderManager = FolderManager()
    @State private var cardsInFolder: [Card] = []
    @State private var editMode: EditMode = .inactive
    @State private var selectedCard: Card? = nil
    @State private var showingCardPreview = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        ScrollView {
            if cardsInFolder.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No cards in this folder")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cardsInFolder, id: \.cardId) { card in
                        CardPreviewView(card: card)
                            .overlay(alignment: .topTrailing) {
                                if editMode == .active {
                                    Button(action: {
                                        hapticFeedback()
                                        if let cardId = card.cardId {
                                            _ = folderManager.removeCardFromFolder(
                                                cardId: cardId,
                                                folderId: folder.folderId!
                                            )
                                            loadCards()
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .padding(4)
                                }
                            }
                            .onTapGesture {
                                if editMode == .inactive {
                                    hapticFeedback()
                                    selectedCard = card
                                    showingCardPreview = true
                                }
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(folder.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Set Active") {
                    hapticFeedback()
                    if let folderId = folder.folderId {
                        _ = folderManager.setActiveFolder(folderId: folderId)
                        folder.isActiveFolder = true
                        folderManager.loadFolders()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
        .onAppear {
            loadCards()
        }
        .sheet(isPresented: $showingCardPreview) {
            if let card = selectedCard {
                CardPreviewModal(card: Binding(
                    get: { card },
                    set: { newCard in
                        selectedCard = newCard
                        loadCards()
                    }
                ), isPresented: $showingCardPreview, cardManager: cardManager)
            }
        }
    }
    
    private func loadCards() {
        if let folderId = folder.folderId {
            cardsInFolder = folderManager.getCardsInFolder(folderId: folderId)
        }
    }
}

struct CardPreviewView: View {
    let card: Card
    
    private var previewText: String {
        let text = card.text
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(previewText)
                .font(.system(size: 14))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

extension Card: Identifiable {
    public var id: Int64? { cardId }
}

