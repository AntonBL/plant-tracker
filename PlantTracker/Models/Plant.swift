import Foundation
import SwiftData

@Model
final class Plant {
    @Attribute(.unique) var id: String
    var name: String
    var species: String?
    var imagePath: String?
    var wateringCadenceDays: Int?
    var reminderTime: Date?
    var lastWatered: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Assessment.plant)
    var assessments: [Assessment] = []

    @Relationship(deleteRule: .cascade, inverse: \WateringEvent.plant)
    var wateringEvents: [WateringEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.plant)
    var chatMessages: [ChatMessage] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        species: String? = nil,
        imagePath: String? = nil,
        wateringCadenceDays: Int? = nil,
        reminderTime: Date? = nil,
        lastWatered: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.imagePath = imagePath
        self.wateringCadenceDays = wateringCadenceDays
        self.reminderTime = reminderTime
        self.lastWatered = lastWatered
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties
extension Plant {
    /// Whether the plant needs watering based on cadence
    var needsWatering: Bool {
        guard let lastWatered = lastWatered,
              let cadence = wateringCadenceDays else {
            return false // Can't determine without cadence
        }

        let daysSinceWatered = Calendar.current.dateComponents(
            [.day],
            from: lastWatered,
            to: Date()
        ).day ?? 0

        return daysSinceWatered >= cadence
    }

    /// Next scheduled watering date
    var nextWateringDate: Date? {
        guard let lastWatered = lastWatered,
              let cadence = wateringCadenceDays else {
            return nil
        }

        return Calendar.current.date(
            byAdding: .day,
            value: cadence,
            to: lastWatered
        )
    }

    /// Most recent assessment (sorted by creation date)
    var latestAssessment: Assessment? {
        assessments.sorted { $0.createdAt > $1.createdAt }.first
    }

    /// Current health status from latest assessment
    var healthStatus: String {
        latestAssessment?.status ?? "unknown"
    }
}
