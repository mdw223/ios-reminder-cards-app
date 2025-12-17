import SwiftUI

struct ContentView: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    
    var body: some View {
        VStack {
            if databaseManager.isInitialized {
                Text("Database Ready")
                    .font(.largeTitle)
                    .padding()
            } else {
                ProgressView("Initializing Database...")
            }
        }
    }
}

