import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @State private var showSideMenu = false
    @State private var showSessionConfig = false
    @State private var showFlashcardSession = false
    @State private var showSessionSummary = false
    @State private var sessionQueue: [Entry] = []
    @State private var lastSessionStats: SessionStats?
    @State private var isResumingSession = false
    @State private var resumeSessionState: PersistedSessionState?

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
            SessionConfigView { newCardLimit, jlptFilter, deck in
                startSession(newCardLimit: newCardLimit, jlptFilter: jlptFilter, deck: deck)
            }
        }
        .fullScreenCover(isPresented: $showFlashcardSession) {
            FlashcardSessionView(
                initialQueue: sessionQueue,
                resumeState: resumeSessionState,
                onSessionComplete: { stats in
                    lastSessionStats = stats
                    sessionManager.clearSession()
                    showFlashcardSession = false
                    showSessionSummary = true
                }
            )
        }
        .sheet(isPresented: $showSessionSummary) {
            if let stats = lastSessionStats {
                SessionSummaryView(
                    stats: stats,
                    onContinue: hasCardsToStudy ? {
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

    private func startSession(newCardLimit: Int, jlptFilter: String?, deck: Deck?) {
        // Only include complete entries (have Japanese, reading, AND English)
        var entriesToStudy = allEntries.filter { $0.isComplete }

        // Apply deck filter if selected
        if let deck = deck {
            let deckEntryIDs = Set(deck.entryIDs)
            entriesToStudy = entriesToStudy.filter { deckEntryIDs.contains($0.id) }
        }

        // Apply JLPT filter if selected
        if let jlpt = jlptFilter {
            entriesToStudy = entriesToStudy.filter { $0.jlptLevel == jlpt }
        }

        // Build study queue
        sessionQueue = srsService.buildStudyQueue(
            from: entriesToStudy,
            newCardLimit: newCardLimit
        )

        // Clear any previous resume state (this is a new session)
        resumeSessionState = nil

        showSessionConfig = false

        // Only show flashcard session if we have cards to study
        // Use a small delay to ensure the sheet dismissal animation completes
        if !sessionQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showFlashcardSession = true
            }
        }
    }

    private func resumeSession() {
        guard let state = sessionManager.loadSession() else { return }

        // Restore entries from saved IDs
        sessionQueue = sessionManager.restoreEntries(from: state, allEntries: allEntries)
        resumeSessionState = state

        if !sessionQueue.isEmpty {
            showFlashcardSession = true
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

#Preview {
    StudyView()
        .modelContainer(for: Entry.self, inMemory: true)
}
