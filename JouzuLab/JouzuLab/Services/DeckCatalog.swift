import Foundation
import SwiftData

// MARK: - Deck Category

enum DeckCategory: String, CaseIterable, Identifiable {
    case myDecks = "My Decks"
    case jouzu = "Jouzu"
    case textbooks = "Textbooks"
    case community = "Community"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .myDecks: return "person.fill"
        case .jouzu: return "star.fill"
        case .textbooks: return "book.fill"
        case .community: return "person.3.fill"
        }
    }
}

// MARK: - Catalog Deck Definition

struct CatalogDeck: Identifiable {
    let id: String
    let name: String
    let description: String
    let author: String
    let category: DeckCategory
    let entryCount: Int
    let bundleFileName: String?  // For bundled decks
    let remoteURL: URL?          // For downloadable decks (future)
    let imageSystemName: String
    let tags: [String]

    init(
        id: String,
        name: String,
        description: String,
        author: String,
        category: DeckCategory,
        entryCount: Int,
        bundleFileName: String? = nil,
        remoteURL: URL? = nil,
        imageSystemName: String = "square.stack.3d.up.fill",
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.author = author
        self.category = category
        self.entryCount = entryCount
        self.bundleFileName = bundleFileName
        self.remoteURL = remoteURL
        self.imageSystemName = imageSystemName
        self.tags = tags
    }
}

// MARK: - Deck Catalog

@MainActor
class DeckCatalog: ObservableObject {
    static let shared = DeckCatalog()

    @Published private(set) var availableDecks: [CatalogDeck] = []

    private init() {
        loadCatalog()
    }

    private func loadCatalog() {
        availableDecks = [
            // Jouzu Decks (Official)
            CatalogDeck(
                id: "jouzu_italki_notes",
                name: "italki Lesson Notes",
                description: "~4,000 complete vocabulary and phrases from personal italki Japanese lessons (2023-2026)",
                author: "JouzuLab",
                category: .jouzu,
                entryCount: 4000,
                bundleFileName: "japanese_data",
                imageSystemName: "text.book.closed.fill",
                tags: ["italki", "lessons", "conversation"]
            ),

            // Textbook Decks
            CatalogDeck(
                id: "genki_3rd",
                name: "Genki 3rd Edition",
                description: "Complete vocabulary from Genki I & II textbooks, organized by lesson",
                author: "JouzuLab",
                category: .textbooks,
                entryCount: 1774,
                bundleFileName: "genki_deck",
                imageSystemName: "book.fill",
                tags: ["genki", "textbook", "N5", "N4", "beginner"]
            ),

            // Community Decks (Placeholder for future)
            // These would be loaded from a remote source
        ]
    }

    func decks(for category: DeckCategory) -> [CatalogDeck] {
        availableDecks.filter { $0.category == category }
    }

    func deck(byID id: String) -> CatalogDeck? {
        availableDecks.first { $0.id == id }
    }

    // MARK: - Load/Unload Deck

    func loadDeck(_ catalogDeck: CatalogDeck, modelContext: ModelContext) async throws -> DeckImportResult {
        guard let fileName = catalogDeck.bundleFileName else {
            throw DeckCatalogError.noBundleFile
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw DeckCatalogError.fileNotFound(fileName)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        // Try to decode entries from either format (DeckJSON or JapaneseData)
        let allEntries: [EntryJSON]
        if let deckJSON = try? decoder.decode(DeckJSON.self, from: data) {
            // New deck format with metadata.name, etc.
            allEntries = deckJSON.entries
        } else if let japaneseData = try? decoder.decode(JapaneseData.self, from: data) {
            // Original italki notes format
            allEntries = japaneseData.entries
        } else {
            throw DeckCatalogError.invalidFormat
        }

        // Filter to only include complete entries (has japanese, reading, and english)
        let entries = allEntries.filter { entry in
            guard !entry.japanese.isEmpty else { return false }
            guard let reading = entry.reading, !reading.isEmpty else { return false }
            guard let english = entry.english, !english.isEmpty else { return false }
            return true
        }

        // Check if deck already exists
        let existingDeck = try fetchDeck(byID: catalogDeck.id, modelContext: modelContext)
        let isNewDeck = existingDeck == nil

        // Create or update deck
        let deck: Deck
        if let existing = existingDeck {
            deck = existing
            deck.name = catalogDeck.name
            deck.deckDescription = catalogDeck.description
            deck.author = catalogDeck.author
        } else {
            deck = Deck(
                id: catalogDeck.id,
                name: catalogDeck.name,
                deckDescription: catalogDeck.description,
                author: catalogDeck.author,
                version: "1.0",
                sourceFileName: fileName
            )
            modelContext.insert(deck)
        }

        // Fetch existing entry IDs to avoid duplicates
        let descriptor = FetchDescriptor<Entry>()
        let existingEntries = try modelContext.fetch(descriptor)
        let existingIDs = Set(existingEntries.map { $0.id })

        var importedCount = 0
        var skippedCount = 0
        var newEntryIDs: [String] = deck.entryIDs

        // Import entries
        for (index, entryJSON) in entries.enumerated() {
            let entry = entryJSON.toEntry(deckId: catalogDeck.id, index: index)
            entry.deckId = catalogDeck.id

            if !existingIDs.contains(entry.id) {
                modelContext.insert(entry)
                newEntryIDs.append(entry.id)
                importedCount += 1
            } else {
                if !newEntryIDs.contains(entry.id) {
                    newEntryIDs.append(entry.id)
                }
                if let existingEntry = existingEntries.first(where: { $0.id == entry.id }) {
                    existingEntry.deckId = catalogDeck.id
                }
                skippedCount += 1
            }
        }

        // Update deck metadata
        deck.entryIDs = newEntryIDs
        deck.entryCount = newEntryIDs.count
        deck.installedDate = Date()

        try modelContext.save()

        return DeckImportResult(
            deck: deck,
            entriesImported: importedCount,
            entriesSkipped: skippedCount,
            isNewDeck: isNewDeck
        )
    }

    func unloadDeck(_ catalogDeck: CatalogDeck, modelContext: ModelContext, deleteEntries: Bool = false) throws {
        guard let deck = try fetchDeck(byID: catalogDeck.id, modelContext: modelContext) else {
            throw DeckCatalogError.deckNotInstalled
        }

        if deleteEntries {
            let entryIDs = Set(deck.entryIDs)
            let descriptor = FetchDescriptor<Entry>()
            let allEntries = try modelContext.fetch(descriptor)

            for entry in allEntries where entryIDs.contains(entry.id) {
                modelContext.delete(entry)
            }
        }

        modelContext.delete(deck)
        try modelContext.save()
    }

    func isDeckInstalled(_ catalogDeck: CatalogDeck, modelContext: ModelContext) -> Bool {
        do {
            return try fetchDeck(byID: catalogDeck.id, modelContext: modelContext) != nil
        } catch {
            return false
        }
    }

    private func fetchDeck(byID id: String, modelContext: ModelContext) throws -> Deck? {
        var descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Deck Catalog Error

enum DeckCatalogError: LocalizedError {
    case noBundleFile
    case fileNotFound(String)
    case deckNotInstalled
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .noBundleFile:
            return "This deck does not have a bundled file"
        case .fileNotFound(let name):
            return "Could not find deck file: \(name).json"
        case .deckNotInstalled:
            return "This deck is not installed"
        case .invalidFormat:
            return "Could not parse deck file - invalid format"
        }
    }
}
