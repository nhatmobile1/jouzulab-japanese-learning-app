import SwiftUI
import SwiftData

// MARK: - Filter Bar View

struct FilterBarView: View {
    @Bindable var filterState: BrowseFilterState
    let availableFilters: [FilterType: [FilterOption]]
    let decks: [Deck]

    @State private var showFilterSheet = false
    @State private var selectedFilterType: FilterType?

    var body: some View {
        VStack(spacing: 0) {
            // Active filters as chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    // Filter button
                    Button {
                        showFilterSheet = true
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xxs) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 16, weight: .medium))
                            Text("Filters")
                                .font(AppTheme.Typography.callout)
                            if filterState.activeFilterCount > 0 {
                                Text("\(filterState.activeFilterCount)")
                                    .font(AppTheme.Typography.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.primaryLight,
                                            dark: AppTheme.Colors.Fallback.primaryDark
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
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
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                        .clipShape(Capsule())
                    }

                    // Sort button
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                if filterState.sortOption == option {
                                    filterState.sortAscending.toggle()
                                } else {
                                    filterState.sortOption = option
                                    filterState.sortAscending = true
                                }
                            } label: {
                                HStack {
                                    Label(option.rawValue, systemImage: option.icon)
                                    if filterState.sortOption == option {
                                        Image(systemName: filterState.sortAscending ? "chevron.up" : "chevron.down")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xxs) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .medium))
                            Text(filterState.sortOption.rawValue)
                                .font(AppTheme.Typography.caption)
                                .lineLimit(1)
                            Image(systemName: filterState.sortAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                            )
                        )
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                        .clipShape(Capsule())
                    }

                    // Active filter chips
                    if let deck = filterState.selectedDeck {
                        ActiveFilterChip(
                            label: deck.name,
                            icon: "square.stack.3d.up"
                        ) {
                            filterState.selectedDeck = nil
                        }
                    }

                    if let jlpt = filterState.selectedJLPT {
                        ActiveFilterChip(
                            label: jlpt,
                            icon: "graduationcap"
                        ) {
                            filterState.selectedJLPT = nil
                        }
                    }

                    if let type = filterState.selectedEntryType {
                        ActiveFilterChip(
                            label: type.capitalized,
                            icon: "textformat"
                        ) {
                            filterState.selectedEntryType = nil
                        }
                    }

                    if let lesson = filterState.selectedLesson {
                        ActiveFilterChip(
                            label: lesson,
                            icon: "book"
                        ) {
                            filterState.selectedLesson = nil
                        }
                    }

                    if let tag = filterState.selectedTag {
                        ActiveFilterChip(
                            label: tag.replacingOccurrences(of: "_", with: " ").capitalized,
                            icon: "tag"
                        ) {
                            filterState.selectedTag = nil
                        }
                    }

                    if filterState.showFavoritesOnly {
                        ActiveFilterChip(
                            label: "Favorites",
                            icon: "star.fill"
                        ) {
                            filterState.showFavoritesOnly = false
                        }
                    }

                    // Clear all button
                    if filterState.hasActiveFilters {
                        Button {
                            withAnimation(AppTheme.Animation.quick) {
                                filterState.clearAll()
                            }
                        } label: {
                            Text("Clear")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.surfaceLight,
                    dark: AppTheme.Colors.Fallback.surfaceDark
                )
            )
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                filterState: filterState,
                availableFilters: availableFilters,
                decks: decks
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Active Filter Chip

struct ActiveFilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(label)
                .font(AppTheme.Typography.caption)
                .lineLimit(1)
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    onRemove()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.primaryLight,
                dark: AppTheme.Colors.Fallback.primaryDark
            ).opacity(0.15)
        )
        .foregroundStyle(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.primaryLight,
                dark: AppTheme.Colors.Fallback.primaryDark
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var filterState: BrowseFilterState
    let availableFilters: [FilterType: [FilterOption]]
    let decks: [Deck]

    var body: some View {
        NavigationStack {
            List {
                // Favorites toggle
                Section {
                    Toggle(isOn: $filterState.showFavoritesOnly) {
                        Label("Favorites Only", systemImage: "star.fill")
                    }
                    .tint(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                }

                // Deck filter
                if let deckOptions = availableFilters[.deck], !deckOptions.isEmpty {
                    Section("Deck") {
                        ForEach(deckOptions) { option in
                            FilterOptionRow(
                                option: option,
                                isSelected: filterState.selectedDeck?.id == option.id
                            ) {
                                if filterState.selectedDeck?.id == option.id {
                                    filterState.selectedDeck = nil
                                } else {
                                    filterState.selectedDeck = decks.first { $0.id == option.id }
                                }
                            }
                        }
                    }
                }

                // JLPT filter
                if let jlptOptions = availableFilters[.jlpt], !jlptOptions.isEmpty {
                    Section("JLPT Level") {
                        ForEach(jlptOptions) { option in
                            FilterOptionRow(
                                option: option,
                                isSelected: filterState.selectedJLPT == option.id
                            ) {
                                filterState.selectedJLPT = filterState.selectedJLPT == option.id ? nil : option.id
                            }
                        }
                    }
                }

                // Entry type filter
                if let typeOptions = availableFilters[.entryType], !typeOptions.isEmpty {
                    Section("Entry Type") {
                        ForEach(typeOptions) { option in
                            FilterOptionRow(
                                option: option,
                                isSelected: filterState.selectedEntryType == option.id
                            ) {
                                filterState.selectedEntryType = filterState.selectedEntryType == option.id ? nil : option.id
                            }
                        }
                    }
                }

                // Lesson filter
                if let lessonOptions = availableFilters[.lesson], !lessonOptions.isEmpty {
                    Section("Lesson") {
                        ForEach(lessonOptions) { option in
                            FilterOptionRow(
                                option: option,
                                isSelected: filterState.selectedLesson == option.id
                            ) {
                                filterState.selectedLesson = filterState.selectedLesson == option.id ? nil : option.id
                            }
                        }
                    }
                }

                // Tag filter
                if let tagOptions = availableFilters[.tag], !tagOptions.isEmpty {
                    Section("Tags") {
                        ForEach(tagOptions) { option in
                            FilterOptionRow(
                                option: option,
                                isSelected: filterState.selectedTag == option.id
                            ) {
                                filterState.selectedTag = filterState.selectedTag == option.id ? nil : option.id
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if filterState.hasActiveFilters {
                        Button("Clear All") {
                            filterState.clearAll()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Filter Option Row

struct FilterOptionRow: View {
    let option: FilterOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                        .frame(width: 24)
                }

                Text(option.label)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Spacer()

                Text("\(option.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
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
