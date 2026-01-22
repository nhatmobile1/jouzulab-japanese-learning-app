import SwiftUI
import SwiftData

// MARK: - Session Data for Item-based Presentation

struct FlashcardSessionData: Identifiable {
    let id = UUID()
    let entries: [Entry]
    let resumeState: PersistedSessionState?
}

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @State private var showSideMenu = false
    @State private var showSessionConfig = false
    @State private var activeSession: FlashcardSessionData? = nil  // Changed to item-based
    @State private var showSessionSummary = false
    @State private var lastSessionStats: SessionStats?
    @State private var isResumingSession = false
    @State private var lastSessionEntryIds: [String] = []  // Track entries from last session

    @StateObject private var streakService = StreakService.shared
    @StateObject private var sessionManager = StudySessionManager.shared
    private let srsService = SRSService.shared

    /// Entries that are complete (have Japanese, reading, and English)
    private var completeEntries: [Entry] {
        allEntries.filter { $0.isComplete }
    }

    private var reviewDueCount: Int {
        let now = Date()
        return completeEntries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count
    }

    private var newCount: Int {
        // A card is "new" if it has never been reviewed (reviewCount == 0)
        // Only count complete entries (have reading AND English)
        completeEntries.filter { $0.reviewCount == 0 }.count
    }

    private var hasCardsToStudy: Bool {
        reviewDueCount > 0 || newCount > 0
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App Header
                AppHeader(
                    title: "Study",
                    subtitle: "Flashcard practice",
                    onMenuTap: {
                        withAnimation(AppTheme.Animation.standard) {
                            showSideMenu = true
                        }
                    },
                    onProfileTap: {
                        // TODO: Navigate to profile
                    }
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        Spacer()
                            .frame(height: AppTheme.Spacing.md)

                        // Icon
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                )
                            )
                            .padding(AppTheme.Spacing.lg)
                            .background(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                ).opacity(0.1)
                            )
                            .clipShape(Circle())

                        // Title
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Flashcard Study")
                                .font(AppTheme.Typography.title)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )

                            Text("Practice with spaced repetition")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                        }

                        // Stats preview
                        HStack(spacing: AppTheme.Spacing.lg) {
                            VStack {
                                Text("\(newCount.formatted())")
                                    .font(AppTheme.Typography.statMedium)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.primaryLight,
                                            dark: AppTheme.Colors.Fallback.primaryDark
                                        )
                                    )
                                Text("New")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                                        )
                                    )
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                                    ).opacity(0.3)
                                )
                                .frame(width: 1, height: 40)

                            VStack {
                                Text("\(reviewDueCount)")
                                    .font(AppTheme.Typography.statMedium)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.accentLight,
                                            dark: AppTheme.Colors.Fallback.accentDark
                                        )
                                    )
                                Text("Due")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                                        )
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        .padding(.horizontal, AppTheme.Spacing.md)

                        // Streak Widget
                        StreakWidget(streakService: streakService)
                            .padding(.horizontal, AppTheme.Spacing.md)

                        // Today's Session Card (if any cards reviewed today)
                        if !streakService.todayReviewedCards.isEmpty {
                            TodaySessionCard(
                                streakService: streakService,
                                onReviewMistakes: {
                                    startReviewSession(entryIds: Array(streakService.todayMistakeEntryIds))
                                },
                                onReviewAll: {
                                    startReviewSession(entryIds: Array(streakService.todayReviewedEntryIds))
                                }
                            )
                            .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        // Session Buttons
                        if sessionManager.hasActiveSession, let info = sessionManager.activeSessionInfo {
                            // Active session card
                            VStack(spacing: AppTheme.Spacing.md) {
                                VStack(spacing: AppTheme.Spacing.xs) {
                                    Text("Session in Progress")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundStyle(
                                            Color.adaptive(
                                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                                            )
                                        )

                                    HStack(spacing: AppTheme.Spacing.lg) {
                                        VStack {
                                            Text("\(info.cardsRemaining)")
                                                .font(AppTheme.Typography.statSmall)
                                                .foregroundStyle(
                                                    Color.adaptive(
                                                        light: AppTheme.Colors.Fallback.primaryLight,
                                                        dark: AppTheme.Colors.Fallback.primaryDark
                                                    )
                                                )
                                            Text("Remaining")
                                                .font(AppTheme.Typography.caption)
                                                .foregroundStyle(
                                                    Color.adaptive(
                                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                                    )
                                                )
                                        }

                                        VStack {
                                            Text("\(info.cardsReviewed)")
                                                .font(AppTheme.Typography.statSmall)
                                                .foregroundStyle(
                                                    Color.adaptive(
                                                        light: AppTheme.Colors.Fallback.accentLight,
                                                        dark: AppTheme.Colors.Fallback.accentDark
                                                    )
                                                )
                                            Text("Reviewed")
                                                .font(AppTheme.Typography.caption)
                                                .foregroundStyle(
                                                    Color.adaptive(
                                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                                    )
                                                )
                                        }

                                        if info.cardsReviewed > 0 {
                                            VStack {
                                                Text("\(Int(info.accuracy * 100))%")
                                                    .font(AppTheme.Typography.statSmall)
                                                    .foregroundStyle(AppTheme.Colors.Fallback.success)
                                                Text("Accuracy")
                                                    .font(AppTheme.Typography.caption)
                                                    .foregroundStyle(
                                                        Color.adaptive(
                                                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                                                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                                                        )
                                                    )
                                            }
                                        }
                                    }
                                }
                                .padding(AppTheme.Spacing.md)

                                // Continue button
                                Button {
                                    resumeSession()
                                } label: {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Continue Session")
                                    }
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.md)
                                    .background(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.primaryLight,
                                            dark: AppTheme.Colors.Fallback.primaryDark
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                                }

                                // Start new session button
                                Button {
                                    sessionManager.clearSession()
                                    showSessionConfig = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Start New Session")
                                    }
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.primaryLight,
                                            dark: AppTheme.Colors.Fallback.primaryDark
                                        )
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.sm)
                                    .background(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.primaryLight,
                                            dark: AppTheme.Colors.Fallback.primaryDark
                                        ).opacity(0.1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                            .cardStyle()
                            .padding(.horizontal, AppTheme.Spacing.md)
                        } else {
                            // Start Study Button (no active session)
                            Button {
                                showSessionConfig = true
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Study Session")
                                }
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .disabled(!hasCardsToStudy)
                            .opacity(hasCardsToStudy ? 1 : 0.5)
                        }

                        // Features list
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            FeatureRow(
                                icon: "rectangle.portrait.on.rectangle.portrait",
                                title: "Flip Cards",
                                description: "Tap to reveal readings and translations"
                            )

                            FeatureRow(
                                icon: "speaker.wave.2.fill",
                                title: "Audio Pronunciation",
                                description: "Listen to native Japanese pronunciation"
                            )

                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "Spaced Repetition",
                                description: "SM-2 algorithm schedules optimal reviews"
                            )

                            FeatureRow(
                                icon: "hand.thumbsup.fill",
                                title: "Self-Grading",
                                description: "Rate as Easy, Good, Hard, or Again"
                            )
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        .padding(.horizontal, AppTheme.Spacing.md)

                        Spacer()
                    }
                }
            }
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )

            // Side Menu Overlay
            SideMenu(isPresented: $showSideMenu) { item in
                print("Navigate to: \(item.rawValue)")
            }
        }
        .sheet(isPresented: $showSessionConfig) {
            SessionConfigView { entries, newCardLimit in
                startSession(entries: entries, newCardLimit: newCardLimit)
            }
        }
        .fullScreenCover(item: $activeSession) { sessionData in
            FlashcardSessionView(
                initialQueue: sessionData.entries,
                resumeState: sessionData.resumeState,
                onSessionComplete: { stats in
                    lastSessionStats = stats
                    // Store the entry IDs from this session for review options
                    lastSessionEntryIds = sessionData.entries.map { $0.id }
                    sessionManager.clearSession()
                    activeSession = nil
                    showSessionSummary = true
                }
            )
        }
        .sheet(isPresented: $showSessionSummary) {
            if let stats = lastSessionStats {
                SessionSummaryView(
                    stats: stats,
                    mistakeCount: streakService.todayMistakes.count,
                    onReviewMistakes: streakService.todayMistakes.isEmpty ? nil : {
                        showSessionSummary = false
                        startReviewSession(entryIds: Array(streakService.todayMistakeEntryIds))
                    },
                    onReviewAll: lastSessionEntryIds.isEmpty ? nil : {
                        showSessionSummary = false
                        startReviewSession(entryIds: lastSessionEntryIds)
                    },
                    onAddMoreCards: hasCardsToStudy ? {
                        showSessionSummary = false
                        showSessionConfig = true
                    } : nil,
                    onFinish: {
                        showSessionSummary = false
                    }
                )
            }
        }
    }

    // MARK: - Session Management

    private func startSession(entries: [Entry], newCardLimit: Int) {
        // Safety check: don't start session with no entries
        guard !entries.isEmpty else {
            print("[StudyView] startSession called with empty entries array - aborting")
            showSessionConfig = false
            return
        }

        // Build study queue from the entries passed by SessionConfigView
        // (already filtered by deck, JLPT, and completeness)
        let queue = srsService.buildStudyQueue(
            from: entries,
            newCardLimit: newCardLimit
        )

        print("[StudyView] Built session queue: \(queue.count) cards from \(entries.count) entries")

        showSessionConfig = false

        // Only show flashcard session if we have cards to study
        // Use a small delay to ensure the sheet dismissal animation completes
        if !queue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Create session data with the queue - this ensures entries are captured NOW
                activeSession = FlashcardSessionData(entries: queue, resumeState: nil)
            }
        } else {
            print("[StudyView] Session queue is empty - not showing flashcard session")
        }
    }

    private func resumeSession() {
        guard let state = sessionManager.loadSession() else { return }

        // Restore entries from saved IDs
        let restoredEntries = sessionManager.restoreEntries(from: state, allEntries: allEntries)

        if !restoredEntries.isEmpty {
            activeSession = FlashcardSessionData(entries: restoredEntries, resumeState: state)
        }
    }

    /// Start a review session with specific entry IDs (for Review Mistakes or Review All)
    private func startReviewSession(entryIds: [String]) {
        // Find entries matching the IDs
        let entryIdSet = Set(entryIds)
        let entriesToReview = allEntries.filter { entryIdSet.contains($0.id) }

        guard !entriesToReview.isEmpty else {
            print("[StudyView] startReviewSession: No matching entries found")
            return
        }

        print("[StudyView] Starting review session with \(entriesToReview.count) entries")

        // Use a small delay to ensure sheet dismissal animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeSession = FlashcardSessionData(entries: entriesToReview, resumeState: nil)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }

            Spacer()
        }
    }
}

// MARK: - Today's Session Card

struct TodaySessionCard: View {
    @ObservedObject var streakService: StreakService
    let onReviewMistakes: () -> Void
    let onReviewAll: () -> Void

    private var reviewedCount: Int {
        streakService.todayReviewedCards.count
    }

    private var mistakeCount: Int {
        streakService.todayMistakes.count
    }

    private var accuracy: Double {
        guard reviewedCount > 0 else { return 0 }
        return Double(reviewedCount - mistakeCount) / Double(reviewedCount)
    }

    private var gradeBreakdown: [Int: Int] {
        var breakdown: [Int: Int] = [0: 0, 1: 0, 2: 0, 3: 0]
        for card in streakService.todayReviewedCards {
            breakdown[card.grade, default: 0] += 1
        }
        return breakdown
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Text("Today's Progress")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                Spacer()

                Text("\(reviewedCount) cards")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }

            // Grade breakdown
            HStack(spacing: AppTheme.Spacing.sm) {
                GradeChip(label: "Again", count: gradeBreakdown[0] ?? 0, color: AppTheme.Colors.Fallback.error)
                GradeChip(label: "Hard", count: gradeBreakdown[1] ?? 0, color: AppTheme.Colors.Fallback.warning)
                GradeChip(label: "Good", count: gradeBreakdown[2] ?? 0, color: AppTheme.Colors.Fallback.success)
                GradeChip(label: "Easy", count: gradeBreakdown[3] ?? 0, color: Color.adaptive(
                    light: AppTheme.Colors.Fallback.primaryLight,
                    dark: AppTheme.Colors.Fallback.primaryDark
                ))
            }

            // Accuracy bar
            VStack(spacing: AppTheme.Spacing.xxs) {
                HStack {
                    Text("Accuracy")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                    Spacer()
                    Text("\(Int(accuracy * 100))%")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accuracyColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                    dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                                )
                            )
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accuracyColor)
                            .frame(width: geometry.size.width * accuracy, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Action buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                if mistakeCount > 0 {
                    Button {
                        onReviewMistakes()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xxs) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Mistakes (\(mistakeCount))")
                                .font(AppTheme.Typography.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.Fallback.warning)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                }

                Button {
                    onReviewAll()
                } label: {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 12))
                        Text("Review All")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        ).opacity(0.15)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
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

struct GradeChip: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(AppTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                    )
                )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StudyView()
        .modelContainer(for: Entry.self, inMemory: true)
}
