import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var stats: DeckStats?
    @State private var entries: [Entry] = []
    @State private var showStudySession = false
    @State private var showDeleteConfirmation = false
    @State private var sessionQueue: [Entry] = []

    private let srsService = SRSService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header card
                VStack(spacing: AppTheme.Spacing.md) {
                    // Deck icon
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )

                    // Deck name
                    Text(deck.name)
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                        .multilineTextAlignment(.center)

                    // Description
                    if let description = deck.deckDescription {
                        Text(description)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                            .multilineTextAlignment(.center)
                    }

                    // Metadata
                    HStack(spacing: AppTheme.Spacing.lg) {
                        if let author = deck.author {
                            Label(author, systemImage: "person")
                        }
                        Label("v\(deck.version)", systemImage: "tag")
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .cardStyle()
                .padding(.horizontal, AppTheme.Spacing.md)

                // Stats card
                if let stats = stats {
                    DeckStatsCard(stats: stats)
                        .padding(.horizontal, AppTheme.Spacing.md)
                }

                // Study button
                Button {
                    startStudySession()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Study This Deck")
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .disabled(entries.isEmpty)
                .opacity(entries.isEmpty ? 0.5 : 1)

                // Entries preview
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Entries")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )

                        Spacer()

                        Text("\(entries.count) total")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                    }

                    // Show first few entries
                    ForEach(entries.prefix(10)) { entry in
                        DeckEntryRow(entry: entry)
                    }

                    if entries.count > 10 {
                        Text("+ \(entries.count - 10) more entries")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppTheme.Spacing.xs)
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .cardStyle()
                .padding(.horizontal, AppTheme.Spacing.md)

                // Delete button
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Deck")
                    }
                    .font(AppTheme.Typography.callout)
                }
                .padding(.top, AppTheme.Spacing.lg)

                Spacer(minLength: AppTheme.Spacing.xl)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Deck Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadDeckData()
        }
        .alert("Delete Deck?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Deck Only", role: .destructive) {
                deleteDeck(deleteEntries: false)
            }
            Button("Delete Deck & Entries", role: .destructive) {
                deleteDeck(deleteEntries: true)
            }
        } message: {
            Text("Do you want to also delete the \(deck.entryCount) entries that were imported with this deck?")
        }
        .fullScreenCover(isPresented: $showStudySession) {
            FlashcardSessionView(initialQueue: sessionQueue) { _ in
                showStudySession = false
            }
        }
    }

    // MARK: - Data Loading

    private func loadDeckData() {
        let service = DeckService(modelContext: modelContext)
        do {
            entries = try service.getEntries(for: deck)
            stats = try service.getStats(for: deck)
        } catch {
            print("Failed to load deck data: \(error)")
        }
    }

    // MARK: - Study Session

    private func startStudySession() {
        sessionQueue = srsService.buildStudyQueue(
            from: entries,
            newCardLimit: 20
        )
        if !sessionQueue.isEmpty {
            showStudySession = true
        }
    }

    // MARK: - Delete

    private func deleteDeck(deleteEntries: Bool) {
        let service = DeckService(modelContext: modelContext)
        do {
            try service.deleteDeck(deck, deleteEntries: deleteEntries)
            dismiss()
        } catch {
            print("Failed to delete deck: \(error)")
        }
    }
}

// MARK: - Stats Card

struct DeckStatsCard: View {
    let stats: DeckStats

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                            dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: stats.progressPercentage)
                    .stroke(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(stats.progressPercentage * 100))%")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

            // Stats grid
            HStack(spacing: AppTheme.Spacing.lg) {
                StatBadge(value: stats.newCount, label: "New", color: AppTheme.Colors.Fallback.primaryLight)
                StatBadge(value: stats.learningCount, label: "Learning", color: AppTheme.Colors.Fallback.warning)
                StatBadge(value: stats.reviewingCount, label: "Reviewing", color: AppTheme.Colors.Fallback.accentLight)
                StatBadge(value: stats.masteredCount, label: "Mastered", color: AppTheme.Colors.Fallback.success)
            }

            if stats.dueForReview > 0 {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                    Text("\(stats.dueForReview) cards due for review")
                }
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.Fallback.warning)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("\(value)")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )
        }
    }
}

// MARK: - Entry Row

struct DeckEntryRow: View {
    let entry: Entry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.japanese)
                    .font(AppTheme.Typography.japaneseBody)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                if let reading = entry.reading {
                    Text(reading)
                        .font(AppTheme.Typography.readingSmall)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                }
            }

            Spacer()

            // Mastery indicator
            Circle()
                .fill(masteryColor)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }

    private var masteryColor: Color {
        switch entry.masteryLevel {
        case .new:
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.textTertiaryLight,
                dark: AppTheme.Colors.Fallback.textTertiaryDark
            )
        case .learning:
            return AppTheme.Colors.Fallback.warning
        case .reviewing:
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.accentLight,
                dark: AppTheme.Colors.Fallback.accentDark
            )
        case .mastered:
            return AppTheme.Colors.Fallback.success
        }
    }
}

// MARK: - Preview

#Preview {
    let deck = Deck(
        name: "JLPT N5 Vocabulary",
        deckDescription: "Essential vocabulary for JLPT N5 level",
        author: "JouzuLab",
        version: "1.0",
        entryCount: 100
    )

    return NavigationStack {
        DeckDetailView(deck: deck)
    }
    .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
