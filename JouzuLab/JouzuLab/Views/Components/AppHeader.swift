import SwiftUI

struct AppHeader: View {
    let title: String
    var subtitle: String?
    var showMenuButton: Bool = true
    var onMenuTap: (() -> Void)?
    var onProfileTap: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Menu button
            if showMenuButton {
                Button {
                    onMenuTap?()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textPrimaryLight,
                                dark: AppTheme.Colors.Fallback.textPrimaryDark
                            )
                        )
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Menu")
            }

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
            }

            Spacer()

            // Profile button
            Button {
                onProfileTap?()
            } label: {
                Circle()
                    .fill(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("上")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
            .accessibilityLabel("Profile")
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

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        AppHeader(title: "Home", subtitle: "Welcome back!")

        AppHeader(title: "Study", subtitle: nil)

        Spacer()
    }
    .background(
        Color.adaptive(
            light: AppTheme.Colors.Fallback.backgroundLight,
            dark: AppTheme.Colors.Fallback.backgroundDark
        )
    )
}
