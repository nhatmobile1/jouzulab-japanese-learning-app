import SwiftUI
import SwiftData

struct SessionConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onStartSession: ([Entry], Int) -> Void

    // Settings state
    @State private var selectedNewCardCount: Int = 10
    @State private var selectedJLPTFilter: String? = nil
    @State private var selectedDeckId: String? = nil

    // Loading state
    @State private var isLoadingSettings: Bool = false
    @State private var settingsApplied: Bool = false
    @State private var loadedEntries: [Entry] = []
    @State private var loadedDecks: [Deck] = []
    @State private var errorMessage: String? = nil

    @StateObject private var audioService = AudioService.shared

    private let newCardOptions = [5, 10, 15, 20, 50]
    private let jlptOptions = ["N5", "N4", "N3", "N2", "N1"]

    // Computed stats from loaded entries
    private var reviewDueCount: Int {
        let now = Date()
        return loadedEntries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count
    }

    private var newCardAvailable: Int {
        loadedEntries.filter { $0.reviewCount == 0 }.count
    }

    private var totalCardsToStudy: Int {
        min(selectedNewCardCount, newCardAvailable) + reviewDueCount
    }

    private var selectedDeck: Deck? {
        guard let id = selectedDeckId else { return nil }
        return loadedDecks.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .background(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.backgroundLight,
                        dark: AppTheme.Colors.Fallback.backgroundDark
                    )
                    .ignoresSafeArea()
                )
                .navigationTitle("Study Setup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                    }
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
                .onAppear {
                    // Load decks immediately on appear
                    loadDecks()
                }
        }
    }

    // MARK: - Data Loading

    private func loadDecks() {
        let descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.entryCount > 0 },
            sortBy: [SortDescriptor(\.installedDate, order: .reverse)]
        )
        if let decks = try? modelContext.fetch(descriptor) {
            loadedDecks = decks
            print("[SessionConfigView] Loaded \(decks.count) decks")
        }
    }

    private func applySettingsAndLoadCards() {
        isLoadingSettings = true
        settingsApplied = false
        loadedEntries = []

        // Use a Task to allow UI to update
        Task {
            // Small delay to show loading state
            try? await Task.sleep(nanoseconds: 100_000_000)

            await MainActor.run {
                // Fetch entries directly from context
                let descriptor = FetchDescriptor<Entry>()
                guard let allEntries = try? modelContext.fetch(descriptor) else {
                    errorMessage = "Failed to load entries"
                    isLoadingSettings = false
                    return
                }

                // Apply filters
                var filtered = allEntries.filter { $0.isComplete }

                // Filter by deck
                if let deckId = selectedDeckId {
                    filtered = filtered.filter { $0.deckId == deckId }
                }

                // Filter by JLPT
                if let jlpt = selectedJLPTFilter {
                    filtered = filtered.filter { $0.jlptLevel == jlpt }
                }

                loadedEntries = filtered
                settingsApplied = true
                isLoadingSettings = false

                print("[SessionConfigView] Applied settings: \(filtered.count) entries loaded (deck: \(selectedDeck?.name ?? "All"))")
            }
        }
    }

    private func startSession() {
        guard !loadedEntries.isEmpty else {
            errorMessage = "No cards available to study"
            return
        }
        onStartSession(loadedEntries, selectedNewCardCount)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Stats preview (only show after settings applied)
                    if settingsApplied {
                        StatsPreviewCard(
                            reviewDue: reviewDueCount,
                            newAvailable: newCardAvailable
                        )
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    // Deck selection
                    if !loadedDecks.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Study From")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )

                            Text("Choose a deck or study all entries")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    DeckOptionButton(
                                        label: "All Decks",
                                        subtitle: "All entries",
                                        icon: "square.stack.3d.up.fill",
                                        isSelected: selectedDeckId == nil
                                    ) {
                                        selectedDeckId = nil
                                        resetSettingsApplied()
                                    }

                                    ForEach(loadedDecks) { deck in
                                        DeckOptionButton(
                                            label: deck.name,
                                            subtitle: "\(deck.entryCount) entries",
                                            icon: "square.stack.3d.up",
                                            isSelected: selectedDeckId == deck.id
                                        ) {
                                            selectedDeckId = deck.id
                                            resetSettingsApplied()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    // New cards limit
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("New Cards")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )

                        Text("Maximum new cards to study this session")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )

                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(newCardOptions, id: \.self) { count in
                                OptionButton(
                                    label: "\(count)",
                                    isSelected: selectedNewCardCount == count
                                ) {
                                    selectedNewCardCount = count
                                    // Don't reset settings for card count change
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // JLPT filter
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("JLPT Level Filter")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )

                        Text("Optional: Focus on a specific JLPT level")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                OptionButton(
                                    label: "All",
                                    isSelected: selectedJLPTFilter == nil
                                ) {
                                    selectedJLPTFilter = nil
                                    resetSettingsApplied()
                                }

                                ForEach(jlptOptions, id: \.self) { level in
                                    OptionButton(
                                        label: level,
                                        isSelected: selectedJLPTFilter == level
                                    ) {
                                        selectedJLPTFilter = level
                                        resetSettingsApplied()
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Audio settings
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("Audio Speed")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )
                            Spacer()

                            // Test button
                            Button {
                                audioService.speak("こんにちは")
                            } label: {
                                HStack(spacing: AppTheme.Spacing.xxs) {
                                    Image(systemName: "speaker.wave.2")
                                    Text("Test")
                                }
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                )
                            }
                        }

                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(SpeechSpeed.allCases) { speed in
                                Button {
                                    audioService.setSpeed(speed)
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.xxs) {
                                        Image(systemName: speed.icon)
                                            .font(.system(size: 14))
                                        Text(speed.rawValue)
                                            .font(AppTheme.Typography.caption)
                                    }
                                    .foregroundStyle(
                                        audioService.currentSpeed == speed
                                            ? .white
                                            : Color.adaptive(
                                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                                            )
                                    )
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(
                                        audioService.currentSpeed == speed
                                            ? Color.adaptive(
                                                light: AppTheme.Colors.Fallback.primaryLight,
                                                dark: AppTheme.Colors.Fallback.primaryDark
                                            )
                                            : Color.adaptive(
                                                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                                            )
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Spacer(minLength: AppTheme.Spacing.xl)
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }

            // Bottom button area
            bottomButtonArea
        }
    }

    private func resetSettingsApplied() {
        settingsApplied = false
        loadedEntries = []
    }

    // MARK: - Bottom Button Area

    @ViewBuilder
    private var bottomButtonArea: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if isLoadingSettings {
                // Loading state
                VStack(spacing: AppTheme.Spacing.sm) {
                    ProgressView()
                        .tint(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                    Text("Loading cards...")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            } else if !settingsApplied {
                // Apply Settings button
                Button {
                    applySettingsAndLoadCards()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Apply Settings")
                            .font(AppTheme.Typography.headline)
                    }
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
                    .shadow(
                        color: Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            } else {
                // Start Session button (only after settings applied)
                StartSessionButton(
                    totalCards: totalCardsToStudy,
                    reviewDue: reviewDueCount,
                    newCards: min(selectedNewCardCount, newCardAvailable),
                    isEnabled: totalCardsToStudy > 0
                ) {
                    startSession()
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Start Session Button

struct StartSessionButton: View {
    let totalCards: Int
    let reviewDue: Int
    let newCards: Int
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Main button - centered, not full width
            Button(action: action) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text(isEnabled ? "Start Session" : "No Cards")
                        .font(AppTheme.Typography.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    isEnabled
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                        : Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                )
                .clipShape(Capsule())
                .shadow(
                    color: isEnabled
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.3)
                        : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isEnabled)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Stats Preview Card

struct StatsPreviewCard: View {
    let reviewDue: Int
    let newAvailable: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("\(reviewDue)")
                    .font(AppTheme.Typography.statMedium)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.accentLight,
                            dark: AppTheme.Colors.Fallback.accentDark
                        )
                    )
                Text("Reviews Due")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    ).opacity(0.3)
                )
                .frame(width: 1, height: 40)

            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("\(newAvailable)")
                    .font(AppTheme.Typography.statMedium)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                Text("New Available")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Option Button

struct OptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(
                    isSelected
                        ? .white
                        : Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                )
                .frame(minWidth: 44)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    isSelected
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                        : Color.adaptive(
                            light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                            dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deck Option Button

struct DeckOptionButton: View {
    let label: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    Text(label)
                        .font(AppTheme.Typography.callout)
                        .lineLimit(1)
                }
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        isSelected
                            ? .white.opacity(0.8)
                            : Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                    )
            }
            .foregroundStyle(
                isSelected
                    ? .white
                    : Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
            )
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                isSelected
                    ? Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                    : Color.adaptive(
                        light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                        dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SessionConfigView { entries, newCardLimit in
        print("Start session: \(entries.count) entries, \(newCardLimit) new card limit")
    }
    .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
