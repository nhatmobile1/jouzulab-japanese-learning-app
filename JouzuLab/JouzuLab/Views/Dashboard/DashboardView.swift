import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @Query private var allDecks: [Deck]

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var streakService = StreakService.shared
    @State private var showSideMenu = false

    // MARK: - Computed Stats

    /// Entries currently being studied (not new)
    private var studyingEntries: [Entry] {
        allEntries.filter { $0.masteryLevel != .new }
    }

    private var totalStudying: Int {
        studyingEntries.count
    }

    private var totalEntries: Int {
        allEntries.count
    }

    private var favoritesCount: Int {
        allEntries.filter { $0.isFavorite }.count
    }

    private var masteredCount: Int {
        allEntries.filter { $0.masteryLevel == .mastered }.count
    }

    private var learningCount: Int {
        allEntries.filter { $0.masteryLevel == .learning || $0.masteryLevel == .reviewing }.count
    }

    private var reviewDueCount: Int {
        let now = Date()
        return allEntries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count
    }

    private var highFrequencyCount: Int {
        allEntries.filter { $0.isHighFrequency }.count
    }

    private var recentEntries: [Entry] {
        Array(studyingEntries
            .sorted { ($0.lastReviewed ?? .distantPast) > ($1.lastReviewed ?? .distantPast) }
            .prefix(5))
    }

    /// Entry type counts for entries being studied
    private var studyingEntryTypeCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for entry in studyingEntries {
            counts[entry.entryType, default: 0] += 1
        }
        return counts
    }

    /// Cards reviewed today
    private var cardsReviewedToday: Int {
        streakService.todayStats?.cardsReviewed ?? 0
    }

    /// All-time accuracy
    private var allTimeAccuracy: Double? {
        let totalReviews = allEntries.reduce(0) { $0 + $1.reviewCount }
        let totalCorrect = allEntries.reduce(0) { $0 + $1.correctCount }
        guard totalReviews > 0 else { return nil }
        return Double(totalCorrect) / Double(totalReviews)
    }

    /// JLPT level progress (mastered/learning vs total for each level)
    private var jlptProgress: [(level: String, mastered: Int, learning: Int, total: Int)] {
        let levels = ["N5", "N4", "N3", "N2", "N1"]
        return levels.compactMap { level in
            let entriesForLevel = allEntries.filter { $0.jlptLevel == level }
            guard !entriesForLevel.isEmpty else { return nil }
            let mastered = entriesForLevel.filter { $0.masteryLevel == .mastered }.count
            let learning = entriesForLevel.filter { $0.masteryLevel == .learning || $0.masteryLevel == .reviewing }.count
            return (level, mastered, learning, entriesForLevel.count)
        }
    }

    /// Mastery progress by deck
    private var deckProgress: [(deck: Deck, mastered: Int, learning: Int, total: Int)] {
        allDecks.compactMap { deck in
            let entriesForDeck = allEntries.filter { $0.deckId == deck.id }
            guard !entriesForDeck.isEmpty else { return nil }
            let mastered = entriesForDeck.filter { $0.masteryLevel == .mastered }.count
            let learning = entriesForDeck.filter { $0.masteryLevel == .learning || $0.masteryLevel == .reviewing }.count
            return (deck, mastered, learning, entriesForDeck.count)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App Header
                AppHeader(
                    title: "Home",
                    subtitle: "Welcome back!",
                    onMenuTap: {
                        withAnimation(AppTheme.Animation.standard) {
                            showSideMenu = true
                        }
                    },
                    onProfileTap: {
                        // TODO: Navigate to profile
                    }
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Welcome Header
                        welcomeHeader

                        // Study Streak Card
                        streakCard

                        // Today's Progress Card
                        todayProgressCard

                        // Quick Stats Grid
                        statsGrid

                        // Study Progress Card
                        progressCard

                        // JLPT Progress Breakdown
                        if !jlptProgress.isEmpty {
                            jlptProgressSection
                        }

                        // Deck Progress Breakdown
                        if !deckProgress.isEmpty {
                            deckProgressSection
                        }

                        // Quick Actions
                        quickActions

                        // Entry Type Breakdown
                        entryTypeBreakdown

                        // Recent Activity (if any)
                        if !recentEntries.isEmpty {
                            recentActivitySection
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )

            // Side Menu Overlay
            SideMenu(isPresented: $showSideMenu) { item in
                // Handle navigation from side menu
                print("Navigate to: \(item.rawValue)")
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Welcome to")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )

            Text("JouzuLab")
                .font(AppTheme.Typography.title)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )

            Text("\(totalEntries.formatted()) entries from your italki lessons")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppTheme.Spacing.md),
            GridItem(.flexible(), spacing: AppTheme.Spacing.md)
        ], spacing: AppTheme.Spacing.md) {
            StatCard(
                title: "Total Studying",
                value: "\(totalStudying.formatted())",
                icon: "book.fill",
                color: Color.adaptive(
                    light: AppTheme.Colors.Fallback.primaryLight,
                    dark: AppTheme.Colors.Fallback.primaryDark
                )
            )

            StatCard(
                title: "Starred",
                value: "\(favoritesCount)",
                icon: "star.fill",
                color: .yellow
            )

            StatCard(
                title: "High Frequency",
                value: "\(highFrequencyCount)",
                icon: "flame.fill",
                color: .orange
            )

            StatCard(
                title: "Due for Review",
                value: "\(reviewDueCount)",
                icon: "clock.fill",
                color: Color.adaptive(
                    light: AppTheme.Colors.Fallback.accentLight,
                    dark: AppTheme.Colors.Fallback.accentDark
                )
            )
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                Text("Study Progress")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                ProgressStat(
                    label: "Mastered",
                    count: masteredCount,
                    total: totalEntries,
                    color: AppTheme.Colors.Fallback.success
                )

                ProgressStat(
                    label: "Learning",
                    count: learningCount,
                    total: totalEntries,
                    color: Color.adaptive(
                        light: AppTheme.Colors.Fallback.accentLight,
                        dark: AppTheme.Colors.Fallback.accentDark
                    )
                )

                ProgressStat(
                    label: "New",
                    count: totalEntries - masteredCount - learningCount,
                    total: totalEntries,
                    color: Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Quick Actions")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            HStack(spacing: AppTheme.Spacing.md) {
                QuickActionButton(
                    title: "Browse",
                    icon: "magnifyingglass",
                    color: Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )

                QuickActionButton(
                    title: "Study",
                    icon: "rectangle.stack.fill",
                    color: Color.adaptive(
                        light: AppTheme.Colors.Fallback.accentLight,
                        dark: AppTheme.Colors.Fallback.accentDark
                    )
                )

                QuickActionButton(
                    title: "Shadow",
                    icon: "waveform",
                    color: Color.adaptive(
                        light: AppTheme.Colors.Fallback.secondaryLight,
                        dark: AppTheme.Colors.Fallback.secondaryDark
                    )
                )
            }
        }
    }

    // MARK: - Entry Type Breakdown

    private var entryTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Studying by Type")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            HStack(spacing: AppTheme.Spacing.md) {
                EntryTypeBar(
                    type: "Vocab",
                    count: studyingEntryTypeCounts["vocab"] ?? 0,
                    total: totalStudying,
                    color: AppTheme.Colors.Fallback.vocab
                )

                EntryTypeBar(
                    type: "Phrase",
                    count: studyingEntryTypeCounts["phrase"] ?? 0,
                    total: totalStudying,
                    color: AppTheme.Colors.Fallback.phrase
                )

                EntryTypeBar(
                    type: "Sentence",
                    count: studyingEntryTypeCounts["sentence"] ?? 0,
                    total: totalStudying,
                    color: AppTheme.Colors.Fallback.sentence
                )
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Recent Activity")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(recentEntries, id: \.id) { entry in
                    RecentEntryRow(entry: entry)
                }
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Study Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streakService.stats.currentStreak > 0 ? .orange : Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    ))
                Text("Study Streak")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                Spacer()
            }

            HStack(spacing: AppTheme.Spacing.xl) {
                // Current streak
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("\(streakService.stats.currentStreak)")
                        .font(AppTheme.Typography.statLarge)
                        .foregroundStyle(streakService.stats.currentStreak > 0 ? .orange : Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        ))
                    Text("Current")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                // Best streak
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("\(streakService.stats.longestStreak)")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                    Text("Best")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                // Total study days
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("\(streakService.stats.totalStudyDays)")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                    Text("Total Days")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                Spacer()
            }

            // Weekly activity (uses existing component from StreakWidget.swift)
            WeeklyActivityView(streakService: streakService)
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Today's Progress Card

    private var todayProgressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                Text("Today")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                Spacer()
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                // Cards reviewed today
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("\(cardsReviewedToday)")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                    Text("Reviewed")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                // Due for review
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("\(reviewDueCount)")
                        .font(AppTheme.Typography.statMedium)
                        .foregroundStyle(reviewDueCount > 0 ? .orange : AppTheme.Colors.Fallback.success)
                    Text("Due")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                // Today's accuracy
                VStack(spacing: AppTheme.Spacing.xxs) {
                    if let accuracy = streakService.todayAccuracy {
                        Text("\(Int(accuracy * 100))%")
                            .font(AppTheme.Typography.statMedium)
                            .foregroundStyle(accuracy >= 0.8 ? AppTheme.Colors.Fallback.success : .orange)
                    } else {
                        Text("-")
                            .font(AppTheme.Typography.statMedium)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                                )
                            )
                    }
                    Text("Accuracy")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }

                // All-time accuracy
                VStack(spacing: AppTheme.Spacing.xxs) {
                    if let accuracy = allTimeAccuracy {
                        Text("\(Int(accuracy * 100))%")
                            .font(AppTheme.Typography.statMedium)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )
                    } else {
                        Text("-")
                            .font(AppTheme.Typography.statMedium)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                                )
                            )
                    }
                    Text("All-time")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - JLPT Progress Section

    private var jlptProgressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                Text("JLPT Progress")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(jlptProgress, id: \.level) { item in
                    JLPTProgressRow(
                        level: item.level,
                        mastered: item.mastered,
                        learning: item.learning,
                        total: item.total
                    )
                }
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
    }

    // MARK: - Deck Progress Section

    private var deckProgressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                Text("Deck Progress")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(deckProgress, id: \.deck.id) { item in
                    DeckProgressRow(
                        name: item.deck.name,
                        mastered: item.mastered,
                        learning: item.learning,
                        total: item.total
                    )
                }
            }
            .padding(AppTheme.Spacing.md)
            .cardStyle()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(AppTheme.Typography.statMedium)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct ProgressStat: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("\(count)")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(color)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )

            Text("\(String(format: "%.0f", percentage))%")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) action")
        .accessibilityAddTraits(.isButton)
    }
}

struct EntryTypeBar: View {
    let type: String
    let count: Int
    let total: Int
    let color: Color

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(type)
                .font(AppTheme.Typography.captionBold)
                .foregroundStyle(color)

            Text("\(count.formatted())")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.2))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geometry.size.width * percentage, height: 4)
                    }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentEntryRow: View {
    let entry: Entry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.japanese)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                if let reading = entry.reading {
                    Text(reading)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
            }

            Spacer()

            Text(entry.entryType.capitalized)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(entry.entryType.entryTypeColor)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(entry.entryType.entryTypeColor.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

// MARK: - JLPT Progress Row

struct JLPTProgressRow: View {
    let level: String
    let mastered: Int
    let learning: Int
    let total: Int

    private var progressPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(mastered + learning) / CGFloat(total)
    }

    private var masteredPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(mastered) / CGFloat(total)
    }

    private var levelColor: Color {
        switch level {
        case "N5": return AppTheme.Colors.Fallback.jlptN5
        case "N4": return AppTheme.Colors.Fallback.jlptN4
        case "N3": return AppTheme.Colors.Fallback.jlptN3
        case "N2": return AppTheme.Colors.Fallback.jlptN2
        case "N1": return AppTheme.Colors.Fallback.jlptN1
        default: return AppTheme.Colors.Fallback.primaryLight
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(level)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(levelColor)
                    .frame(width: 30, alignment: .leading)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(levelColor.opacity(0.15))
                            .frame(height: 8)

                        // Learning progress (lighter)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(levelColor.opacity(0.5))
                            .frame(width: geometry.size.width * progressPercentage, height: 8)

                        // Mastered progress (solid)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(levelColor)
                            .frame(width: geometry.size.width * masteredPercentage, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(mastered + learning)/\(total)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
}

// MARK: - Deck Progress Row

struct DeckProgressRow: View {
    let name: String
    let mastered: Int
    let learning: Int
    let total: Int

    private var progressPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(mastered + learning) / CGFloat(total)
    }

    private var masteredPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(mastered) / CGFloat(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(name)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                    .lineLimit(1)

                Spacer()

                Text("\(mastered + learning)/\(total)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.15))
                        .frame(height: 6)

                    // Learning progress (lighter)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.5))
                        .frame(width: geometry.size.width * progressPercentage, height: 6)

                    // Mastered progress (solid)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.Colors.Fallback.success)
                        .frame(width: geometry.size.width * masteredPercentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
