import Foundation
import SwiftData

// MARK: - Mastery Level

enum MasteryLevel: String, Codable {
    case new
    case learning
    case reviewing
    case mastered
}

// MARK: - Entry Model (SwiftData)

@Model
class Entry {
    // MARK: Core Data
    @Attribute(.unique) var id: String
    var japanese: String
    var reading: String?
    var english: String?
    var entryType: String
    var lessonDate: String?
    var tags: [String]
    var grammarPatterns: [String]
    var jlptLevel: String?
    var contextNote: String?
    var isSubEntry: Bool
    var sourceLine: Int

    // MARK: Computed
    var isComplete: Bool {
        reading != nil && english != nil
    }

    // MARK: Progress Tracking (Phase 3)
    var masteryLevel: MasteryLevel
    var lastReviewed: Date?
    var nextReview: Date?
    var easeFactor: Double
    var reviewCount: Int
    var correctCount: Int
    var isFavorite: Bool

    // MARK: Init

    init(
        id: String,
        japanese: String,
        reading: String? = nil,
        english: String? = nil,
        entryType: String = "vocab",
        lessonDate: String? = nil,
        tags: [String] = [],
        grammarPatterns: [String] = [],
        jlptLevel: String? = nil,
        contextNote: String? = nil,
        isSubEntry: Bool = false,
        sourceLine: Int = 0
    ) {
        self.id = id
        self.japanese = japanese
        self.reading = reading
        self.english = english
        self.entryType = entryType
        self.lessonDate = lessonDate
        self.tags = tags
        self.grammarPatterns = grammarPatterns
        self.jlptLevel = jlptLevel
        self.contextNote = contextNote
        self.isSubEntry = isSubEntry
        self.sourceLine = sourceLine

        // Default progress values
        self.masteryLevel = .new
        self.lastReviewed = nil
        self.nextReview = nil
        self.easeFactor = 2.5
        self.reviewCount = 0
        self.correctCount = 0
        self.isFavorite = false
    }
}

// MARK: - JSON Import Structure

struct JapaneseData: Codable {
    let metadata: Metadata
    let entries: [EntryJSON]
}

struct Metadata: Codable {
    let version: String
    let createdDate: String
    let totalEntries: Int
    let entriesWithReading: Int
    let entriesWithEnglish: Int
    let entriesMissingReading: Int
    let entriesMissingEnglish: Int
    let lessonCount: Int
    let source: String

    enum CodingKeys: String, CodingKey {
        case version
        case createdDate = "created_date"
        case totalEntries = "total_entries"
        case entriesWithReading = "entries_with_reading"
        case entriesWithEnglish = "entries_with_english"
        case entriesMissingReading = "entries_missing_reading"
        case entriesMissingEnglish = "entries_missing_english"
        case lessonCount = "lesson_count"
        case source
    }
}

struct EntryJSON: Codable {
    let id: String
    let japanese: String
    let reading: String?
    let english: String?
    let entryType: String
    let lessonDate: String?
    let tags: [String]
    let grammarPatterns: [String]
    let jlptLevel: String?
    let contextNote: String?
    let isSubEntry: Bool
    let sourceLine: Int

    enum CodingKeys: String, CodingKey {
        case id, japanese, reading, english, tags
        case entryType = "entry_type"
        case lessonDate = "lesson_date"
        case grammarPatterns = "grammar_patterns"
        case jlptLevel = "jlpt_level"
        case contextNote = "context_note"
        case isSubEntry = "is_sub_entry"
        case sourceLine = "source_line"
    }

    func toEntry() -> Entry {
        Entry(
            id: id,
            japanese: japanese,
            reading: reading,
            english: english,
            entryType: entryType,
            lessonDate: lessonDate,
            tags: tags,
            grammarPatterns: grammarPatterns,
            jlptLevel: jlptLevel,
            contextNote: contextNote,
            isSubEntry: isSubEntry,
            sourceLine: sourceLine
        )
    }
}

// MARK: - Scenario Definition

enum Scenario: String, CaseIterable, Identifiable {
    case all = "all"
    case general = "general"
    case time = "time"
    case restaurant = "restaurant"
    case dailyLife = "daily_life"
    case family = "family"
    case shopping = "shopping"
    case weather = "weather"
    case travel = "travel"
    case transportation = "transportation"
    case health = "health"
    case greetings = "greetings"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .general: return "General"
        case .time: return "Time"
        case .restaurant: return "Restaurant"
        case .dailyLife: return "Daily Life"
        case .family: return "Family"
        case .shopping: return "Shopping"
        case .weather: return "Weather"
        case .travel: return "Travel"
        case .transportation: return "Transportation"
        case .health: return "Health"
        case .greetings: return "Greetings"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .general: return "text.book.closed"
        case .time: return "clock"
        case .restaurant: return "fork.knife"
        case .dailyLife: return "house"
        case .family: return "person.3"
        case .shopping: return "bag"
        case .weather: return "cloud.sun"
        case .travel: return "airplane"
        case .transportation: return "tram"
        case .health: return "heart"
        case .greetings: return "hand.wave"
        }
    }
}

// MARK: - Entry Type

enum EntryType: String, CaseIterable, Identifiable {
    case all = "all"
    case vocab = "vocab"
    case phrase = "phrase"
    case sentence = "sentence"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .vocab: return "Vocab"
        case .phrase: return "Phrase"
        case .sentence: return "Sentence"
        }
    }
}
