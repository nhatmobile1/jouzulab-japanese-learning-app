import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true
    @State private var importError: String?
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case study = "Study"
        case decks = "Decks"
        case shadow = "Shadow"
        case browse = "Browse"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .study: return "rectangle.stack.fill"
            case .decks: return "square.stack.3d.up.fill"
            case .shadow: return "waveform"
            case .browse: return "book.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

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
        let catalog = DeckCatalog.shared

        do {
            if try service.needsImport() {
                // Fresh install: Use DeckCatalog to load italki notes, which creates proper Deck record
                if let italkiDeck = catalog.deck(byID: "jouzu_italki_notes") {
                    let result = try await catalog.loadDeck(italkiDeck, modelContext: modelContext)
                    print("Loaded italki deck: \(result.entriesImported) entries imported, \(result.entriesSkipped) skipped")
                }
            } else {
                // Existing data: Check if we need to migrate (entries exist but no Deck record)
                try await migrateExistingEntriesToDeck()
            }
            isLoading = false
        } catch {
            importError = error.localizedDescription
            isLoading = false
        }
    }

    /// Migrate existing entries to have proper Deck records if they were imported before the deck system
    private func migrateExistingEntriesToDeck() async throws {
        let catalog = DeckCatalog.shared

        // Check if italki deck exists
        var descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.id == "jouzu_italki_notes" }
        )
        descriptor.fetchLimit = 1
        let existingDeck = try modelContext.fetch(descriptor).first

        if existingDeck == nil {
            // Check if we have entries that should belong to the italki deck
            let entryDescriptor = FetchDescriptor<Entry>()
            let allEntries = try modelContext.fetch(entryDescriptor)

            // If there are entries without deckId, they're from the old import system
            let orphanedEntries = allEntries.filter { $0.deckId == nil }

            if !orphanedEntries.isEmpty {
                // Create the italki deck
                let deck = Deck(
                    id: "jouzu_italki_notes",
                    name: "italki Lesson Notes",
                    deckDescription: "~4,000 complete vocabulary and phrases from personal italki Japanese lessons (2023-2026)",
                    author: "JouzuLab",
                    version: "1.0",
                    sourceFileName: "japanese_data"
                )
                modelContext.insert(deck)

                // Update all orphaned entries to belong to this deck
                var entryIDs: [String] = []
                for entry in orphanedEntries {
                    entry.deckId = "jouzu_italki_notes"
                    entryIDs.append(entry.id)
                }

                deck.entryIDs = entryIDs
                deck.entryCount = entryIDs.count
                deck.installedDate = Date()

                try modelContext.save()
                print("Migrated \(orphanedEntries.count) entries to italki deck")
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(ContentView.Tab.home.rawValue, systemImage: ContentView.Tab.home.icon)
                }
                .tag(ContentView.Tab.home)

            StudyView()
                .tabItem {
                    Label(ContentView.Tab.study.rawValue, systemImage: ContentView.Tab.study.icon)
                }
                .tag(ContentView.Tab.study)

            DecksView()
                .tabItem {
                    Label(ContentView.Tab.decks.rawValue, systemImage: ContentView.Tab.decks.icon)
                }
                .tag(ContentView.Tab.decks)

            ShadowView()
                .tabItem {
                    Label(ContentView.Tab.shadow.rawValue, systemImage: ContentView.Tab.shadow.icon)
                }
                .tag(ContentView.Tab.shadow)

            BrowseView()
                .tabItem {
                    Label(ContentView.Tab.browse.rawValue, systemImage: ContentView.Tab.browse.icon)
                }
                .tag(ContentView.Tab.browse)

            SettingsView()
                .tabItem {
                    Label(ContentView.Tab.settings.rawValue, systemImage: ContentView.Tab.settings.icon)
                }
                .tag(ContentView.Tab.settings)
        }
        .tint(Color.adaptive(
            light: AppTheme.Colors.Fallback.primaryLight,
            dark: AppTheme.Colors.Fallback.primaryDark
        ))
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.adaptive(
                    light: AppTheme.Colors.Fallback.primaryLight,
                    dark: AppTheme.Colors.Fallback.primaryDark
                ))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("JouzuLab")
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )

                Text("Loading entries...")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.Fallback.warning)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Import Failed")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            Button {
                retryAction()
            } label: {
                Text("Retry")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    ))
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry importing data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
