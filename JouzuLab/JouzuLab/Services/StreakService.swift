import Foundation

// MARK: - Reviewed Card (for tracking today's session)

struct ReviewedCard: Codable, Identifiable {
    let id: UUID
    let entryId: String
    let grade: Int // SRSGrade raw value (0-3)
    let reviewedAt: Date

    init(entryId: String, grade: Int) {
        self.id = UUID()
        self.entryId = entryId
        self.grade = grade
        self.reviewedAt = Date()
    }

    var gradeLabel: String {
        switch grade {
        case 0: return "Again"
        case 1: return "Hard"
        case 2: return "Good"
        case 3: return "Easy"
        default: return "Unknown"
        }
    }
}

// MARK: - Study Stats

struct StudyStats: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalStudyDays: Int = 0
    var totalCardsReviewed: Int = 0
    var lastStudyDate: Date?
    var studyHistory: [String: DailyStats] = [:] // Key: "yyyy-MM-dd"

    struct DailyStats: Codable {
        var cardsReviewed: Int = 0
        var correctCount: Int = 0
        var studyTime: TimeInterval = 0 // seconds
        var reviewedCards: [ReviewedCard] = [] // Individual card reviews
    }
}

// MARK: - Streak Service

class StreakService: ObservableObject {
    static let shared = StreakService()

    @Published private(set) var stats: StudyStats

    private let userDefaultsKey = "studyStats"
    private let calendar = Calendar.current

    private init() {
        stats = StreakService.loadStats()
        checkAndUpdateStreak()
    }

    // MARK: - Public Methods

    /// Record a completed study session
    func recordStudySession(cardsReviewed: Int, correctCount: Int, duration: TimeInterval) {
        let today = dateKey(for: Date())

        // Update or create today's stats
        var dailyStats = stats.studyHistory[today] ?? StudyStats.DailyStats()
        dailyStats.cardsReviewed += cardsReviewed
        dailyStats.correctCount += correctCount
        dailyStats.studyTime += duration
        stats.studyHistory[today] = dailyStats

        // Update totals
        stats.totalCardsReviewed += cardsReviewed

        // Update streak
        updateStreak(studyDate: Date())

        saveStats()
    }

    /// Check if user has studied today
    var hasStudiedToday: Bool {
        let today = dateKey(for: Date())
        return stats.studyHistory[today] != nil
    }

    /// Get today's stats
    var todayStats: StudyStats.DailyStats? {
        let today = dateKey(for: Date())
        return stats.studyHistory[today]
    }

    /// Get stats for a specific date
    func statsFor(date: Date) -> StudyStats.DailyStats? {
        let key = dateKey(for: date)
        return stats.studyHistory[key]
    }

    /// Get the last 7 days of study activity (for weekly view)
    func weeklyActivity() -> [(date: Date, stats: StudyStats.DailyStats?)] {
        var result: [(Date, StudyStats.DailyStats?)] = []
        let today = calendar.startOfDay(for: Date())

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let key = dateKey(for: date)
                result.append((date, stats.studyHistory[key]))
            }
        }

        return result
    }

    /// Calculate accuracy for today
    var todayAccuracy: Double? {
        guard let today = todayStats, today.cardsReviewed > 0 else { return nil }
        return Double(today.correctCount) / Double(today.cardsReviewed)
    }

    // MARK: - Card Review Tracking

    /// Record an individual card review
    func recordCardReview(entryId: String, grade: Int) {
        let today = dateKey(for: Date())
        var dailyStats = stats.studyHistory[today] ?? StudyStats.DailyStats()

        let reviewedCard = ReviewedCard(entryId: entryId, grade: grade)
        dailyStats.reviewedCards.append(reviewedCard)
        stats.studyHistory[today] = dailyStats

        saveStats()
    }

    /// Get today's reviewed cards
    var todayReviewedCards: [ReviewedCard] {
        let today = dateKey(for: Date())
        return stats.studyHistory[today]?.reviewedCards ?? []
    }

    /// Get unique entry IDs reviewed today (for filtering)
    var todayReviewedEntryIds: Set<String> {
        Set(todayReviewedCards.map { $0.entryId })
    }

    /// Get cards reviewed today grouped by grade
    var todayCardsByGrade: [Int: [ReviewedCard]] {
        Dictionary(grouping: todayReviewedCards, by: { $0.grade })
    }

    /// Get cards that need more practice (graded Again or Hard)
    var todayMistakes: [ReviewedCard] {
        todayReviewedCards.filter { $0.grade <= 1 }
    }

    /// Get unique entry IDs that were mistakes today
    var todayMistakeEntryIds: Set<String> {
        Set(todayMistakes.map { $0.entryId })
    }

    /// Clear today's reviewed cards (for testing/reset)
    func clearTodayReviewedCards() {
        let today = dateKey(for: Date())
        if var dailyStats = stats.studyHistory[today] {
            dailyStats.reviewedCards = []
            stats.studyHistory[today] = dailyStats
            saveStats()
        }
    }

    // MARK: - Private Methods

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func checkAndUpdateStreak() {
        guard let lastStudy = stats.lastStudyDate else {
            // No previous study, streak is 0
            stats.currentStreak = 0
            return
        }

        let today = calendar.startOfDay(for: Date())
        let lastStudyDay = calendar.startOfDay(for: lastStudy)

        let daysDifference = calendar.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0

        if daysDifference > 1 {
            // Streak broken - more than 1 day gap
            stats.currentStreak = 0
            saveStats()
        }
        // If daysDifference is 0 (same day) or 1 (yesterday), streak is maintained
    }

    private func updateStreak(studyDate: Date) {
        let studyDay = calendar.startOfDay(for: studyDate)

        if let lastStudy = stats.lastStudyDate {
            let lastStudyDay = calendar.startOfDay(for: lastStudy)
            let daysDifference = calendar.dateComponents([.day], from: lastStudyDay, to: studyDay).day ?? 0

            if daysDifference == 0 {
                // Same day, streak unchanged
            } else if daysDifference == 1 {
                // Consecutive day, increment streak
                stats.currentStreak += 1
                stats.totalStudyDays += 1
            } else {
                // Gap in study, reset streak to 1
                stats.currentStreak = 1
                stats.totalStudyDays += 1
            }
        } else {
            // First time studying
            stats.currentStreak = 1
            stats.totalStudyDays = 1
        }

        // Update longest streak if needed
        if stats.currentStreak > stats.longestStreak {
            stats.longestStreak = stats.currentStreak
        }

        stats.lastStudyDate = studyDate
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
        objectWillChange.send()
    }

    private static func loadStats() -> StudyStats {
        guard let data = UserDefaults.standard.data(forKey: "studyStats"),
              let stats = try? JSONDecoder().decode(StudyStats.self, from: data) else {
            return StudyStats()
        }
        return stats
    }

    // MARK: - Debug/Reset

    func resetAllStats() {
        stats = StudyStats()
        saveStats()
    }
}
