import SwiftUI

struct SessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let stats: SessionStats
    let onContinue: (() -> Void)?
    let onFinish: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Celebration icon
                    Image(systemName: celebrationIcon)
                        .font(.system(size: 72, weight: .medium))
                        .foregroundStyle(celebrationColor)
                        .padding(.top, AppTheme.Spacing.xl)

                    // Main message
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Text(celebrationMessage)
                            .font(AppTheme.Typography.title)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )

                        Text("You reviewed \(stats.cardsReviewed) cards")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                    }

                    // Stats card
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Accuracy
                        AccuracyRing(accuracy: stats.accuracy)

                        Divider()

                        // Grade breakdown
                        GradeBreakdownView(distribution: stats.gradeDistribution)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .cardStyle()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    Spacer(minLength: AppTheme.Spacing.xl)

                    // Action buttons
                    VStack(spacing: AppTheme.Spacing.sm) {
                        if let onContinue = onContinue {
                            Button {
                                onContinue()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Study More")
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
                        }

                        Button {
                            onFinish()
                        } label: {
                            Text("Done")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                        dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Session Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Computed Properties

    private var celebrationIcon: String {
        if stats.accuracy >= 0.9 {
            return "star.fill"
        } else if stats.accuracy >= 0.7 {
            return "hand.thumbsup.fill"
        } else {
            return "flame.fill"
        }
    }

    private var celebrationColor: Color {
        if stats.accuracy >= 0.9 {
            return Color(hex: "FFD700") // Gold
        } else if stats.accuracy >= 0.7 {
            return AppTheme.Colors.Fallback.success
        } else {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.accentLight,
                dark: AppTheme.Colors.Fallback.accentDark
            )
        }
    }

    private var celebrationMessage: String {
        if stats.accuracy >= 0.9 {
            return "Excellent!"
        } else if stats.accuracy >= 0.7 {
            return "Great Work!"
        } else if stats.accuracy >= 0.5 {
            return "Good Effort!"
        } else {
            return "Keep Practicing!"
        }
    }
}

// MARK: - Accuracy Ring

struct AccuracyRing: View {
    let accuracy: Double

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                            dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                        ),
                        lineWidth: 12
                    )
                    .frame(width: 100, height: 100)

                // Progress ring
                Circle()
                    .trim(from: 0, to: accuracy)
                    .stroke(
                        accuracyColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Percentage text
                Text("\(Int(accuracy * 100))%")
                    .font(AppTheme.Typography.statMedium)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

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

// MARK: - Grade Breakdown

struct GradeBreakdownView: View {
    let distribution: [SRSGrade: Int]

    private var total: Int {
        distribution.values.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("Grade Breakdown")
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )

            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(SRSGrade.allCases, id: \.rawValue) { grade in
                    GradeStatItem(
                        grade: grade,
                        count: distribution[grade] ?? 0,
                        total: total
                    )
                }
            }
        }
    }
}

struct GradeStatItem: View {
    let grade: SRSGrade
    let count: Int
    let total: Int

    private var gradeColor: Color {
        switch grade {
        case .again:
            return AppTheme.Colors.Fallback.error
        case .hard:
            return AppTheme.Colors.Fallback.warning
        case .good:
            return AppTheme.Colors.Fallback.success
        case .easy:
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.primaryLight,
                dark: AppTheme.Colors.Fallback.primaryDark
            )
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text("\(count)")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(gradeColor)

            Text(grade.displayName)
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
}

// MARK: - Preview

#Preview {
    let stats = SessionStats(
        cardsReviewed: 15,
        correctCount: 12,
        gradeDistribution: [
            .again: 2,
            .hard: 1,
            .good: 8,
            .easy: 4
        ]
    )

    return SessionSummaryView(
        stats: stats,
        onContinue: { print("Continue") },
        onFinish: { print("Finish") }
    )
}
