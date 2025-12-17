import SwiftUI

struct HomeView: View {
    @StateObject private var cardManager = CardManager()
    @State private var showingCardEdit = false
    @State private var editingCardId: Int64? = nil
    @State private var dragOffset: CGFloat = 0
    
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
                
                if cardManager.cards.isEmpty {
                    emptyStateView
                } else {
                    cardView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        if let currentCard = cardManager.currentCard {
                            Button(action: {
                                hapticFeedback()
                                _ = cardManager.toggleFavorite(cardId: currentCard.cardId!)
                                cardManager.loadCards()
                            }) {
                                Image(systemName: currentCard.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(currentCard.isFavorite ? .yellow : .primary)
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if cardManager.currentCard != nil {
                            Button(action: {
                                hapticFeedback()
                                editingCardId = cardManager.currentCard?.cardId
                                showingCardEdit = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.primary)
                                    .font(.title3)
                            }
                        }
                        
                        Button(action: {
                            hapticFeedback()
                            editingCardId = nil
                            showingCardEdit = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            hapticFeedback()
                            // TODO: Filter functionality
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        if !cardManager.cards.isEmpty {
                            Text("Card \(cardManager.currentIndex + 1) of \(cardManager.cards.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCardEdit, onDismiss: {
                cardManager.loadCards()
            }) {
                CardEditView(
                    isPresented: $showingCardEdit,
                    cardId: editingCardId,
                    cardManager: cardManager
                )
            }
        }
    }
    
    private var cardView: some View {
        GeometryReader { geometry in
            ZStack {
                if let card = cardManager.currentCard {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Text(card.text)
                            .font(.system(size: 28, weight: .regular, design: .default))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(y: dragOffset)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
                        
                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: dragOffset < 0 ? .bottom : .top).combined(with: .opacity),
                        removal: .move(edge: dragOffset < 0 ? .top : .bottom).combined(with: .opacity)
                    ))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        
                        if value.translation.height < -threshold {
                            // Swipe up - next card
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                cardManager.nextCard()
                                hapticFeedback()
                            }
                        } else if value.translation.height > threshold {
                            // Swipe down - previous card
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                cardManager.previousCard()
                                hapticFeedback()
                            }
                        }
                        
                        dragOffset = 0
                    }
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No cards yet")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button(action: {
                hapticFeedback()
                editingCardId = nil
                showingCardEdit = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Card")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

