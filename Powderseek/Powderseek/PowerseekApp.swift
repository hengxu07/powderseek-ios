import SwiftUI

// @main marks this as the app entry point — like React's root render call.
@main
struct PowerseekApp: App {

    // @StateObject creates the ViewModel once and keeps it alive for the app's
    // lifetime. Using @StateObject here (not @ObservedObject) means SwiftUI owns
    // it and won't recreate it on re-render.
    @StateObject private var chatVM = ChatViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // .environmentObject pushes chatVM into the SwiftUI environment
                // so any child view can access it with @EnvironmentObject.
                .environmentObject(chatVM)
        }
    }
}
