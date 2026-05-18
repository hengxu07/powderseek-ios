import Foundation

// Identifiable lets SwiftUI's ForEach use id: \.id instead of index-based loops.
// This is important for stable list animations when messages stream in.
struct ChatMessage: Identifiable {
    let id = UUID()
    var role: Role
    var content: String
    var isStreaming: Bool = false

    enum Role {
        case user, assistant
    }
}
