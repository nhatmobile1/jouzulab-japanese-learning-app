import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]
    @State private var showSideMenu = false

    private var reviewDueCount: Int {
        let now = Date()
        return allEntries.filter { entry in
            guard let nextReview = entry.nextReview else { return false }
            return nextReview <= now
        }.count
    }

    private var newCount: Int {
        allEntries.filter { $0.masteryLevel == .new }.count
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

                            Text("Coming in Phase 2")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            FeatureRow(
                                icon: "rectangle.portrait.on.rectangle.portrait",
                                title: "Flip Cards",
                                description: "Tap to reveal readings and translations"
                            )

                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "Spaced Repetition",
                                description: "Smart scheduling based on your performance"
                            )

                            FeatureRow(
                                icon: "hand.thumbsup.fill",
                                title: "Self-Grading",
                                description: "Rate as Easy, Good, Hard, or Again"
                            )

                            FeatureRow(
                                icon: "calendar.badge.clock",
                                title: "Daily Reviews",
                                description: "Keep your knowledge fresh"
                            )
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        .padding(.horizontal, AppTheme.Spacing.md)

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
                                Text("New entries")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                                        )
                                    )
                            }

                            VStack {
                                Text("\(reviewDueCount)")
                                    .font(AppTheme.Typography.statMedium)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.accentLight,
                                            dark: AppTheme.Colors.Fallback.accentDark
                                        )
                                    )
                                Text("Due for review")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(
                                        Color.adaptive(
                                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                                        )
                                    )
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()

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
