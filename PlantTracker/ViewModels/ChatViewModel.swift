import Foundation
import SwiftData
import UIKit

@MainActor
@Observable
final class ChatViewModel {
    private let modelContext: ModelContext
    private let proxyClient: GeminiProxyClient
    private let plant: Plant

    var messages: [ChatMessage] = []
    var isSending = false
    var errorMessage: String?
    var showError = false

    init(
        plant: Plant,
        modelContext: ModelContext,
        proxyClient: GeminiProxyClient = .shared
    ) {
        self.plant = plant
        self.modelContext = modelContext
        self.proxyClient = proxyClient
        loadMessages()
    }

    /// Load chat messages for this plant
    func loadMessages() {
        messages = plant.chatMessages.sorted { $0.createdAt < $1.createdAt }
    }

    /// Send a message to the AI
    /// - Parameters:
    ///   - content: The user's message
    ///   - image: Optional image to attach
    func sendMessage(_ content: String, image: UIImage? = nil) async {
        guard !content.isEmpty else { return }

        isSending = true
        errorMessage = nil
        showError = false

        // Save image if provided
        var imageFilename: String?
        if let image = image {
            let filename = "\(UUID().uuidString)_\(Date().timeIntervalSince1970).jpg"
            imageFilename = ImageService.saveImage(image, filename: filename)
        }

        // Create user message
        let userMessage = ChatMessage.userMessage(content: content, imageFilename: imageFilename)
        userMessage.plant = plant
        plant.chatMessages.append(userMessage)
        modelContext.insert(userMessage)

        // Update local messages
        messages.append(userMessage)

        do {
            try modelContext.save()

            // Build message history for API
            let messageDTOs = messages.map { $0.toDTO() }

            // Build plant context
            let context = PlantContextDTO(
                plantName: plant.name,
                species: plant.species,
                lastAssessmentStatus: plant.latestAssessment?.status,
                currentDate: Date().ISO8601Format()
            )

            // Call proxy
            let response = try await proxyClient.chat(
                messages: messageDTOs,
                plantContext: context
            )

            // Create assistant message from response
            let assistantMessage = ChatMessage.from(response: response)
            assistantMessage.plant = plant
            plant.chatMessages.append(assistantMessage)
            modelContext.insert(assistantMessage)

            // Update local messages
            messages.append(assistantMessage)

            try modelContext.save()

            isSending = false

        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            showError = true
            isSending = false

            // Remove the user message on error
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages.remove(at: index)
            }
            modelContext.delete(userMessage)

            print("Chat error: \(error)")
        }
    }

    /// Clear chat history
    func clearHistory() {
        for message in plant.chatMessages {
            modelContext.delete(message)
        }

        plant.chatMessages.removeAll()

        do {
            try modelContext.save()
            loadMessages()
        } catch {
            errorMessage = "Failed to clear history: \(error.localizedDescription)"
            showError = true
            print("Clear history error: \(error)")
        }
    }
}
