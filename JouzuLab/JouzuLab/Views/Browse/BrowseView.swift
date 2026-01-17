import SwiftUI
import SwiftData

// MARK: - JLPT Level Enum

enum JLPTLevel: String, CaseIterable, Identifiable {
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"

    var id: String { rawValue }
}

// MARK: - Browse View

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    @State private var selectedJLPT: JLPTLevel = .n5
    @State private var selectedType: EntryType = .vocab
    @State private var selectedScenario: Scenario?
    @State private var showFavoritesOnly = false

    // Filtered entries for the selected JLPT + type
    private var filteredByJLPT: [Entry] {
        allEntries.filter { $0.jlptLevel == selectedJLPT.rawValue }
    }

    // Count for each scenario at current JLPT + type
    private func scenarioCount(for scenario: Scenario) -> Int {
        filteredByJLPT.filter { entry in
            let typeMatch = selectedType == .all || entry.entryType == selectedType.rawValue
            let scenarioMatch = entry.tags.contains(scenario.rawValue)
            return typeMatch && scenarioMatch
        }.count
    }

    // Total count for current JLPT + type
    private var totalCount: Int {
        filteredByJLPT.filter { entry in
            selectedType == .all || entry.entryType == selectedType.rawValue
        }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // JLPT Level Tabs
                jlptTabBar

                // Entry Type Toggle
                entryTypeToggle

                // Scenario Grid
                scenarioGrid
            }
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(AppTheme.Animation.quick) {
                            showFavoritesOnly.toggle()
                        }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                    }
                    .accessibilityLabel(showFavoritesOnly ? "Show all" : "Show favorites only")
                }
            }
            .navigationDestination(for: Scenario.self) { scenario in
                ScenarioEntryListView(
                    jlptLevel: selectedJLPT,
                    entryType: selectedType,
                    scenario: scenario,
                    showFavoritesOnly: showFavoritesOnly
                )
            }
        }
    }

    // MARK: - JLPT Tab Bar

    private var jlptTabBar: some View {
        HStack(spacing: 0) {
            ForEach(JLPTLevel.allCases) { level in
                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        selectedJLPT = level
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(level.rawValue)
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(selectedJLPT == level ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .foregroundStyle(
                                selectedJLPT == level
                                    ? Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                    : Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                            )

                        // Underline indicator
                        Rectangle()
                            .fill(
                                selectedJLPT == level
                                    ? Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                    : Color.clear
                            )
                            .frame(height: 3)
                    }
                }
                .accessibilityLabel("\(level.rawValue) level")
                .accessibilityAddTraits(selectedJLPT == level ? .isSelected : [])
            }
        }
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
    }

    // MARK: - Entry Type Toggle

    private var entryTypeToggle: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach([EntryType.vocab, EntryType.phrase, EntryType.sentence], id: \.self) { type in
                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        selectedType = type
                    }
                } label: {
                    Text(type.displayName)
                        .font(AppTheme.Typography.callout)
                        .fontWeight(selectedType == type ? .semibold : .regular)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            selectedType == type
                                ? Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                )
                                : Color.adaptive(
                                    light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                    dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                                )
                        )
                        .foregroundStyle(
                            selectedType == type
                                ? .white
                                : Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .accessibilityLabel("\(type.displayName) entries")
                .accessibilityAddTraits(selectedType == type ? .isSelected : [])
            }

            Spacer()

            // Total count badge
            Text("\(totalCount)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
    }

    // MARK: - Scenario Grid

    // Scenarios that have entries for current JLPT + type
    private var availableScenarios: [Scenario] {
        Scenario.allCases.filter { scenario in
            scenario != .all && scenarioCount(for: scenario) > 0
        }
    }

    private var scenarioGrid: some View {
        ScrollView {
            if availableScenarios.isEmpty {
                // Empty state
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )

                    Text("No entries found")
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )

                    Text("Try selecting a different JLPT level or entry type")
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xxl)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md)
                ], spacing: AppTheme.Spacing.md) {
                    ForEach(availableScenarios) { scenario in
                        let count = scenarioCount(for: scenario)

                        NavigationLink(value: scenario) {
                            ScenarioCard(
                                scenario: scenario,
                                count: count
                            )
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
    }
}

// MARK: - Scenario Card

struct ScenarioCard: View {
    let scenario: Scenario
    let count: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: scenario.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
            }

            Spacer()

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(scenario.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text("\(count) entries")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(height: 120)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Scenario Entry List View

struct ScenarioEntryListView: View {
    let jlptLevel: JLPTLevel
    let entryType: EntryType
    let scenario: Scenario
    let showFavoritesOnly: Bool

    @Query private var allEntries: [Entry]
    @State private var searchText = ""

    private var filteredEntries: [Entry] {
        var entries = allEntries.filter { entry in
            let jlptMatch = entry.jlptLevel == jlptLevel.rawValue
            let typeMatch = entryType == .all || entry.entryType == entryType.rawValue
            let scenarioMatch = entry.tags.contains(scenario.rawValue)
            return jlptMatch && typeMatch && scenarioMatch
        }

        if showFavoritesOnly {
            entries = entries.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            entries = entries.filter { entry in
                entry.japanese.lowercased().contains(query) ||
                (entry.reading?.lowercased().contains(query) ?? false) ||
                (entry.english?.lowercased().contains(query) ?? false)
            }
        }

        return entries
    }

    var body: some View {
        EntryListView(
            entries: filteredEntries,
            searchText: $searchText
        )
        .navigationTitle(scenario.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    BrowseView()
        .modelContainer(for: Entry.self, inMemory: true)
}
