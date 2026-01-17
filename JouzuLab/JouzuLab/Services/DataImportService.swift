import Foundation
import SwiftData

// MARK: - Data Import Service

@MainActor
class DataImportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Import from Bundle

    func importFromBundle(filename: String = "japanese_data") async throws -> ImportResult {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound(filename)
        }

        return try await importFromURL(url)
    }

    // MARK: - Fast Initial Import (for first launch)

    func performInitialImport(filename: String = "japanese_data") async throws -> ImportResult {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ImportError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let japaneseData = try decoder.decode(JapaneseData.self, from: data)

        // Direct batch insert without checking (only use on first launch)
        for entryJSON in japaneseData.entries {
            let entry = entryJSON.toEntry()
            modelContext.insert(entry)
        }

        try modelContext.save()

        return ImportResult(
            totalInFile: japaneseData.entries.count,
            imported: japaneseData.entries.count,
            skipped: 0,
            metadata: japaneseData.metadata
        )
    }

    // MARK: - Import from URL

    func importFromURL(_ url: URL) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        let japaneseData = try decoder.decode(JapaneseData.self, from: data)

        // Fetch all existing IDs in one query (much faster than per-entry queries)
        let descriptor = FetchDescriptor<Entry>()
        let existingEntries = try modelContext.fetch(descriptor)
        let existingIDs = Set(existingEntries.map { $0.id })

        var imported = 0
        var skipped = 0

        // Batch insert - only insert entries that don't exist
        for (index, entryJSON) in japaneseData.entries.enumerated() {
            let entry = entryJSON.toEntry(index: index)
            if !existingIDs.contains(entry.id) {
                modelContext.insert(entry)
                imported += 1
            } else {
                skipped += 1
            }
        }

        // Single save at the end
        try modelContext.save()

        return ImportResult(
            totalInFile: japaneseData.entries.count,
            imported: imported,
            skipped: skipped,
            metadata: japaneseData.metadata
        )
    }

    // MARK: - Check if Import Needed

    func needsImport() throws -> Bool {
        let descriptor = FetchDescriptor<Entry>()
        let count = try modelContext.fetchCount(descriptor)
        return count == 0
    }

    // MARK: - Clear All Data

    func clearAllData() throws {
        try modelContext.delete(model: Entry.self)
        try modelContext.save()
    }

    // MARK: - Get Stats

    func getStats() throws -> DataStats {
        let allDescriptor = FetchDescriptor<Entry>()
        let total = try modelContext.fetchCount(allDescriptor)

        let entries = try modelContext.fetch(allDescriptor)

        let withReading = entries.filter { $0.reading != nil }.count
        let withEnglish = entries.filter { $0.english != nil }.count
        let complete = entries.filter { $0.isComplete }.count

        var byScenario: [String: Int] = [:]
        var byType: [String: Int] = [:]

        for entry in entries {
            for tag in entry.tags {
                byScenario[tag, default: 0] += 1
            }
            byType[entry.entryType, default: 0] += 1
        }

        return DataStats(
            total: total,
            withReading: withReading,
            withEnglish: withEnglish,
            complete: complete,
            byScenario: byScenario,
            byType: byType
        )
    }
}

// MARK: - Import Result

struct ImportResult {
    let totalInFile: Int
    let imported: Int
    let skipped: Int
    let metadata: Metadata
}

// MARK: - Data Stats

struct DataStats {
    let total: Int
    let withReading: Int
    let withEnglish: Int
    let complete: Int
    let byScenario: [String: Int]
    let byType: [String: Int]
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find \(filename).json in bundle"
        case .decodingFailed(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        }
    }
}
