import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Text("❄️").font(.system(size: 14))
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 0) {
                if message.role == .user {
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                } else {
                    // Assistant: split into paragraphs so SwiftUI renders visible
                    // spacing between sections. AttributedString handles bold/italic
                    // within each paragraph. Single \n inside a paragraph → space
                    // (CommonMark soft-break rule).
                    VStack(alignment: .leading, spacing: 8) {
                        let paragraphs = message.content
                            .components(separatedBy: "\n\n")
                            .map { $0.replacingOccurrences(of: "\n", with: " ")
                                      .trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                            if let attributed = try? AttributedString(markdown: para) {
                                Text(attributed)
                            } else {
                                Text(para)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.80, alignment: .leading)
                    .overlay(alignment: .bottomTrailing) {
                        if message.isStreaming {
                            StreamingDot()
                                .padding(8)
                        }
                    }
                }
            }

            if message.role == .user { Spacer() }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// A simple animated dot that pulses while the message is streaming.
// Uses @State with animation — a common SwiftUI pattern for simple animations.
private struct StreamingDot: View {
    @State private var opacity = 1.0

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 6, height: 6)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                    opacity = 0.2
                }
            }
    }
}
