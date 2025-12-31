import Foundation

struct AnalyzeRequest: Codable {
    let imageBase64: String
    let plantName: String?
    let species: String?
    let season: String?
    let lastWatered: String?

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case plantName = "plant_name"
        case species
        case season
        case lastWatered = "last_watered"
    }
}

struct AnalyzeResponse: Codable {
    let status: String
    let confidence: Double
    let issues: [String]
    let recommendations: [String]
    let suggestedIntervalDays: Double
    let rationale: String

    enum CodingKeys: String, CodingKey {
        case status
        case confidence
        case issues
        case recommendations
        case suggestedIntervalDays = "suggested_interval_days"
        case rationale
    }
}

struct ChatMessageDTO: Codable {
    let role: String
    let content: String
}

struct PlantContextDTO: Codable {
    let plantName: String?
    let species: String?
    let lastAssessmentStatus: String?

    enum CodingKeys: String, CodingKey {
        case plantName = "plant_name"
        case species
        case lastAssessmentStatus = "last_assessment_status"
    }
}

struct ChatRequest: Codable {
    let messages: [ChatMessageDTO]
    let plantContext: PlantContextDTO?

    enum CodingKeys: String, CodingKey {
        case messages
        case plantContext = "plant_context"
    }
}

struct ChatResponse: Codable {
    let reply: String
    let actionSuggestions: [String]?
    let safetyNote: String?

    enum CodingKeys: String, CodingKey {
        case reply
        case actionSuggestions = "action_suggestions"
        case safetyNote = "safety_note"
    }
}

struct ProxyErrorResponse: Codable {
    let error: String
    let message: String
    let retryable: Bool
}
