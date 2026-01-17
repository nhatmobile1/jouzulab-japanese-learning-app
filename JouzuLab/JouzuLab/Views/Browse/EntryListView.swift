import SwiftUI
import SwiftData

struct EntryListView: View {
    let entries: [Entry]
    @Binding var searchText: String

    @State private var selectedEntry: Entry?

    var body: some View {
        List {
            if entries.isEmpty {
                emptyState
            } else {
                ForEach(entries, id: \.id) { entry in
                    NavigationLink(value: entry) {
                        EntryCard(entry: entry)
                    }
                    .listRowInsets(EdgeInsets(
                        top: AppTheme.Spacing.xs,
                        leading: AppTheme.Spacing.md,
                        bottom: AppTheme.Spacing.xs,
                        trailing: AppTheme.Spacing.md
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            entry.isFavorite.toggle()
                        } label: {
                            Label(
                                entry.isFavorite ? "Unstar" : "Star",
                                systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                            )
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
        )
        .searchable(text: $searchText, prompt: "Search Japanese, reading, or English")
        .navigationDestination(for: Entry.self) { entry in
            EntryDetailView(entry: entry)
        }
        .overlay {
            if !searchText.isEmpty && entries.isEmpty {
                noSearchResults
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries", systemImage: "doc.text")
        } description: {
            Text("No entries found for this filter.")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - No Search Results

    private var noSearchResults: some View {
        ContentUnavailableView.search(text: searchText)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EntryListView(
            entries: [],
            searchText: .constant("")
        )
    }
}
