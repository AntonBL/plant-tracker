import Foundation

struct AnalyzeRequest: Codable {
    let imageBase64: String
    let plantName: String?
    let species: String?
    let season: String?
    let lastWatered: String?
    let customPrompt: String?
    let currentDate: String?

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case plantName = "plant_name"
        case species
        case season
        case lastWatered = "last_watered"
        case customPrompt = "custom_prompt"
        case currentDate = "current_date"
    }
}

struct AnalyzeResponse: Codable {
    let status: String
    let confidence: Double
    let issues: [String]
    let recommendations: [String]
    let suggestedIntervalDays: Int?
    let rationale: String?
    let suggestedName: String?

    enum CodingKeys: String, CodingKey {
        case status
        case confidence
        case issues
        case recommendations
        case suggestedIntervalDays = "suggested_interval_days"
        case rationale
        case suggestedName = "suggested_name"
    }
}

struct ChatMessageDTO: Codable {
    let role: String
    let content: String
    let imageBase64: String?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case imageBase64 = "image_base64"
    }
}

struct PlantContextDTO: Codable {
    let plantName: String?
    let species: String?
    let lastAssessmentStatus: String?
    let currentDate: String?

    enum CodingKeys: String, CodingKey {
        case plantName = "plant_name"
        case species
        case lastAssessmentStatus = "last_assessment_status"
        case currentDate = "current_date"
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
