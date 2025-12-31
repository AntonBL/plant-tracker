import Foundation
import SwiftData

@Model
final class WateringEvent {
    @Attribute(.unique) var id: String
    var wateredAt: Date

    var plant: Plant?

    init(
        id: String = UUID().uuidString,
        wateredAt: Date = Date()
    ) {
        self.id = id
        self.wateredAt = wateredAt
    }
}

// MARK: - Convenience
extension WateringEvent {
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: wateredAt)
    }

    /// Days since this watering event
    var daysAgo: Int {
        let components = Calendar.current.dateComponents(
            [.day],
            from: wateredAt,
            to: Date()
        )
        return components.day ?? 0
    }
}
