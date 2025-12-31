import Foundation
import SwiftData

@MainActor
@Observable
final class PlantListViewModel {
    private let modelContext: ModelContext

    var plants: [Plant] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPlants()
    }

    /// Load all plants from SwiftData
    func loadPlants() {
        let descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            plants = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load plants: \(error.localizedDescription)"
            print("Error loading plants: \(error)")
        }
    }

    /// Delete a plant
    /// - Parameter plant: The plant to delete
    func deletePlant(_ plant: Plant) {
        // Delete associated image if it exists
        if let imagePath = plant.imagePath {
            ImageService.deleteImage(at: imagePath)
        }

        // Cancel notification
        NotificationService.shared.cancelReminder(for: plant.id)

        // Delete from SwiftData (cascade will delete related objects)
        modelContext.delete(plant)

        do {
            try modelContext.save()
            loadPlants()
        } catch {
            errorMessage = "Failed to delete plant: \(error.localizedDescription)"
            print("Error deleting plant: \(error)")
        }
    }

    /// Get plants that need watering
    var plantsNeedingWater: [Plant] {
        plants.filter { $0.needsWatering }
    }
}
