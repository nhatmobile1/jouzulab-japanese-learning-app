import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: Entry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Main Content Card
                mainContentCard

                // Metadata Section
                if !entry.tags.isEmpty || !entry.grammarPatterns.isEmpty {
                    metadataSection
                }

                // Info Section
                infoSection
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    entry.isFavorite.toggle()
                } label: {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(entry.isFavorite ? .yellow : .secondary)
                }
                .accessibilityLabel(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    // MARK: - Main Content Card

    private var mainContentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Japanese
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Japanese")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
                    .textCase(.uppercase)

                Text(entry.japanese)
                    .font(AppTheme.Typography.japaneseTitle)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }

            Divider()
                .background(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    ).opacity(0.3)
                )

            // Reading
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Reading")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
                    .textCase(.uppercase)

                if let reading = entry.reading {
                    Text(reading)
                        .font(AppTheme.Typography.japaneseHeadline)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                } else {
                    Text("No reading available")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .italic()
                }
            }

            Divider()
                .background(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    ).opacity(0.3)
                )

            // English
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("English")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        )
                    )
                    .textCase(.uppercase)

                if let english = entry.english {
                    Text(english)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                } else {
                    Text("No translation available")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .italic()
                }
            }

            // Completion Status
            if !entry.isComplete {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.Colors.Fallback.warning)
                    Text("Incomplete entry")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Tags
            if !entry.tags.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Scenarios")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .textCase(.uppercase)

                    FlowLayout(spacing: AppTheme.Spacing.xs) {
                        ForEach(entry.tags, id: \.self) { tag in
                            TagChip(
                                text: tag.capitalized,
                                color: Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                )
                            )
                        }
                    }
                }
            }

            // Grammar Patterns
            if !entry.grammarPatterns.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Grammar Patterns")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textTertiaryLight,
                                dark: AppTheme.Colors.Fallback.textTertiaryDark
                            )
                        )
                        .textCase(.uppercase)

                    FlowLayout(spacing: AppTheme.Spacing.xs) {
                        ForEach(entry.grammarPatterns, id: \.self) { pattern in
                            TagChip(
                                text: pattern,
                                color: Color.adaptive(
                                    light: AppTheme.Colors.Fallback.secondaryLight,
                                    dark: AppTheme.Colors.Fallback.secondaryDark
                                )
                            )
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Details")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    )
                )
                .textCase(.uppercase)

            VStack(spacing: 0) {
                DetailInfoRow(label: "Type", value: entry.entryType.capitalized)

                if let lessonDate = entry.lessonDate {
                    DetailInfoRow(label: "Lesson Date", value: lessonDate)
                }

                if let jlptLevel = entry.jlptLevel {
                    DetailInfoRow(
                        label: "JLPT Level",
                        value: jlptLevel,
                        valueColor: jlptLevel.jlptColor
                    )
                }

                if entry.lessonFrequency > 1 {
                    DetailInfoRow(
                        label: "Frequency",
                        value: "\(entry.lessonFrequency) occurrences",
                        valueColor: entry.isHighFrequency ? .orange : nil
                    )
                }

                DetailInfoRow(label: "Entry ID", value: entry.id, isLast: true)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Detail Info Row

struct DetailInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color?
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                Spacer()
                Text(value)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(
                        valueColor ?? Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
            }
            .padding(.vertical, AppTheme.Spacing.sm)

            if !isLast {
                Divider()
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textTertiaryLight,
                            dark: AppTheme.Colors.Fallback.textTertiaryDark
                        ).opacity(0.2)
                    )
            }
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EntryDetailView(
            entry: Entry(
                id: "entry_00001",
                japanese: "質問が ありますか",
                reading: "しつもんが ありますか",
                english: "Do you have any questions?",
                entryType: "phrase",
                lessonDate: "2023-02-26",
                tags: ["general", "greetings"],
                grammarPatterns: ["ますか"],
                jlptLevel: "N4",
                lessonFrequency: 5
            )
        )
    }
    .modelContainer(for: Entry.self, inMemory: true)
}
