import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true
    @State private var importError: String?
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = importError {
                ErrorView(message: error) {
                    Task { await importData() }
                }
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .task {
            await importData()
        }
    }

    private func importData() async {
        isLoading = true
        importError = nil

        let service = DataImportService(modelContext: modelContext)

        do {
            if try service.needsImport() {
                // Use fast initial import on first launch (no duplicate checking)
                let result = try await service.performInitialImport()
                print("Imported \(result.imported) entries")
            }
            isLoading = false
        } catch {
            importError = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "book")
                }
                .tag(0)

            StudyPlaceholderView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.on.rectangle")
                }
                .tag(1)

            StatsPlaceholderView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(2)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading entries...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Import Failed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Placeholder Views (Phase 2 & 3)

struct StudyPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Study Mode")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Flashcards coming in Phase 2")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Study")
        }
    }
}

struct StatsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Statistics")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Progress tracking coming in Phase 3")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
