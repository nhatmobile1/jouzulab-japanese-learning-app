import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DecksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.installedDate, order: .reverse) private var installedDecks: [Deck]

    @State private var selectedCategory: DeckCategory = .myDecks
    @State private var showImportPicker = false
    @State private var showImportResult = false
    @State private var importResult: DeckImportResult?
    @State private var importError: Error?
    @State private var showErrorAlert = false
    @State private var deckToDelete: Deck?
    @State private var showDeleteConfirmation = false

    @StateObject private var catalog = DeckCatalog.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                CategoryTabBar(selectedCategory: $selectedCategory)

                // Content based on selected category
                Group {
                    switch selectedCategory {
                    case .myDecks:
                        MyDecksSection(
                            installedDecks: installedDecks,
                            onImport: { showImportPicker = true },
                            onDelete: { deck in
                                deckToDelete = deck
                                showDeleteConfirmation = true
                            }
                        )
                    case .jouzu:
                        CatalogDecksSection(
                            category: .jouzu,
                            installedDeckIDs: Set(installedDecks.map { $0.id }),
                            onLoad: loadCatalogDeck,
                            onUnload: unloadCatalogDeck
                        )
                    case .textbooks:
                        CatalogDecksSection(
                            category: .textbooks,
                            installedDeckIDs: Set(installedDecks.map { $0.id }),
                            onLoad: loadCatalogDeck,
                            onUnload: unloadCatalogDeck
                        )
                    case .community:
                        CommunityDecksSection()
                    }
                }
            }
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Decks")
            .toolbar {
                if selectedCategory == .myDecks {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showImportPicker = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Complete", isPresented: $showImportResult) {
                Button("OK") { }
            } message: {
                if let result = importResult {
                    Text(importResultMessage(result))
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(importError?.localizedDescription ?? "Unknown error")
            }
            .alert("Delete Deck?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Deck Only", role: .destructive) {
                    if let deck = deckToDelete {
                        deleteDeck(deck, deleteEntries: false)
                    }
                }
                Button("Delete Deck & Entries", role: .destructive) {
                    if let deck = deckToDelete {
                        deleteDeck(deck, deleteEntries: true)
                    }
                }
            } message: {
                Text("Do you want to also delete the entries that were imported with this deck?")
            }
        }
    }

    // MARK: - Catalog Deck Actions

    private func loadCatalogDeck(_ catalogDeck: CatalogDeck) {
        Task {
            do {
                let result = try await catalog.loadDeck(catalogDeck, modelContext: modelContext)
                importResult = result
                showImportResult = true
            } catch {
                importError = error
                showErrorAlert = true
            }
        }
    }

    private func unloadCatalogDeck(_ catalogDeck: CatalogDeck) {
        do {
            try catalog.unloadDeck(catalogDeck, modelContext: modelContext, deleteEntries: true)
        } catch {
            importError = error
            showErrorAlert = true
        }
    }

    // MARK: - File Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await importDeck(from: url)
            }
        case .failure(let error):
            importError = error
            showErrorAlert = true
        }
    }

    private func importDeck(from url: URL) async {
        let service = DeckService(modelContext: modelContext)
        do {
            let result = try await service.importDeck(from: url)
            importResult = result
            showImportResult = true
        } catch {
            importError = error
            showErrorAlert = true
        }
    }

    private func importResultMessage(_ result: DeckImportResult) -> String {
        if result.isNewDeck {
            return "Installed \"\(result.deck.name)\" with \(result.entriesImported) entries."
        } else {
            return "Updated \"\(result.deck.name)\". Added \(result.entriesImported) new entries, \(result.entriesSkipped) already existed."
        }
    }

    // MARK: - Delete

    private func deleteDeck(_ deck: Deck, deleteEntries: Bool) {
        let service = DeckService(modelContext: modelContext)
        do {
            try service.deleteDeck(deck, deleteEntries: deleteEntries)
        } catch {
            importError = error
            showErrorAlert = true
        }
    }
}

// MARK: - Category Tab Bar

struct CategoryTabBar: View {
    @Binding var selectedCategory: DeckCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(DeckCategory.allCases) { category in
                    CategoryTab(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(AppTheme.Animation.standard) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(
                    isSelected
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                        : Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    isSelected
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.1)
                        : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - My Decks Section

struct MyDecksSection: View {
    let installedDecks: [Deck]
    let onImport: () -> Void
    let onDelete: (Deck) -> Void

    var body: some View {
        if installedDecks.isEmpty {
            EmptyDecksView(onImport: onImport)
        } else {
            List {
                ForEach(installedDecks) { deck in
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        InstalledDeckRow(deck: deck)
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        onDelete(installedDecks[index])
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - Installed Deck Row

struct InstalledDeckRow: View {
    let deck: Deck
    @Environment(\.modelContext) private var modelContext

    @State private var stats: DeckStats?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(deck.name)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Spacer()

                Text("\(deck.entryCount) cards")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }

            if let description = deck.deckDescription {
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .lineLimit(2)
            }

            // Progress bar
            if let stats = stats {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView(value: stats.progressPercentage)
                        .tint(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )

                    Text("\(Int(stats.progressPercentage * 100))%")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
        .task {
            loadStats()
        }
    }

    private func loadStats() {
        let service = DeckService(modelContext: modelContext)
        stats = try? service.getStats(for: deck)
    }
}

// MARK: - Catalog Decks Section

struct CatalogDecksSection: View {
    let category: DeckCategory
    let installedDeckIDs: Set<String>
    let onLoad: (CatalogDeck) -> Void
    let onUnload: (CatalogDeck) -> Void

    @StateObject private var catalog = DeckCatalog.shared

    private var decks: [CatalogDeck] {
        catalog.decks(for: category)
    }

    var body: some View {
        if decks.isEmpty {
            EmptyCategoryView(category: category)
        } else {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.md) {
                    ForEach(decks) { deck in
                        CatalogDeckCard(
                            deck: deck,
                            isInstalled: installedDeckIDs.contains(deck.id),
                            onLoad: { onLoad(deck) },
                            onUnload: { onUnload(deck) }
                        )
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
    }
}

// MARK: - Catalog Deck Card

struct CatalogDeckCard: View {
    let deck: CatalogDeck
    let isInstalled: Bool
    let onLoad: () -> Void
    let onUnload: () -> Void

    @State private var showUnloadConfirmation = false
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Image(systemName: deck.imageSystemName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .frame(width: 48, height: 48)
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(deck.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Label("\(deck.entryCount) cards", systemImage: "rectangle.stack")
                        Text("by \(deck.author)")
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                }

                Spacer()

                // Status badge
                if isInstalled {
                    Text("Installed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.Fallback.success)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(AppTheme.Colors.Fallback.success.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Description
            Text(deck.description)
                .font(AppTheme.Typography.body)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )
                .lineLimit(3)

            // Tags
            if !deck.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(deck.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                        dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Action button
            HStack(spacing: AppTheme.Spacing.sm) {
                if isInstalled {
                    Button {
                        showUnloadConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Unload")
                        }
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.Fallback.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.Fallback.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    }
                } else {
                    Button {
                        isLoading = true
                        onLoad()
                        // Note: isLoading will be reset when the view updates
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                            Text("Load Deck")
                        }
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    }
                    .disabled(isLoading)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .shadow(
            color: .black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        .onChange(of: isInstalled) { _, newValue in
            if newValue {
                isLoading = false
            }
        }
        .confirmationDialog("Unload Deck?", isPresented: $showUnloadConfirmation, titleVisibility: .visible) {
            Button("Unload & Delete Entries", role: .destructive) {
                onUnload()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the deck and all its entries from your library. You can reload it at any time.")
        }
    }
}

// MARK: - Empty State Views

struct EmptyDecksView: View {
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No Decks Loaded")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text("Browse the Jouzu or Textbooks tabs to load a deck, or import your own JSON file")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .multilineTextAlignment(.center)
            }

            Button {
                onImport()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import JSON File")
                }
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCategoryView: View {
    let category: DeckCategory

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: category.icon)
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("No \(category.rawValue) Available")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text("Check back later for new content")
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
    }
}

// MARK: - Community Decks Section (Placeholder)

struct CommunityDecksSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Community Decks")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text("Coming soon! User-created decks will be available here.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    DecksView()
        .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
