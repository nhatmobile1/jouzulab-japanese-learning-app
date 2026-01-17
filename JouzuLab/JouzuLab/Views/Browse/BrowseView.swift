import SwiftUI
import SwiftData

// MARK: - Browse View

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @Query(sort: \Deck.installedDate, order: .reverse) private var decks: [Deck]

    @State private var filterState = BrowseFilterState()
    @State private var availableFilters: [FilterType: [FilterOption]] = [:]
    @State private var showSideMenu = false

    private var filteredEntries: [Entry] {
        let provider = FilterDataProvider(modelContext: modelContext)
        return provider.applyFilters(entries: allEntries, decks: decks, filters: filterState)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // App Header
                    AppHeader(
                        title: "Browse",
                        subtitle: "\(filteredEntries.count) entries",
                        onMenuTap: {
                            withAnimation(AppTheme.Animation.standard) {
                                showSideMenu = true
                            }
                        },
                        onProfileTap: {
                            // TODO: Navigate to profile
                        }
                    )

                    // Search bar
                    SearchBarView(text: $filterState.searchText)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)

                    // Filter bar
                    FilterBarView(
                        filterState: filterState,
                        availableFilters: availableFilters,
                        decks: decks
                    )

                    // Content
                    if filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        entryListView
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
                    print("Navigate to: \(item.rawValue)")
                }
            }
            .navigationBarHidden(true)
            .task {
                updateAvailableFilters()
            }
            .onChange(of: allEntries.count) {
                updateAvailableFilters()
            }
            .onChange(of: decks.count) {
                updateAvailableFilters()
            }
        }
    }

    // MARK: - Update Filters

    private func updateAvailableFilters() {
        let provider = FilterDataProvider(modelContext: modelContext)
        availableFilters = provider.getAvailableFilters(
            entries: allEntries,
            decks: decks,
            currentFilters: filterState
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Spacer()

            Image(systemName: filterState.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )

            Text(filterState.hasActiveFilters ? "No matching entries" : "No entries found")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )

            if filterState.hasActiveFilters {
                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        filterState.clearAll()
                    }
                } label: {
                    Text("Clear Filters")
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                }
            } else {
                Text("Import a deck to get started")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Entry List

    private var entryListView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(filteredEntries) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        BrowseEntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )

            TextField("Search Japanese, reading, or English...", text: $text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

// MARK: - Browse Entry Card

struct BrowseEntryCard: View {
    let entry: Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Main content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                // Japanese
                Text(entry.japanese)
                    .font(AppTheme.Typography.japaneseBody)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                // Reading
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

                // English
                if let english = entry.english {
                    Text(english)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                        .lineLimit(1)
                }
            }

            Spacer()

            // Metadata badges
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                // JLPT badge
                if let jlpt = entry.jlptLevel {
                    Text(jlpt)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(jlpt.jlptColor.opacity(0.2))
                        .foregroundStyle(jlpt.jlptColor)
                        .clipShape(Capsule())
                }

                // Lesson badge
                if let lesson = entry.lesson {
                    Text(lesson)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                }

                // Favorite indicator
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
        }
        .padding(AppTheme.Spacing.md)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Preview

#Preview {
    BrowseView()
        .modelContainer(for: [Entry.self, Deck.self], inMemory: true)
}
