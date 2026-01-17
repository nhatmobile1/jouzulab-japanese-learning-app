import SwiftUI
import SwiftData

// MARK: - Browse Filter State

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case japanese = "Japanese (A-Z)"
    case reading = "Reading (あ-ん)"
    case jlptLevel = "JLPT Level"
    case lesson = "Lesson"
    case masteryLevel = "Mastery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dateAdded: return "calendar"
        case .japanese: return "character.ja"
        case .reading: return "textformat.abc"
        case .jlptLevel: return "graduationcap"
        case .lesson: return "book"
        case .masteryLevel: return "chart.bar"
        }
    }
}

@Observable
class BrowseFilterState {
    var selectedDeck: Deck?
    var selectedJLPT: String?
    var selectedEntryType: String?
    var selectedLesson: String?
    var selectedTag: String?
    var showFavoritesOnly: Bool = false
    var searchText: String = ""
    var sortOption: SortOption = .dateAdded
    var sortAscending: Bool = true

    var hasActiveFilters: Bool {
        selectedDeck != nil ||
        selectedJLPT != nil ||
        selectedEntryType != nil ||
        selectedLesson != nil ||
        selectedTag != nil ||
        showFavoritesOnly
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedDeck != nil { count += 1 }
        if selectedJLPT != nil { count += 1 }
        if selectedEntryType != nil { count += 1 }
        if selectedLesson != nil { count += 1 }
        if selectedTag != nil { count += 1 }
        if showFavoritesOnly { count += 1 }
        return count
    }

    func clearAll() {
        selectedDeck = nil
        selectedJLPT = nil
        selectedEntryType = nil
        selectedLesson = nil
        selectedTag = nil
        showFavoritesOnly = false
        searchText = ""
    }
}

// MARK: - Filter Option

struct FilterOption: Identifiable, Hashable {
    let id: String
    let label: String
    let count: Int
    let icon: String?

    init(id: String, label: String, count: Int = 0, icon: String? = nil) {
        self.id = id
        self.label = label
        self.count = count
        self.icon = icon
    }
}

// MARK: - Filter Type

enum FilterType: String, CaseIterable, Identifiable {
    case deck = "Deck"
    case jlpt = "JLPT"
    case entryType = "Type"
    case lesson = "Lesson"
    case tag = "Tag"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .deck: return "square.stack.3d.up"
        case .jlpt: return "graduationcap"
        case .entryType: return "textformat"
        case .lesson: return "book"
        case .tag: return "tag"
        }
    }
}

// MARK: - Filter Data Provider

@MainActor
class FilterDataProvider {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAvailableFilters(
        entries: [Entry],
        decks: [Deck],
        currentFilters: BrowseFilterState
    ) -> [FilterType: [FilterOption]] {
        var result: [FilterType: [FilterOption]] = [:]

        // Deck filter
        var deckOptions: [FilterOption] = []
        for deck in decks {
            let count = entries.filter { deck.entryIDs.contains($0.id) }.count
            if count > 0 {
                deckOptions.append(FilterOption(
                    id: deck.id,
                    label: deck.name,
                    count: count,
                    icon: "square.stack.3d.up"
                ))
            }
        }
        if !deckOptions.isEmpty {
            result[.deck] = deckOptions
        }

        // JLPT filter
        let jlptLevels = ["N5", "N4", "N3", "N2", "N1"]
        var jlptOptions: [FilterOption] = []
        for level in jlptLevels {
            let count = entries.filter { $0.jlptLevel == level }.count
            if count > 0 {
                jlptOptions.append(FilterOption(
                    id: level,
                    label: level,
                    count: count,
                    icon: "graduationcap"
                ))
            }
        }
        if !jlptOptions.isEmpty {
            result[.jlpt] = jlptOptions
        }

        // Entry type filter
        let types = ["vocab", "phrase", "sentence"]
        let typeLabels = ["Vocab": "vocab", "Phrase": "phrase", "Sentence": "sentence"]
        var typeOptions: [FilterOption] = []
        for type in types {
            let count = entries.filter { $0.entryType == type }.count
            if count > 0 {
                let label = typeLabels.first { $0.value == type }?.key ?? type.capitalized
                typeOptions.append(FilterOption(
                    id: type,
                    label: label,
                    count: count,
                    icon: "textformat"
                ))
            }
        }
        if !typeOptions.isEmpty {
            result[.entryType] = typeOptions
        }

        // Lesson filter (from entries that have lessons)
        var lessonCounts: [String: Int] = [:]
        for entry in entries {
            if let lesson = entry.lesson, !lesson.isEmpty {
                lessonCounts[lesson, default: 0] += 1
            }
        }
        if !lessonCounts.isEmpty {
            let sortedLessons = lessonCounts.keys.sorted { l1, l2 in
                // Try to sort numerically if possible
                let num1 = l1.filter { $0.isNumber }
                let num2 = l2.filter { $0.isNumber }
                if let n1 = Int(num1), let n2 = Int(num2) {
                    return n1 < n2
                }
                return l1 < l2
            }
            result[.lesson] = sortedLessons.map { lesson in
                FilterOption(
                    id: lesson,
                    label: lesson,
                    count: lessonCounts[lesson] ?? 0,
                    icon: "book"
                )
            }
        }

        // Tag filter
        var tagCounts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        if !tagCounts.isEmpty {
            let sortedTags = tagCounts.sorted { $0.value > $1.value }.prefix(20)
            result[.tag] = sortedTags.map { tag, count in
                FilterOption(
                    id: tag,
                    label: tag.replacingOccurrences(of: "_", with: " ").capitalized,
                    count: count,
                    icon: Scenario(rawValue: tag)?.icon ?? "tag"
                )
            }
        }

        return result
    }

    func applyFilters(
        entries: [Entry],
        decks: [Deck],
        filters: BrowseFilterState
    ) -> [Entry] {
        var result = entries

        // Filter by deck
        if let deck = filters.selectedDeck {
            let deckEntryIDs = Set(deck.entryIDs)
            result = result.filter { deckEntryIDs.contains($0.id) }
        }

        // Filter by JLPT
        if let jlpt = filters.selectedJLPT {
            result = result.filter { $0.jlptLevel == jlpt }
        }

        // Filter by entry type
        if let type = filters.selectedEntryType {
            result = result.filter { $0.entryType == type }
        }

        // Filter by lesson
        if let lesson = filters.selectedLesson {
            result = result.filter { $0.lesson == lesson }
        }

        // Filter by tag
        if let tag = filters.selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        // Filter by favorites
        if filters.showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Filter by search text
        if !filters.searchText.isEmpty {
            let query = filters.searchText.lowercased()
            result = result.filter { entry in
                entry.japanese.lowercased().contains(query) ||
                (entry.reading?.lowercased().contains(query) ?? false) ||
                (entry.english?.lowercased().contains(query) ?? false)
            }
        }

        // Apply sorting
        result = sortEntries(result, by: filters.sortOption, ascending: filters.sortAscending)

        return result
    }

    func sortEntries(_ entries: [Entry], by option: SortOption, ascending: Bool) -> [Entry] {
        let sorted: [Entry]

        switch option {
        case .dateAdded:
            sorted = entries.sorted { e1, e2 in
                let date1 = e1.lessonDate ?? ""
                let date2 = e2.lessonDate ?? ""
                return ascending ? date1 < date2 : date1 > date2
            }

        case .japanese:
            sorted = entries.sorted { e1, e2 in
                ascending ? e1.japanese < e2.japanese : e1.japanese > e2.japanese
            }

        case .reading:
            sorted = entries.sorted { e1, e2 in
                let r1 = e1.reading ?? e1.japanese
                let r2 = e2.reading ?? e2.japanese
                return ascending ? r1 < r2 : r1 > r2
            }

        case .jlptLevel:
            let jlptOrder = ["N5": 1, "N4": 2, "N3": 3, "N2": 4, "N1": 5]
            sorted = entries.sorted { e1, e2 in
                let o1 = jlptOrder[e1.jlptLevel ?? ""] ?? 99
                let o2 = jlptOrder[e2.jlptLevel ?? ""] ?? 99
                return ascending ? o1 < o2 : o1 > o2
            }

        case .lesson:
            sorted = entries.sorted { e1, e2 in
                let l1 = e1.lesson ?? ""
                let l2 = e2.lesson ?? ""
                // Try numeric sorting for lessons
                let num1 = l1.filter { $0.isNumber }
                let num2 = l2.filter { $0.isNumber }
                if let n1 = Int(num1), let n2 = Int(num2), n1 != n2 {
                    return ascending ? n1 < n2 : n1 > n2
                }
                return ascending ? l1 < l2 : l1 > l2
            }

        case .masteryLevel:
            let masteryOrder: [MasteryLevel: Int] = [.new: 1, .learning: 2, .reviewing: 3, .mastered: 4]
            sorted = entries.sorted { e1, e2 in
                let o1 = masteryOrder[e1.masteryLevel] ?? 0
                let o2 = masteryOrder[e2.masteryLevel] ?? 0
                return ascending ? o1 < o2 : o1 > o2
            }
        }

        return sorted
    }
}
