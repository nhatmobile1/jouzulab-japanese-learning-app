import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    @Environment(\.colorScheme) private var colorScheme
    @State private var showSideMenu = false

    // MARK: - Computed Stats

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
        Array(allEntries
            .sorted { ($0.lastReviewed ?? .distantPast) > ($1.lastReviewed ?? .distantPast) }
            .prefix(5))
    }

    private var entryTypeCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for entry in allEntries {
            counts[entry.entryType, default: 0] += 1
        }
        return counts
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

                        // Quick Stats Grid
                        statsGrid

                        // Study Progress Card
                        progressCard

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
                title: "Total Entries",
                value: "\(totalEntries.formatted())",
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
            Text("Entry Types")
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
                    count: entryTypeCounts["vocab"] ?? 0,
                    total: totalEntries,
                    color: AppTheme.Colors.Fallback.vocab
                )

                EntryTypeBar(
                    type: "Phrase",
                    count: entryTypeCounts["phrase"] ?? 0,
                    total: totalEntries,
                    color: AppTheme.Colors.Fallback.phrase
                )

                EntryTypeBar(
                    type: "Sentence",
                    count: entryTypeCounts["sentence"] ?? 0,
                    total: totalEntries,
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

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Entry.self, inMemory: true)
}
