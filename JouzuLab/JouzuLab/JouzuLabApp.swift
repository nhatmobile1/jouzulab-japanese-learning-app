import SwiftUI
import SwiftData

@main
struct JouzuLabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Entry.self])
    }
}
