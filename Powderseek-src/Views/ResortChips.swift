import SwiftUI

// Shows tappable resort name pills below assistant messages.
// In the web app these are inline clickable bold words; in iOS it's cleaner
// to put them as chips underneath since inline taps are complex in SwiftUI.
struct ResortChips: View {
    let slugs: [String]
    let onTap: (String) -> Void

    @EnvironmentObject var chatVM: ChatViewModel

    var body: some View {
        if !slugs.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(slugs, id: \.self) { slug in
                        // Find the display name from the resort list
                        let name = chatVM.resorts.first { $0.slug == slug }?.name ?? slug
                        Button {
                            onTap(slug)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mountain.2")
                                    .font(.system(size: 11))
                                Text(name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                .padding(.leading, 52)  // align under the assistant bubble (avatar width + gap)
                .padding(.trailing, 12)
            }
        }
    }
}
