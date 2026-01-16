import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    @State private var searchText = ""
    @State private var selectedScenario: Scenario = .all
    @State private var selectedType: EntryType = .all
    @State private var showFavoritesOnly = false

    private var filteredEntries: [Entry] {
        var entries = allEntries

        // Filter by favorites
        if showFavoritesOnly {
            entries = entries.filter { $0.isFavorite }
        }

        // Filter by scenario
        if selectedScenario != .all {
            entries = entries.filter { $0.tags.contains(selectedScenario.rawValue) }
        }

        // Filter by entry type
        if selectedType != .all {
            entries = entries.filter { $0.entryType == selectedType.rawValue }
        }

        // Filter by search
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

    private var favoritesCount: Int {
        allEntries.filter { $0.isFavorite }.count
    }

    private var scenarioCounts: [Scenario: Int] {
        var counts: [Scenario: Int] = [.all: allEntries.count]
        for scenario in Scenario.allCases where scenario != .all {
            counts[scenario] = allEntries.filter { $0.tags.contains(scenario.rawValue) }.count
        }
        return counts
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scenario Pills
                scenarioScrollView

                // Entry List
                EntryListView(
                    entries: filteredEntries,
                    searchText: $searchText
                )
            }
            .navigationTitle("Browse")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showFavoritesOnly.toggle()
                        }
                    } label: {
                        Label(
                            "Starred",
                            systemImage: showFavoritesOnly ? "star.fill" : "star"
                        )
                        .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Entry Type", selection: $selectedType) {
                            ForEach(EntryType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedType == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
        }
    }

    // MARK: - Scenario Scroll View

    private var scenarioScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Scenario.allCases) { scenario in
                    ScenarioPill(
                        scenario: scenario,
                        count: scenarioCounts[scenario] ?? 0,
                        isSelected: selectedScenario == scenario
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScenario = scenario
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Scenario Pill

struct ScenarioPill: View {
    let scenario: Scenario
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: scenario.icon)
                    .font(.subheadline)

                Text(scenario.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BrowseView()
        .modelContainer(for: Entry.self, inMemory: true)
}
