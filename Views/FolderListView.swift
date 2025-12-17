import SwiftUI

struct FolderListView: View {
    @StateObject private var folderManager = FolderManager()
    @State private var showingNewFolderAlert = false
    @State private var newFolderTitle = ""
    @State private var folderToDelete: Folder? = nil
    @State private var showingDeleteConfirmation = false
    @State private var selectedFolder: Folder? = nil
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(folderManager.folders, id: \.folderId) { folder in
                        FolderCardView(
                            folder: folder,
                            cardCount: folderManager.getCardCount(for: folder.folderId!),
                            isActive: folder.isActiveFolder
                        )
                        .onTapGesture {
                            hapticFeedback()
                            selectedFolder = folder
                        }
                        .contextMenu {
                            Button(action: {
                                hapticFeedback()
                                _ = folderManager.setActiveFolder(folderId: folder.folderId!)
                            }) {
                                Label("Set Active", systemImage: "checkmark.circle")
                            }
                            
                            if !folder.isDefault && !folder.isFavorites {
                                Button(role: .destructive, action: {
                                    folderToDelete = folder
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        hapticFeedback()
                        showingNewFolderAlert = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderTitle)
                Button("Cancel", role: .cancel) {
                    newFolderTitle = ""
                }
                Button("Create") {
                    if !newFolderTitle.isEmpty {
                        _ = folderManager.createFolder(title: newFolderTitle)
                        newFolderTitle = ""
                    }
                }
            } message: {
                Text("Enter a name for the new folder")
            }
            .alert("Delete Folder", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    folderToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        _ = folderManager.deleteFolder(folderId: folder.folderId!)
                        folderToDelete = nil
                    }
                }
            } message: {
                if let folder = folderToDelete {
                    Text("Are you sure you want to delete '\(folder.title)'? This will remove the folder but keep all cards.")
                }
            }
            .sheet(item: $selectedFolder) { folder in
                NavigationView {
                    FolderDetailView(folder: folder)
                }
            }
        }
    }
}

struct FolderCardView: View {
    let folder: Folder
    let cardCount: Int
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 100)
                
                VStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Text(folder.title)
                .font(.headline)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            Text("\(cardCount) card\(cardCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

extension Folder: Identifiable {
    public var id: Int64? { folderId }
}

