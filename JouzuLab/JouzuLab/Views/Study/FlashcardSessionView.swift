import SwiftUI
import SwiftData

struct FlashcardSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialQueue: [Entry]
    let onSessionComplete: (SessionStats) -> Void

    @State private var cardQueue: [Entry]
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var sessionStats: SessionStats

    @StateObject private var audioService = AudioService.shared

    private let srsService = SRSService.shared

    init(initialQueue: [Entry], onSessionComplete: @escaping (SessionStats) -> Void) {
        self.initialQueue = initialQueue
        self.onSessionComplete = onSessionComplete
        _cardQueue = State(initialValue: initialQueue)
        _sessionStats = State(initialValue: SessionStats())
    }

    private var currentEntry: Entry? {
        guard currentIndex < cardQueue.count else { return nil }
        return cardQueue[currentIndex]
    }

    private var progress: Double {
        guard !cardQueue.isEmpty else { return 1.0 }
        return Double(sessionStats.cardsReviewed) / Double(cardQueue.count + sessionStats.cardsReviewed)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            SessionProgressHeader(
                cardsRemaining: cardQueue.count - currentIndex,
                totalReviewed: sessionStats.cardsReviewed,
                progress: progress,
                onClose: { dismiss() }
            )

            if let entry = currentEntry {
                // Flashcard
                FlashcardView(
                    entry: entry,
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
    let cardsRemaining: Int
    let totalReviewed: Int
    let progress: Double
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
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

                Text("\(cardsRemaining) remaining")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )

                Spacer()

                Text("\(totalReviewed) done")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .frame(width: 80, alignment: .trailing)
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

    return FlashcardSessionView(initialQueue: [entry1, entry2]) { stats in
        print("Session complete: \(stats.cardsReviewed) cards")
    }
    .modelContainer(for: Entry.self, inMemory: true)
}
