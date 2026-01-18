import Foundation
import SwiftData

// MARK: - Persisted Session State

struct PersistedSessionState: Codable {
    let entryIDs: [String]
    let currentIndex: Int
    let cardsReviewed: Int
    let correctCount: Int
    let gradeDistribution: [Int: Int]  // SRSGrade.rawValue -> count
    let sessionStartTime: Date
    let savedAt: Date

    init(
        entryIDs: [String],
        currentIndex: Int,
        stats: SessionStats,
        sessionStartTime: Date
    ) {
        self.entryIDs = entryIDs
        self.currentIndex = currentIndex
        self.cardsReviewed = stats.cardsReviewed
        self.correctCount = stats.correctCount
        // Convert SRSGrade keys to Int for Codable
        self.gradeDistribution = Dictionary(uniqueKeysWithValues: stats.gradeDistribution.map { ($0.key.rawValue, $0.value) })
        self.sessionStartTime = sessionStartTime
        self.savedAt = Date()
    }

    func toSessionStats() -> SessionStats {
        var stats = SessionStats()
        stats.cardsReviewed = cardsReviewed
        stats.correctCount = correctCount
        // Convert Int keys back to SRSGrade
        for (rawValue, count) in gradeDistribution {
            if let grade = SRSGrade(rawValue: rawValue) {
                stats.gradeDistribution[grade] = count
            }
        }
        return stats
    }
}

// MARK: - Study Session Manager

class StudySessionManager: ObservableObject {
    static let shared = StudySessionManager()

    private let userDefaults = UserDefaults.standard
    private let sessionKey = "activeStudySession"

    @Published private(set) var hasActiveSession: Bool = false
    @Published private(set) var activeSessionInfo: SessionInfo?

    struct SessionInfo {
        let totalCards: Int
        let cardsRemaining: Int
        let cardsReviewed: Int
        let accuracy: Double
        let savedAt: Date
    }

    private init() {
        loadSessionInfo()
    }

    // MARK: - Public Methods

    /// Save current session state
    func saveSession(
        entryIDs: [String],
        currentIndex: Int,
        stats: SessionStats,
        sessionStartTime: Date
    ) {
        let state = PersistedSessionState(
            entryIDs: entryIDs,
            currentIndex: currentIndex,
            stats: stats,
            sessionStartTime: sessionStartTime
        )

        if let encoded = try? JSONEncoder().encode(state) {
            userDefaults.set(encoded, forKey: sessionKey)
            loadSessionInfo()
        }
    }

    /// Load persisted session state
    func loadSession() -> PersistedSessionState? {
        guard let data = userDefaults.data(forKey: sessionKey),
              let state = try? JSONDecoder().decode(PersistedSessionState.self, from: data) else {
            return nil
        }
        return state
    }

    /// Clear the saved session
    func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
        hasActiveSession = false
        activeSessionInfo = nil
    }

    /// Restore entries from persisted state
    func restoreEntries(from state: PersistedSessionState, allEntries: [Entry]) -> [Entry] {
        let idSet = Set(state.entryIDs)
        let entryMap = Dictionary(uniqueKeysWithValues: allEntries.filter { idSet.contains($0.id) }.map { ($0.id, $0) })

        // Preserve order from saved state
        return state.entryIDs.compactMap { entryMap[$0] }
    }

    // MARK: - Private Methods

    private func loadSessionInfo() {
        guard let state = loadSession() else {
            hasActiveSession = false
            activeSessionInfo = nil
            return
        }

        let cardsRemaining = state.entryIDs.count - state.currentIndex
        let accuracy = state.cardsReviewed > 0
            ? Double(state.correctCount) / Double(state.cardsReviewed)
            : 0

        hasActiveSession = cardsRemaining > 0
        activeSessionInfo = SessionInfo(
            totalCards: state.entryIDs.count,
            cardsRemaining: cardsRemaining,
            cardsReviewed: state.cardsReviewed,
            accuracy: accuracy,
            savedAt: state.savedAt
        )
    }
}
