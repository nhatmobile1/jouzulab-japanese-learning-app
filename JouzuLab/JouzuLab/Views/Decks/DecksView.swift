import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DecksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.installedDate, order: .reverse) private var decks: [Deck]

    @State private var showImportPicker = false
    @State private var showImportResult = false
    @State private var importResult: DeckImportResult?
    @State private var importError: Error?
    @State private var showErrorAlert = false
    @State private var deckToDelete: Deck?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    EmptyDecksView {
                        showImportPicker = true
                    }
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckDetailView(deck: deck)) {
                                DeckRowView(deck: deck)
                            }
                        }
                        .onDelete(perform: confirmDelete)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showImportPicker = true
                    } label: {
                        Image(systemName: "plus")
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
            .alert("Import Error", isPresented: $showErrorAlert) {
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

    // MARK: - Import Handling

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

    // MARK: - Delete Handling

    private func confirmDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            deckToDelete = decks[index]
            showDeleteConfirmation = true
        }
    }

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

// MARK: - Empty State

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
                Text("No Decks Installed")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text("Import JSON deck files to add vocabulary sets")
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
                    Text("Import Deck")
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
    }
}

// MARK: - Deck Row

struct DeckRowView: View {
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

// MARK: - Preview

#Preview {
    DecksView()
        .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
