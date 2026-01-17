import Foundation
import SwiftData

// MARK: - Deck Model

@Model
class Deck {
    @Attribute(.unique) var id: String
    var name: String
    var deckDescription: String?
    var author: String?
    var version: String
    var entryCount: Int
    var installedDate: Date
    var sourceFileName: String?

    // Track which entries belong to this deck
    var entryIDs: [String]

    init(
        id: String = UUID().uuidString,
        name: String,
        deckDescription: String? = nil,
        author: String? = nil,
        version: String = "1.0",
        entryCount: Int = 0,
        installedDate: Date = Date(),
        sourceFileName: String? = nil,
        entryIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.deckDescription = deckDescription
        self.author = author
        self.version = version
        self.entryCount = entryCount
        self.installedDate = installedDate
        self.sourceFileName = sourceFileName
        self.entryIDs = entryIDs
    }
}

// MARK: - Deck JSON Structure

struct DeckJSON: Codable {
    let metadata: DeckMetadata
    let entries: [EntryJSON]
}

struct DeckMetadata: Codable {
    let id: String?
    let name: String
    let description: String?
    let author: String?
    let version: String?
    let createdDate: String?
    let totalEntries: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, author, version
        case createdDate = "created_date"
        case totalEntries = "total_entries"
    }
}

// MARK: - Deck Import Result

struct DeckImportResult {
    let deck: Deck
    let entriesImported: Int
    let entriesSkipped: Int
    let isNewDeck: Bool
}
