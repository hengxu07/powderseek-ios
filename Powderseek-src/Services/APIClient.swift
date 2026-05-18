import Foundation

// The body we POST to /chat
private struct ChatRequest: Encodable {
    let sessionId: String
    let message: String
    let trip: TripInput?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case message, trip
    }
}

// Each SSE event the server sends
private struct SSEEvent: Decodable {
    let type: String
    let content: String?
}

enum APIError: Error, LocalizedError {
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

final class APIClient {
    // Switch this to "https://web-production-56f6d.up.railway.app" for production
    static let baseURL = "http://localhost:8000"

    // MARK: - Fetch resort list (called once on launch)
    func fetchResorts() async throws -> [ResortSummary] {
        let url = URL(string: "\(Self.baseURL)/resorts")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ResortSummary].self, from: data)
    }

    // MARK: - Fetch full resort detail (called when user taps a resort chip)
    func fetchResortDetail(slug: String) async throws -> ResortDetail {
        let url = URL(string: "\(Self.baseURL)/resort/\(slug)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ResortDetail.self, from: data)
    }

    // MARK: - Stream a chat message
    //
    // Returns an AsyncThrowingStream — an async sequence that yields String chunks
    // one at a time as they arrive from the server. The caller (ChatViewModel)
    // iterates this with `for try await chunk in stream { ... }`.
    //
    // Internally: URLSession.bytes gives us AsyncBytes (raw bytes). We iterate
    // .lines to get one SSE line at a time, parse the JSON payload, and yield
    // only the "text" content chunks.
    func streamChat(
        sessionId: String,
        message: String,
        trip: TripInput?
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // AsyncThrowingStream takes a closure that runs once. Inside we
            // create a Task to do async work, yielding values back through
            // the continuation.
            Task {
                do {
                    var request = URLRequest(url: URL(string: "\(Self.baseURL)/chat")!)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let body = ChatRequest(sessionId: sessionId, message: message, trip: trip)
                    request.httpBody = try JSONEncoder().encode(body)

                    // bytes(for:) opens the connection and returns AsyncBytes —
                    // a sequence we can iterate without loading the full response.
                    let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)

                    for try await line in asyncBytes.lines {
                        // SSE lines look like: data: {"type":"text","content":"hello"}
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let event = try? JSONDecoder().decode(SSEEvent.self, from: data)
                        else { continue }

                        switch event.type {
                        case "text":
                            continuation.yield(event.content ?? "")
                        case "error":
                            continuation.finish(throwing: APIError.serverError(event.content ?? "Unknown error"))
                            return
                        case "done":
                            continuation.finish()
                            return
                        default:
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
