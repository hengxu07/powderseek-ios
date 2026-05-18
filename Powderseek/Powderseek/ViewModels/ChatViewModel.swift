import Foundation
import Combine

// @MainActor ensures every property update and method call on this class
// runs on the main thread — required for UI updates. Same problem as
// "can't update state from a background thread" in React Native.
//
// ObservableObject is a protocol that lets SwiftUI watch this class.
// Any @Published property change triggers a re-render of observing views.
@MainActor
final class ChatViewModel: ObservableObject {

    // @Published = SwiftUI's signal to re-render when these change
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var resorts: [ResortSummary] = []    // loaded once on launch
    @Published var trip: TripInput? = nil           // set when user opens trip form

    // sessionId persists in UserDefaults so conversations survive app restarts.
    // This is equivalent to localStorage in the browser.
    private let sessionId: String = {
        let key = "powderseek_session_id"
        if let existing = UserDefaults.standard.string(forKey: key) { return existing }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }()

    private let api = APIClient()

    // Resort name → slug map, built from the /resorts list.
    // Same logic as the web app's ChatWindow name-matching map.
    private var resortNameMap: [String: String] = [:]

    // MARK: - Load resort list on launch

    func loadResorts() async {
        guard resorts.isEmpty else { return }
        do {
            let list = try await api.fetchResorts()
            resorts = list
            buildResortNameMap(from: list)
        } catch {
            // Non-fatal: resort chips just won't appear
        }
    }

    private func buildResortNameMap(from list: [ResortSummary]) {
        var map: [String: String] = [:]
        for r in list {
            let lower = r.name.lowercased()
            map[lower] = r.slug
            // Normalize slashes: "val d'isère / tignes" → "val d'isère/tignes"
            let compact = lower.replacingOccurrences(of: " / ", with: "/")
            map[compact] = r.slug
            // First part before slash: "val d'isère"
            if let firstPart = lower.components(separatedBy: " / ").first {
                map[firstPart] = r.slug
            }
            // Slug words: "park-city" → "park city"
            let slugWords = r.slug.replacingOccurrences(of: "-", with: " ")
            map[slugWords] = r.slug
            // First word if 5+ chars: "niseko", "hakuba", "mammoth"
            let firstWord = lower.components(separatedBy: " ").first ?? ""
            if firstWord.count >= 5 { map[firstWord] = r.slug }
        }
        resortNameMap = map
    }

    // MARK: - Detect resort slugs mentioned in a message

    // Scans assistant message content for **bold** resort names and returns
    // the matching slugs. These become the tappable resort chips below messages.
    func resortSlugs(in content: String) -> [String] {
        // Regex that finds text inside **…**
        guard let regex = try? NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*") else { return [] }
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, range: range)

        var slugs: [String] = []
        for match in matches {
            if let r = Range(match.range(at: 1), in: content) {
                let text = String(content[r]).lowercased()
                if let slug = matchResort(in: text), !slugs.contains(slug) {
                    slugs.append(slug)
                }
            }
        }
        return slugs
    }

    // Tries to find a resort slug in a bold span.
    // Handles agent patterns like "**Telluride, Colorado. This is your trip.**"
    // by progressively stripping the text down to just the resort name.
    private func matchResort(in text: String) -> String? {
        // 1. Exact match
        if let slug = resortNameMap[text] { return slug }
        // 2. First token before any comma, period, colon, or exclamation
        let firstToken = text
            .components(separatedBy: CharacterSet(charactersIn: ",.!?:"))
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if !firstToken.isEmpty, let slug = resortNameMap[firstToken] { return slug }
        // 3. First word (catches "Niseko United — Top Pick" → "niseko united")
        let words = firstToken.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        for length in stride(from: words.count, through: 1, by: -1) {
            let candidate = words.prefix(length).joined(separator: " ")
            if candidate.count >= 4, let slug = resortNameMap[candidate] { return slug }
        }
        return nil
    }

    // MARK: - Send a message

    func send(text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Add user bubble immediately
        messages.append(ChatMessage(role: .user, content: text))

        // Add empty assistant bubble that we'll stream into
        messages.append(ChatMessage(role: .assistant, content: "", isStreaming: true))

        isStreaming = true
        let tripForRequest = trip
        trip = nil  // clear after first use, like the web app

        do {
            for try await chunk in api.streamChat(sessionId: sessionId, message: text, trip: tripForRequest) {
                // Append each chunk to the last message's content.
                // Because ChatViewModel is @MainActor this is always on main thread.
                messages[messages.count - 1].content += chunk
            }
        } catch {
            messages[messages.count - 1].content = "Something went wrong — \(error.localizedDescription)"
        }

        messages[messages.count - 1].isStreaming = false
        isStreaming = false
    }

    // MARK: - Reset

    func reset() {
        messages = []
        trip = nil
    }
}
