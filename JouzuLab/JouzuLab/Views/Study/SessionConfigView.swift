import SwiftUI
import SwiftData

struct SessionConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @Query(sort: \Deck.installedDate, order: .reverse) private var decks: [Deck]

    let onStartSession: (Int, String?, Deck?) -> Void

    @State private var selectedNewCardCount: Int = 10
    @State private var selectedJLPTFilter: String? = nil
    @State private var selectedDeck: Deck? = nil

    @StateObject private var audioService = AudioService.shared

    private let newCardOptions = [5, 10, 15, 20, 50]
    private let jlptOptions = ["N5", "N4", "N3", "N2", "N1"]

    private var reviewDueCount: Int {
        let now = Date()
        return filteredEntries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count
    }

    private var newCardAvailable: Int {
        filteredEntries.filter { $0.masteryLevel == .new && $0.reviewCount == 0 }.count
    }

    private var filteredEntries: [Entry] {
        var entries = allEntries

        // Filter by deck
        if let deck = selectedDeck {
            let deckEntryIDs = Set(deck.entryIDs)
            entries = entries.filter { deckEntryIDs.contains($0.id) }
        }

        // Filter by JLPT
        if let jlpt = selectedJLPTFilter {
            entries = entries.filter { $0.jlptLevel == jlpt }
        }

        return entries
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Session stats preview
                    StatsPreviewCard(
                        reviewDue: reviewDueCount,
                        newAvailable: newCardAvailable
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Deck selection
                    if !decks.isEmpty {
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
                                        subtitle: "\(allEntries.count) entries",
                                        icon: "square.stack.3d.up.fill",
                                        isSelected: selectedDeck == nil
                                    ) {
                                        selectedDeck = nil
                                    }

                                    ForEach(decks) { deck in
                                        DeckOptionButton(
                                            label: deck.name,
                                            subtitle: "\(deck.entryCount) entries",
                                            icon: "square.stack.3d.up",
                                            isSelected: selectedDeck?.id == deck.id
                                        ) {
                                            selectedDeck = deck
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
                                }

                                ForEach(jlptOptions, id: \.self) { level in
                                    OptionButton(
                                        label: level,
                                        isSelected: selectedJLPTFilter == level
                                    ) {
                                        selectedJLPTFilter = level
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
                        Text("Audio Settings")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )

                        // Speed
                        HStack {
                            Text("Speed")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                            Spacer()
                            HStack(spacing: AppTheme.Spacing.xs) {
                                ForEach(SpeechSpeed.allCases) { speed in
                                    Button {
                                        audioService.setSpeed(speed)
                                    } label: {
                                        Image(systemName: speed.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(
                                                audioService.currentSpeed == speed
                                                    ? .white
                                                    : Color.adaptive(
                                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                                    )
                                            )
                                            .frame(width: 32, height: 32)
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
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }

                        // Volume
                        HStack {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                                    )
                                )
                            Slider(value: Binding(
                                get: { Double(audioService.volume) },
                                set: { audioService.setVolume(Float($0)) }
                            ), in: 0...1)
                            .tint(Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            ))
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                                    )
                                )
                        }

                        // Test button
                        Button {
                            audioService.speak("こんにちは")
                        } label: {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                Text("Test Audio")
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
                    .padding(AppTheme.Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Spacer(minLength: AppTheme.Spacing.xl)

                    // Start button
                    Button {
                        onStartSession(selectedNewCardCount, selectedJLPTFilter, selectedDeck)
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Study Session")
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
                    .disabled(reviewDueCount == 0 && newCardAvailable == 0)
                    .opacity((reviewDueCount == 0 && newCardAvailable == 0) ? 0.5 : 1)
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }
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
        }
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
    SessionConfigView { newCards, jlptFilter, deck in
        print("Start session: \(newCards) new cards, filter: \(jlptFilter ?? "none"), deck: \(deck?.name ?? "all")")
    }
    .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
