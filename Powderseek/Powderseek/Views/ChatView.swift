import SwiftUI

// Wrapper so we can use sheet(item:) without a retroactive String conformance
struct ResortSlug: Identifiable {
    let id: String  // the slug itself
}

struct ChatView: View {
    @EnvironmentObject var chatVM: ChatViewModel

    @State private var inputText = ""
    @State private var showTripForm = false
    @State private var selectedResort: ResortSlug? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Message list or empty state
            if chatVM.messages.isEmpty {
                emptyState
            } else {
                messageList
            }

            // Input bar
            inputBar
        }
        .background(Color(.systemBackground))
        // .sheet presents a modal bottom sheet.
        // The `item:` variant takes an optional Identifiable — sheet appears
        // when non-nil, dismisses when set back to nil.
        .sheet(isPresented: $showTripForm) {
            TripInputSheet()
        }
        .sheet(item: $selectedResort) { resort in
            ResortDetailSheet(slug: resort.id)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("❄️ Powderseek")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if !chatVM.messages.isEmpty {
                Button("New chat") {
                    chatVM.reset()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🏔️")
                    .font(.system(size: 56))
                Text("Where to next?")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Tell me how many days you have and I'll find you the best powder.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            Task { await chatVM.send(text: suggestion) }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 40)
        }
    }

    // MARK: - Message list

    // ScrollViewReader lets us programmatically scroll to a specific view by id.
    // We use it to scroll to the bottom as messages stream in.
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatVM.messages) { msg in
                        VStack(alignment: .leading, spacing: 6) {
                            MessageBubble(message: msg)
                            // Show resort chips below assistant messages
                            if msg.role == .assistant && !msg.isStreaming {
                                ResortChips(
                                    slugs: chatVM.resortSlugs(in: msg.content),
                                    onTap: { slug in selectedResort = ResortSlug(id: slug) }
                                )
                            }
                        }
                    }
                    // Invisible anchor view we scroll to
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 12)
            }
            // onChange fires when the watched value changes — like useEffect with a dep.
            // We scroll to bottom whenever messages update.
            .onChange(of: chatVM.messages.last?.content) {
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                // Trip form button
                Button {
                    showTripForm = true
                } label: {
                    Image(systemName: "calendar")
                        .foregroundColor(chatVM.trip != nil ? .blue : .secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }

                // Text field
                // TextField in SwiftUI is single-line; for multiline use TextEditor.
                TextField("Where should I ski?", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)

                // Send button
                Button {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty, !chatVM.isStreaming else { return }
                    inputText = ""
                    Task { await chatVM.send(text: text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty || chatVM.isStreaming ? .secondary : .blue)
                }
                .disabled(inputText.isEmpty || chatVM.isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private let suggestions = [
        "Where should I ski this weekend?",
        "I have 5 days in February — where's the best powder?",
        "Surprise me — 10 days, open to flying anywhere.",
    ]
}

