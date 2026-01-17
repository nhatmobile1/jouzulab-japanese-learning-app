import SwiftUI

struct EntryCard: View {
    let entry: Entry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // Japanese Text + Badges
            HStack(alignment: .center, spacing: AppTheme.Spacing.xs) {
                Text(entry.japanese)
                    .font(AppTheme.Typography.japaneseBody)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Spacer()

                // Favorite indicator
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 12, weight: .medium))
                }

                // High frequency indicator
                if entry.isHighFrequency {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12, weight: .medium))
                }

                // Completion indicator
                if !entry.isComplete {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.Fallback.warning)
                        .font(.system(size: 12, weight: .medium))
                }

                // Entry type badge
                Text(entry.entryType.capitalized)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, AppTheme.Spacing.xs)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(entry.entryType.entryTypeColor.opacity(0.15))
                    .foregroundStyle(entry.entryType.entryTypeColor)
                    .clipShape(Capsule())
            }

            // Reading
            if let reading = entry.reading {
                Text(reading)
                    .font(AppTheme.Typography.reading)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }

            // English
            if let english = entry.english {
                Text(english)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .lineLimit(2)
            }

            // JLPT Level (if available)
            if let jlptLevel = entry.jlptLevel {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Text(jlptLevel)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(jlptLevel.jlptColor)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppTheme.Spacing.md) {
        EntryCard(
            entry: Entry(
                id: "entry_00001",
                japanese: "質問が ありますか",
                reading: "しつもんが ありますか",
                english: "Do you have any questions?",
                entryType: "phrase",
                jlptLevel: "N4"
            )
        )

        EntryCard(
            entry: Entry(
                id: "entry_00002",
                japanese: "発音",
                reading: "はつおん",
                english: "pronunciation",
                entryType: "vocab",
                jlptLevel: "N3",
                lessonFrequency: 5
            )
        )

        EntryCard(
            entry: Entry(
                id: "entry_00003",
                japanese: "今日は何日ですか",
                reading: nil,
                english: nil,
                entryType: "sentence"
            )
        )
    }
    .padding()
    .background(Color.adaptive(
        light: AppTheme.Colors.Fallback.backgroundLight,
        dark: AppTheme.Colors.Fallback.backgroundDark
    ))
    .modelContainer(for: Entry.self, inMemory: true)
}
