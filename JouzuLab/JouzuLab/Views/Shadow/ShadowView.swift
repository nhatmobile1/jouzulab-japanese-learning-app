import SwiftUI

struct ShadowView: View {
    @State private var showSideMenu = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App Header
                AppHeader(
                    title: "Shadow",
                    subtitle: "Pronunciation practice",
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
                        Image(systemName: "waveform")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.secondaryLight,
                                    dark: AppTheme.Colors.Fallback.secondaryDark
                                )
                            )
                            .padding(AppTheme.Spacing.lg)
                            .background(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.secondaryLight,
                                    dark: AppTheme.Colors.Fallback.secondaryDark
                                ).opacity(0.1)
                            )
                            .clipShape(Circle())

                        // Title
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Shadowing Practice")
                                .font(AppTheme.Typography.title)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )

                            Text("Coming in Phase 2.5")
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
                                icon: "play.circle.fill",
                                title: "Audio Playback",
                                description: "Listen to native pronunciation"
                            )

                            FeatureRow(
                                icon: "repeat",
                                title: "Loop Segments",
                                description: "Practice difficult phrases repeatedly"
                            )

                            FeatureRow(
                                icon: "speedometer",
                                title: "Speed Control",
                                description: "Slow down or speed up playback"
                            )

                            FeatureRow(
                                icon: "text.alignleft",
                                title: "Transcripts",
                                description: "Follow along with Japanese text"
                            )
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        .padding(.horizontal, AppTheme.Spacing.md)

                        // Info card
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.accentLight,
                                        dark: AppTheme.Colors.Fallback.accentDark
                                    )
                                )

                            Text("Shadowing tool is ready!")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )

                            Text("Use shadowing_tool.py to process video/audio content. iOS integration coming soon.")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                                .multilineTextAlignment(.center)
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
    }
}

#Preview {
    ShadowView()
}
