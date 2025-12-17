import SwiftUI

struct ContentView: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    
    var body: some View {
        if databaseManager.isInitialized {
            HomeView()
        } else {
            VStack {
                ProgressView("Initializing Database...")
            }
            .onAppear {
                databaseManager.initializeDatabase()
            }
        }
    }
}

