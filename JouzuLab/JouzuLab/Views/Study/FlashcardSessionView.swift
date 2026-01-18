import SwiftUI
import SwiftData

struct FlashcardSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialQueue: [Entry]
    let resumeState: PersistedSessionState?
    let onSessionComplete: (SessionStats) -> Void

    @State private var cardQueue: [Entry]
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var sessionStats: SessionStats
    @State private var sessionStartTime: Date = Date()
    @State private var showEndSessionAlert: Bool = false
    @State private var showSessionMenu: Bool = false
    @State private var deckNameCache: [String: String] = [:]

    @StateObject private var audioService = AudioService.shared
    @Query private var decks: [Deck]

    private let srsService = SRSService.shared
    private let streakService = StreakService.shared
    private let sessionManager = StudySessionManager.shared

    init(
        initialQueue: [Entry],
        resumeState: PersistedSessionState? = nil,
        onSessionComplete: @escaping (SessionStats) -> Void
    ) {
        self.initialQueue = initialQueue
        self.resumeState = resumeState
        self.onSessionComplete = onSessionComplete
        _cardQueue = State(initialValue: initialQueue)

        // Restore state if resuming
        if let state = resumeState {
            _currentIndex = State(initialValue: state.currentIndex)
            _sessionStats = State(initialValue: state.toSessionStats())
            _sessionStartTime = State(initialValue: state.sessionStartTime)
        } else {
            _sessionStats = State(initialValue: SessionStats())
        }
    }

    private var currentEntry: Entry? {
        guard currentIndex < cardQueue.count else { return nil }
        return cardQueue[currentIndex]
    }

    private var progress: Double {
        guard !cardQueue.isEmpty else { return 1.0 }
        return Double(sessionStats.cardsReviewed) / Double(cardQueue.count + sessionStats.cardsReviewed)
    }

    private var cardsRemaining: Int {
        cardQueue.count - currentIndex
    }

    private var currentAccuracy: Double {
        sessionStats.accuracy
    }

    /// Get the deck name for an entry
    private func deckName(for entry: Entry) -> String? {
        guard let deckId = entry.deckId else { return nil }

        // Check cache first
        if let cached = deckNameCache[deckId] {
            return cached
        }

        // Look up deck
        if let deck = decks.first(where: { $0.id == deckId }) {
            // We can't mutate state here directly, so return the name
            return deck.name
        }

        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Progress header
            SessionProgressHeader(
                currentCardNumber: sessionStats.cardsReviewed + 1,
                totalCards: initialQueue.count,
                cardsRemaining: cardsRemaining,
                totalReviewed: sessionStats.cardsReviewed,
                accuracy: currentAccuracy,
                progress: progress,
                onClose: {
                    if sessionStats.cardsReviewed > 0 {
                        showEndSessionAlert = true
                    } else {
                        dismiss()
                    }
                },
                onMenuTap: { showSessionMenu = true }
            )

            if initialQueue.isEmpty {
                // No cards to study - should not normally happen
                VStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "rectangle.stack.badge.minus")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )

                    Text("No Cards Available")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )

                    Text("There are no cards ready for study. Try adjusting your filters or add more entries.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)

                    Button("Go Back") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let entry = currentEntry {
                // Flashcard
                FlashcardView(
                    entry: entry,
                    deckName: deckName(for: entry),
                    isFlipped: $isFlipped,
                    audioService: audioService
                )
                .padding(AppTheme.Spacing.lg)
                .id(entry.id) // Force view refresh on card change

                Spacer()

                // Grade buttons (only visible when flipped)
                if isFlipped {
                    GradeButtonsView(entry: entry) { grade in
                        handleGrade(grade, for: entry)
                    }
                    .padding(.bottom, AppTheme.Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                // Session complete
                VStack(spacing: AppTheme.Spacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.Colors.Fallback.success)

                    Text("Session Complete!")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )

                    Button("View Summary") {
                        recordSessionToStreak()
                        onSessionComplete(sessionStats)
                    }
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Speed control
            if currentEntry != nil {
                SpeedControlBar(audioService: audioService)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)
            }
        }
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
        .animation(AppTheme.Animation.standard, value: isFlipped)
        .alert("Pause Session?", isPresented: $showEndSessionAlert) {
            Button("Continue Studying", role: .cancel) { }
            Button("Pause & Save Progress") {
                saveSessionAndExit()
            }
            Button("End Session") {
                recordSessionToStreak()
                onSessionComplete(sessionStats)
            }
        } message: {
            Text("You've reviewed \(sessionStats.cardsReviewed) cards with \(cardsRemaining) remaining.")
        }
        .confirmationDialog("Session Options", isPresented: $showSessionMenu, titleVisibility: .visible) {
            Button("Restart Session") {
                restartSession()
            }
            Button("Pause & Exit") {
                saveSessionAndExit()
            }
            Button("End & Complete Session") {
                recordSessionToStreak()
                onSessionComplete(sessionStats)
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Session Control

    private func restartSession() {
        cardQueue = initialQueue
        currentIndex = 0
        sessionStats = SessionStats()
        sessionStartTime = Date()
        isFlipped = false
        sessionManager.clearSession()
    }

    private func saveSessionAndExit() {
        // Save current session state
        let entryIDs = cardQueue.map { $0.id }
        sessionManager.saveSession(
            entryIDs: entryIDs,
            currentIndex: currentIndex,
            stats: sessionStats,
            sessionStartTime: sessionStartTime
        )

        // Record partial progress to streak
        if sessionStats.cardsReviewed > 0 {
            let duration = Date().timeIntervalSince(sessionStartTime)
            streakService.recordStudySession(
                cardsReviewed: sessionStats.cardsReviewed,
                correctCount: sessionStats.correctCount,
                duration: duration
            )
        }

        dismiss()
    }

    // MARK: - Grade Handling

    private func handleGrade(_ grade: SRSGrade, for entry: Entry) {
        // Update stats
        sessionStats.cardsReviewed += 1
        sessionStats.gradeDistribution[grade, default: 0] += 1

        if grade.rawValue >= SRSGrade.good.rawValue {
            sessionStats.correctCount += 1
        }

        // Process review with SRS
        srsService.processReview(entry: entry, grade: grade)

        // If "Again", add card back to end of queue
        if grade == .again {
            cardQueue.append(entry)
        }

        // Move to next card
        withAnimation(AppTheme.Animation.standard) {
            isFlipped = false
        }

        // Small delay before showing next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
        }
    }

    // MARK: - Streak Recording

    private func recordSessionToStreak() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        streakService.recordStudySession(
            cardsReviewed: sessionStats.cardsReviewed,
            correctCount: sessionStats.correctCount,
            duration: duration
        )
    }
}

// MARK: - Session Stats

struct SessionStats {
    var cardsReviewed: Int = 0
    var correctCount: Int = 0
    var gradeDistribution: [SRSGrade: Int] = [:]

    var accuracy: Double {
        guard cardsReviewed > 0 else { return 0 }
        return Double(correctCount) / Double(cardsReviewed)
    }
}

// MARK: - Progress Header

struct SessionProgressHeader: View {
    let currentCardNumber: Int
    let totalCards: Int
    let cardsRemaining: Int
    let totalReviewed: Int
    let accuracy: Double
    let progress: Double
    let onClose: () -> Void
    let onMenuTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Top row: close button, card counter, menu button
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                        .frame(width: 32, height: 32)
                }

                Spacer()

                // Card counter
                Text("Card \(min(currentCardNumber, totalCards)) of \(totalCards)")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Spacer()

                Button(action: onMenuTap) {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                        .frame(width: 32, height: 32)
                }
            }

            // Stats row
            HStack(spacing: AppTheme.Spacing.lg) {
                // Remaining
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 12))
                    Text("\(cardsRemaining) left")
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )

                // Reviewed
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12))
                    Text("\(totalReviewed) done")
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )

                // Accuracy (only show if reviewed > 0)
                if totalReviewed > 0 {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "target")
                            .font(.system(size: 12))
                        Text("\(Int(accuracy * 100))%")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundStyle(accuracyColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                            )
                        )
                        .frame(height: 4)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.primaryLight,
                                dark: AppTheme.Colors.Fallback.primaryDark
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .clipShape(Capsule())
                        .animation(AppTheme.Animation.standard, value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
    }

    private var accuracyColor: Color {
        if accuracy >= 0.8 {
            return AppTheme.Colors.Fallback.success
        } else if accuracy >= 0.6 {
            return AppTheme.Colors.Fallback.warning
        } else {
            return AppTheme.Colors.Fallback.error
        }
    }
}

// MARK: - Speed Control Bar

struct SpeedControlBar: View {
    @ObservedObject var audioService: AudioService

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Speed:")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )

            ForEach(SpeechSpeed.allCases) { speed in
                Button {
                    audioService.setSpeed(speed)
                } label: {
                    Image(systemName: speed.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            audioService.currentSpeed == speed
                                ? Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                )
                                : Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                                )
                        )
                        .frame(width: 32, height: 32)
                        .background(
                            audioService.currentSpeed == speed
                                ? Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                ).opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(Circle())
                }
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let entry1 = Entry(id: "1", japanese: "漢字", reading: "かんじ", english: "Chinese characters")
    let entry2 = Entry(id: "2", japanese: "勉強", reading: "べんきょう", english: "Study")

    return FlashcardSessionView(
        initialQueue: [entry1, entry2],
        onSessionComplete: { stats in
            print("Session complete: \(stats.cardsReviewed) cards")
        }
    )
    .modelContainer(for: Entry.self, inMemory: true)
}
