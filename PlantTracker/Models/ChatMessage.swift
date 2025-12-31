import Foundation
import SwiftData
import UIKit

@Model
final class ChatMessage {
    @Attribute(.unique) var id: String
    var role: String // "user" or "assistant"
    var content: String
    var actionSuggestions: [String]?
    var safetyNote: String?
    var createdAt: Date
    var imageFilename: String? // Optional reference to local image file

    var plant: Plant?

    init(
        id: String = UUID().uuidString,
        role: String,
        content: String,
        actionSuggestions: [String]? = nil,
        safetyNote: String? = nil,
        createdAt: Date = Date(),
        imageFilename: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.actionSuggestions = actionSuggestions
        self.safetyNote = safetyNote
        self.createdAt = createdAt
        self.imageFilename = imageFilename
    }
}

// MARK: - Convenience
extension ChatMessage {
    /// Whether this is a user message
    var isUser: Bool {
        role.lowercased() == "user"
    }

    /// Whether this is an assistant message
    var isAssistant: Bool {
        role.lowercased() == "assistant"
    }

    /// Convert to DTO for API request
    func toDTO() -> ChatMessageDTO {
        let imageBase64: String?
        if let path = imageFilename,
           let image = ImageService.loadImage(from: path),
           let compressedData = ImageService.compressImage(image) {
            imageBase64 = compressedData.base64EncodedString()
        } else {
            imageBase64 = nil
        }

        return ChatMessageDTO(
            role: role,
            content: content,
            imageBase64: imageBase64
        )
    }

    /// Create from user input
    static func userMessage(content: String, imageFilename: String? = nil) -> ChatMessage {
        ChatMessage(role: "user", content: content, imageFilename: imageFilename)
    }

    /// Create from API response
    static func from(response: ChatResponse) -> ChatMessage {
        ChatMessage(
            role: "assistant",
            content: response.reply,
            actionSuggestions: (response.actionSuggestions?.isEmpty == true) ? nil : response.actionSuggestions,
            safetyNote: response.safetyNote
        )
    }
}
