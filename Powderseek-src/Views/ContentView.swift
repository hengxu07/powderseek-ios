import SwiftUI

// ContentView is the root view — equivalent to App.tsx.
// It's thin: just sets up the background and loads the resort list on appear.
struct ContentView: View {

    // @EnvironmentObject pulls the ViewModel from the environment.
    // No prop drilling needed — any view in the tree can do this.
    @EnvironmentObject var chatVM: ChatViewModel

    var body: some View {
        ChatView()
            .preferredColorScheme(.dark)
            // .task runs an async function when the view appears, and cancels
            // it automatically when the view disappears. Like useEffect + cleanup.
            .task {
                await chatVM.loadResorts()
            }
    }
}
