import SwiftUI
import SwiftData

@main
struct PlantTrackerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Initialize SwiftData model container
            modelContainer = try ModelContainer(
                for: Plant.self,
                     Assessment.self,
                     WateringEvent.self,
                     ChatMessage.self,
                     ImprovementNote.self
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        // Request notification permissions on launch
        Task {
            await NotificationService.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
