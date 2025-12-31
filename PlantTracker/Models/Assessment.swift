import Foundation
import SwiftData

@Model
final class Assessment {
    @Attribute(.unique) var id: String
    var status: String // "healthy", "needs_attention", "critical"
    var confidence: Double
    var issues: [String]
    var recommendations: [String]
    var suggestedIntervalDays: Int?
    var rationale: String?
    var createdAt: Date

    var plant: Plant?

    init(
        id: String = UUID().uuidString,
        status: String,
        confidence: Double,
        issues: [String],
        recommendations: [String],
        suggestedIntervalDays: Int? = nil,
        rationale: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.status = status
        self.confidence = confidence
        self.issues = issues
        self.recommendations = recommendations
        self.suggestedIntervalDays = suggestedIntervalDays
        self.rationale = rationale
        self.createdAt = createdAt
    }
}

// MARK: - Convenience
extension Assessment {
    /// Create Assessment from API response
    static func from(response: AnalyzeResponse) -> Assessment {
        Assessment(
            status: response.status,
            confidence: response.confidence,
            issues: response.issues,
            recommendations: response.recommendations,
            suggestedIntervalDays: response.suggestedIntervalDays,
            rationale: response.rationale
        )
    }

    /// Color for status badge
    var statusColor: String {
        switch status.lowercased() {
        case "healthy":
            return "green"
        case "needs_attention":
            return "orange"
        case "critical":
            return "red"
        default:
            return "gray"
        }
    }

    /// Human-readable status
    var statusDisplayText: String {
        switch status.lowercased() {
        case "healthy":
            return "Healthy"
        case "needs_attention":
            return "Needs Attention"
        case "critical":
            return "Critical"
        default:
            return "Unknown"
        }
    }
}
