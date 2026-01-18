import SwiftUI

// MARK: - Streak Widget

struct StreakWidget: View {
    @ObservedObject var streakService: StreakService

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Text("Study Streak")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                Spacer()
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                // Current streak
                VStack(spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(streakColor)
                        Text("\(streakService.stats.currentStreak)")
                            .font(AppTheme.Typography.statLarge)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )
                    }
                    Text("Day Streak")
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

                // Best streak
                VStack(spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "FFD700"))
                        Text("\(streakService.stats.longestStreak)")
                            .font(AppTheme.Typography.statMedium)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textPrimaryLight,
                                    dark: AppTheme.Colors.Fallback.textPrimaryDark
                                )
                            )
                    }
                    Text("Best")
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

            // Weekly activity
            WeeklyActivityView(streakService: streakService)
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }

    private var streakColor: Color {
        let streak = streakService.stats.currentStreak
        if streak >= 30 {
            return Color(hex: "FFD700") // Gold
        } else if streak >= 7 {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.accentLight,
                dark: AppTheme.Colors.Fallback.accentDark
            )
        } else if streak > 0 {
            return AppTheme.Colors.Fallback.warning
        } else {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.textTertiaryLight,
                dark: AppTheme.Colors.Fallback.textTertiaryDark
            )
        }
    }
}

// MARK: - Weekly Activity View

struct WeeklyActivityView: View {
    @ObservedObject var streakService: StreakService

    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter
    }()

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("This Week")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                Spacer()

                if streakService.hasStudiedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Done today")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundStyle(AppTheme.Colors.Fallback.success)
                }
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(streakService.weeklyActivity(), id: \.date) { item in
                    DayActivityDot(
                        dayName: dayFormatter.string(from: item.date),
                        isToday: calendar.isDateInToday(item.date),
                        hasActivity: item.stats != nil,
                        cardsCount: item.stats?.cardsReviewed ?? 0
                    )
                }
            }
        }
    }
}

// MARK: - Day Activity Dot

struct DayActivityDot: View {
    let dayName: String
    let isToday: Bool
    let hasActivity: Bool
    let cardsCount: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Text(String(dayName.prefix(1)))
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    isToday
                        ? Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                        : Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                )

            Circle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .overlay {
                    if isToday {
                        Circle()
                            .stroke(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                ),
                                lineWidth: 2
                            )
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    private var dotColor: Color {
        if hasActivity {
            return intensityColor
        } else {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
            )
        }
    }

    private var intensityColor: Color {
        if cardsCount >= 50 {
            return AppTheme.Colors.Fallback.success
        } else if cardsCount >= 20 {
            return AppTheme.Colors.Fallback.success.opacity(0.7)
        } else {
            return AppTheme.Colors.Fallback.success.opacity(0.4)
        }
    }

    private var dotSize: CGFloat {
        if hasActivity {
            return min(12 + CGFloat(cardsCount) / 10, 20)
        }
        return 12
    }
}

// MARK: - Compact Streak Badge

struct CompactStreakBadge: View {
    @ObservedObject var streakService: StreakService

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(streakColor)
            Text("\(streakService.stats.currentStreak)")
                .font(AppTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
            )
        )
        .clipShape(Capsule())
    }

    private var streakColor: Color {
        let streak = streakService.stats.currentStreak
        if streak >= 30 {
            return Color(hex: "FFD700")
        } else if streak >= 7 {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.accentLight,
                dark: AppTheme.Colors.Fallback.accentDark
            )
        } else if streak > 0 {
            return AppTheme.Colors.Fallback.warning
        } else {
            return Color.adaptive(
                light: AppTheme.Colors.Fallback.textTertiaryLight,
                dark: AppTheme.Colors.Fallback.textTertiaryDark
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StreakWidget(streakService: StreakService.shared)
        CompactStreakBadge(streakService: StreakService.shared)
    }
    .padding()
    .background(Color.adaptive(
        light: AppTheme.Colors.Fallback.backgroundLight,
        dark: AppTheme.Colors.Fallback.backgroundDark
    ))
}
