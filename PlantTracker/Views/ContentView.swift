import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            PlantListView()
                .tabItem {
                    Label("Plants", systemImage: "leaf.fill")
                }

            ImprovementNotesView()
                .tabItem {
                    Label("Improvements", systemImage: "lightbulb.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Plant.self, Assessment.self, WateringEvent.self, ChatMessage.self, ImprovementNote.self])
}
