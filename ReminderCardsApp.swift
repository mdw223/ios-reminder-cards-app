import SwiftUI

@main
struct ReminderCardsApp: App {
    @StateObject private var databaseManager = DatabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(databaseManager)
                .onAppear {
                    databaseManager.initializeDatabase()
                }
        }
    }
}

