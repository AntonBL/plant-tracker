import Foundation

/// Protocol for proxy client, enabling testability with mock implementations
protocol ProxyClientProtocol {
    func analyze(
        imageData: Data,
        plantName: String?,
        species: String?,
        season: String?,
        lastWatered: String?,
        customPrompt: String?,
        currentDate: String?
    ) async throws -> AnalyzeResponse

    func chat(
        messages: [ChatMessageDTO],
        plantContext: PlantContextDTO?
    ) async throws -> ChatResponse
}

final class GeminiProxyClient: ProxyClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    /// Shared instance using the default proxy URL from Constants
    static let shared: GeminiProxyClient = {
        do {
            return try GeminiProxyClient()
        } catch {
            fatalError("Failed to initialize GeminiProxyClient: \(error)")
        }
    }()

    /// Initialize with default proxy URL from Constants
    /// - Throws: ProxyError.invalidConfiguration if the URL is malformed
    convenience init() throws {
        guard let url = URL(string: Constants.proxyBaseURL) else {
            throw ProxyError.invalidConfiguration("Invalid proxy URL: \(Constants.proxyBaseURL)")
        }
        self.init(baseURL: url)
    }

    /// Initialize with custom base URL (useful for testing)
    /// - Parameters:
    ///   - baseURL: The base URL for the proxy server
    ///   - session: URLSession to use for requests (default: .shared)
    ///   - timeoutInterval: Request timeout in seconds (default: 60)
    init(baseURL: URL, session: URLSession = .shared, timeoutInterval: TimeInterval = 60) {
        self.baseURL = baseURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    func analyze(
        imageData: Data,
        plantName: String?,
        species: String?,
        season: String?,
        lastWatered: String?,
        customPrompt: String? = nil,
        currentDate: String? = nil
    ) async throws -> AnalyzeResponse {
        let imageBase64 = imageData.base64EncodedString()
        let requestBody = AnalyzeRequest(
            imageBase64: imageBase64,
            plantName: plantName,
            species: species,
            season: season,
            lastWatered: lastWatered,
            customPrompt: customPrompt,
            currentDate: currentDate
        )
        return try await send(path: "/analyze", body: requestBody)
    }

    func chat(
        messages: [ChatMessageDTO],
        plantContext: PlantContextDTO?
    ) async throws -> ChatResponse {
        let requestBody = ChatRequest(messages: messages, plantContext: plantContext)
        return try await send(path: "/chat", body: requestBody)
    }

    private func send<Request: Encodable, Response: Decodable>(
        path: String,
        body: Request
    ) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // DTOs use explicit CodingKeys for snake_case mapping
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxyError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            // DTOs use explicit CodingKeys for snake_case mapping
            return try JSONDecoder().decode(Response.self, from: data)
        }

        if let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data) {
            throw ProxyError.remote(errorResponse)
        }

        throw ProxyError.httpStatus(httpResponse.statusCode)
    }
}

enum ProxyError: LocalizedError {
    case invalidConfiguration(String)
    case invalidResponse
    case httpStatus(Int)
    case remote(ProxyErrorResponse)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpStatus(let code):
            return "Server returned status code \(code)"
        case .remote(let errorResponse):
            return errorResponse.message
        }
    }
}
