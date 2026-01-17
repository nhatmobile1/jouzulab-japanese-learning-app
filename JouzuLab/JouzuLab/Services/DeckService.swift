import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Deck Service

@MainActor
class DeckService: ObservableObject {
    private let modelContext: ModelContext

    @Published var isImporting = false
    @Published var lastError: DeckError?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Import Deck from URL

    func importDeck(from url: URL) async throws -> DeckImportResult {
        isImporting = true
        defer { isImporting = false }

        // Start accessing security-scoped resource if needed
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Read and parse the JSON file
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DeckError.fileReadFailed(error)
        }

        let decoder = JSONDecoder()
        let deckJSON: DeckJSON
        do {
            deckJSON = try decoder.decode(DeckJSON.self, from: data)
        } catch {
            throw DeckError.invalidFormat(error)
        }

        // Generate deck ID if not provided
        let deckID = deckJSON.metadata.id ?? UUID().uuidString

        // Check if deck already exists
        let existingDeck = try fetchDeck(byID: deckID)
        let isNewDeck = existingDeck == nil

        // Create or update deck
        let deck: Deck
        if let existing = existingDeck {
            deck = existing
            deck.name = deckJSON.metadata.name
            deck.deckDescription = deckJSON.metadata.description
            deck.author = deckJSON.metadata.author
            deck.version = deckJSON.metadata.version ?? "1.0"
        } else {
            deck = Deck(
                id: deckID,
                name: deckJSON.metadata.name,
                deckDescription: deckJSON.metadata.description,
                author: deckJSON.metadata.author,
                version: deckJSON.metadata.version ?? "1.0",
                sourceFileName: url.lastPathComponent
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
        for (index, entryJSON) in deckJSON.entries.enumerated() {
            let entry = entryJSON.toEntry(deckId: deckID, index: index)

            if !existingIDs.contains(entry.id) {
                modelContext.insert(entry)
                newEntryIDs.append(entry.id)
                importedCount += 1
            } else {
                // Entry exists, but ensure it's tracked in this deck
                if !newEntryIDs.contains(entry.id) {
                    newEntryIDs.append(entry.id)
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

    // MARK: - Fetch Decks

    func fetchAllDecks() throws -> [Deck] {
        let descriptor = FetchDescriptor<Deck>(
            sortBy: [SortDescriptor(\.installedDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchDeck(byID id: String) throws -> Deck? {
        var descriptor = FetchDescriptor<Deck>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Delete Deck

    func deleteDeck(_ deck: Deck, deleteEntries: Bool = false) throws {
        if deleteEntries {
            // Delete all entries that belong to this deck
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

    // MARK: - Get Entries for Deck

    func getEntries(for deck: Deck) throws -> [Entry] {
        let entryIDs = Set(deck.entryIDs)
        let descriptor = FetchDescriptor<Entry>()
        let allEntries = try modelContext.fetch(descriptor)
        return allEntries.filter { entryIDs.contains($0.id) }
    }

    // MARK: - Deck Stats

    func getStats(for deck: Deck) throws -> DeckStats {
        let entries = try getEntries(for: deck)

        let newCount = entries.filter { $0.masteryLevel == .new }.count
        let learningCount = entries.filter { $0.masteryLevel == .learning }.count
        let reviewingCount = entries.filter { $0.masteryLevel == .reviewing }.count
        let masteredCount = entries.filter { $0.masteryLevel == .mastered }.count

        let now = Date()
        let dueCount = entries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count

        return DeckStats(
            totalEntries: entries.count,
            newCount: newCount,
            learningCount: learningCount,
            reviewingCount: reviewingCount,
            masteredCount: masteredCount,
            dueForReview: dueCount
        )
    }
}

// MARK: - Deck Stats

struct DeckStats {
    let totalEntries: Int
    let newCount: Int
    let learningCount: Int
    let reviewingCount: Int
    let masteredCount: Int
    let dueForReview: Int

    var progressPercentage: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(masteredCount) / Double(totalEntries)
    }
}

// MARK: - Deck Error

enum DeckError: LocalizedError {
    case fileReadFailed(Error)
    case invalidFormat(Error)
    case deckNotFound
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileReadFailed(let error):
            return "Could not read file: \(error.localizedDescription)"
        case .invalidFormat(let error):
            return "Invalid deck format: \(error.localizedDescription)"
        case .deckNotFound:
            return "Deck not found"
        case .deleteFailed(let error):
            return "Could not delete deck: \(error.localizedDescription)"
        }
    }
}

// MARK: - JSON File Type

extension UTType {
    static var deckJSON: UTType {
        UTType(importedAs: "com.jouzulab.deck", conformingTo: .json)
    }
}
