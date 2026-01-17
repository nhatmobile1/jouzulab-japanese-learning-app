import Foundation
import SwiftData

// MARK: - SRS Grade

enum SRSGrade: Int, CaseIterable {
    case again = 0  // Complete blackout
    case hard = 1   // Incorrect but remembered after seeing answer
    case good = 2   // Correct with effort
    case easy = 3   // Perfect recall

    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var colorName: String {
        switch self {
        case .again: return "error"
        case .hard: return "warning"
        case .good: return "success"
        case .easy: return "primary"
        }
    }
}

// MARK: - SRS Service (SM-2 Algorithm)

class SRSService {
    static let shared = SRSService()

    private init() {}

    // SM-2 constants
    private let minEaseFactor: Double = 1.3
    private let defaultEaseFactor: Double = 2.5

    // MARK: - Calculate Next Review

    /// Process a review and update the entry's SRS fields
    func processReview(entry: Entry, grade: SRSGrade) {
        let now = Date()
        entry.lastReviewed = now
        entry.reviewCount += 1

        if grade.rawValue >= SRSGrade.good.rawValue {
            entry.correctCount += 1
        }

        // Calculate new interval and ease factor
        let (newInterval, newEaseFactor) = calculateNextInterval(
            currentEaseFactor: entry.easeFactor,
            currentInterval: currentIntervalDays(for: entry),
            grade: grade,
            masteryLevel: entry.masteryLevel
        )

        // Update ease factor
        entry.easeFactor = newEaseFactor

        // Update next review date
        entry.nextReview = Calendar.current.date(byAdding: .day, value: newInterval, to: now)

        // Update mastery level
        entry.masteryLevel = calculateNewMasteryLevel(
            current: entry.masteryLevel,
            grade: grade,
            reviewCount: entry.reviewCount,
            correctCount: entry.correctCount
        )
    }

    // MARK: - Preview Interval

    /// Preview what the next interval would be for a given grade
    func previewInterval(entry: Entry, grade: SRSGrade) -> Int {
        let (interval, _) = calculateNextInterval(
            currentEaseFactor: entry.easeFactor,
            currentInterval: currentIntervalDays(for: entry),
            grade: grade,
            masteryLevel: entry.masteryLevel
        )
        return interval
    }

    /// Format interval for display (e.g., "1 day", "6 days", "2 weeks")
    func formatInterval(_ days: Int) -> String {
        if days == 0 {
            return "< 1 day"
        } else if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else if days < 14 {
            return "1 week"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) weeks"
        } else if days < 60 {
            return "1 month"
        } else {
            let months = days / 30
            return "\(months) months"
        }
    }

    // MARK: - Private Helpers

    private func currentIntervalDays(for entry: Entry) -> Int {
        guard let lastReview = entry.lastReviewed,
              let nextReview = entry.nextReview else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: lastReview, to: nextReview).day ?? 0
        return max(0, days)
    }

    private func calculateNextInterval(
        currentEaseFactor: Double,
        currentInterval: Int,
        grade: SRSGrade,
        masteryLevel: MasteryLevel
    ) -> (interval: Int, easeFactor: Double) {
        var newEaseFactor = currentEaseFactor
        var newInterval: Int

        switch grade {
        case .again:
            // Reset to learning phase
            newInterval = 0  // Review again in same session or next day
            newEaseFactor = max(minEaseFactor, currentEaseFactor - 0.2)

        case .hard:
            // Slightly increase interval, decrease ease
            if masteryLevel == .new || masteryLevel == .learning {
                newInterval = 1
            } else {
                newInterval = max(1, Int(Double(currentInterval) * 1.2))
            }
            newEaseFactor = max(minEaseFactor, currentEaseFactor - 0.15)

        case .good:
            // Standard SM-2 progression
            if masteryLevel == .new {
                newInterval = 1
            } else if masteryLevel == .learning {
                newInterval = 6
            } else {
                newInterval = max(1, Int(Double(currentInterval) * currentEaseFactor))
            }
            // Ease factor stays the same for "good"

        case .easy:
            // Accelerated progression, increase ease
            if masteryLevel == .new {
                newInterval = 4
            } else if masteryLevel == .learning {
                newInterval = 10
            } else {
                newInterval = max(1, Int(Double(currentInterval) * currentEaseFactor * 1.3))
            }
            newEaseFactor = currentEaseFactor + 0.15
        }

        return (newInterval, newEaseFactor)
    }

    private func calculateNewMasteryLevel(
        current: MasteryLevel,
        grade: SRSGrade,
        reviewCount: Int,
        correctCount: Int
    ) -> MasteryLevel {
        // Calculate accuracy
        let accuracy = reviewCount > 0 ? Double(correctCount) / Double(reviewCount) : 0

        switch grade {
        case .again:
            // Drop back to learning if reviewing/mastered
            if current == .mastered || current == .reviewing {
                return .learning
            }
            return current

        case .hard:
            // Stay at current level or move to learning
            if current == .new {
                return .learning
            }
            return current

        case .good, .easy:
            switch current {
            case .new:
                return .learning
            case .learning:
                // Need at least 3 reviews with good accuracy to move to reviewing
                if reviewCount >= 3 && accuracy >= 0.7 {
                    return .reviewing
                }
                return .learning
            case .reviewing:
                // Need sustained good performance to master
                if reviewCount >= 10 && accuracy >= 0.85 {
                    return .mastered
                }
                return .reviewing
            case .mastered:
                return .mastered
            }
        }
    }

    // MARK: - Queue Management

    /// Get entries due for review
    func getDueEntries(from entries: [Entry], limit: Int? = nil) -> [Entry] {
        let now = Date()
        var dueEntries = entries.filter { entry in
            guard let nextReview = entry.nextReview else {
                // New cards are always available
                return entry.masteryLevel == .new
            }
            return nextReview <= now
        }

        // Sort: due cards first (oldest first), then new cards
        dueEntries.sort { entry1, entry2 in
            let date1 = entry1.nextReview ?? Date.distantFuture
            let date2 = entry2.nextReview ?? Date.distantFuture
            return date1 < date2
        }

        if let limit = limit {
            return Array(dueEntries.prefix(limit))
        }
        return dueEntries
    }

    /// Get new entries that haven't been studied yet
    func getNewEntries(from entries: [Entry], limit: Int? = nil) -> [Entry] {
        var newEntries = entries.filter { $0.masteryLevel == .new && $0.reviewCount == 0 }

        // Shuffle for variety
        newEntries.shuffle()

        if let limit = limit {
            return Array(newEntries.prefix(limit))
        }
        return newEntries
    }

    /// Build a study queue combining due reviews and new cards
    func buildStudyQueue(
        from entries: [Entry],
        newCardLimit: Int,
        reviewLimit: Int? = nil
    ) -> [Entry] {
        let dueEntries = getDueEntries(from: entries, limit: reviewLimit)
        let newEntries = getNewEntries(from: entries, limit: newCardLimit)

        // Interleave: reviews first, then new cards
        var queue = dueEntries
        queue.append(contentsOf: newEntries)

        return queue
    }
}
