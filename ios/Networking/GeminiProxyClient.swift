import Foundation

final class GeminiProxyClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func analyze(
        imageData: Data,
        plantName: String?,
        species: String?,
        season: String?,
        lastWatered: String?
    ) async throws -> AnalyzeResponse {
        let imageBase64 = imageData.base64EncodedString()
        let requestBody = AnalyzeRequest(
            imageBase64: imageBase64,
            plantName: plantName,
            species: species,
            season: season,
            lastWatered: lastWatered
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxyError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(Response.self, from: data)
        }

        if let errorResponse = try? JSONDecoder().decode(ProxyErrorResponse.self, from: data) {
            throw ProxyError.remote(errorResponse)
        }

        throw ProxyError.httpStatus(httpResponse.statusCode)
    }
}

enum ProxyError: Error {
    case invalidResponse
    case httpStatus(Int)
    case remote(ProxyErrorResponse)
}
