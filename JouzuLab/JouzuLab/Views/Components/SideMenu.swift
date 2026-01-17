import SwiftUI

struct SideMenu: View {
    @Binding var isPresented: Bool
    var onNavigate: ((SideMenuItem) -> Void)?

    enum SideMenuItem: String, CaseIterable {
        case home = "Home"
        case study = "Study"
        case shadow = "Shadow"
        case browse = "Browse"
        case settings = "Settings"
        case decks = "Decks"
        case favorites = "Favorites"
        case stats = "Statistics"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .study: return "rectangle.stack.fill"
            case .shadow: return "waveform"
            case .browse: return "book.fill"
            case .settings: return "gearshape.fill"
            case .decks: return "square.stack.3d.up"
            case .favorites: return "star.fill"
            case .stats: return "chart.bar.fill"
            }
        }

        var isMainTab: Bool {
            switch self {
            case .home, .study, .shadow, .browse, .settings:
                return true
            default:
                return false
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Dimmed background
                if isPresented {
                    Color.black
                        .opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(AppTheme.Animation.standard) {
                                isPresented = false
                            }
                        }
                }

                // Menu panel
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Circle()
                                .fill(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.primaryLight,
                                        dark: AppTheme.Colors.Fallback.primaryDark
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("上手")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                )

                            Text("JouzuLab")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                                    )
                                )

                            Text("Japanese Learning")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(
                                    Color.adaptive(
                                        light: AppTheme.Colors.Fallback.textSecondaryLight,
                                        dark: AppTheme.Colors.Fallback.textSecondaryDark
                                    )
                                )
                        }
                        .padding(AppTheme.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.surfaceElevatedLight,
                                dark: AppTheme.Colors.Fallback.surfaceElevatedDark
                            )
                        )

                        // Menu items
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // Main tabs section
                                ForEach(SideMenuItem.allCases.filter { $0.isMainTab }, id: \.self) { item in
                                    MenuRow(item: item) {
                                        onNavigate?(item)
                                        withAnimation(AppTheme.Animation.standard) {
                                            isPresented = false
                                        }
                                    }
                                }

                                Divider()
                                    .padding(.vertical, AppTheme.Spacing.sm)

                                // Additional items
                                ForEach(SideMenuItem.allCases.filter { !$0.isMainTab }, id: \.self) { item in
                                    MenuRow(item: item) {
                                        onNavigate?(item)
                                        withAnimation(AppTheme.Animation.standard) {
                                            isPresented = false
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.sm)
                        }

                        Spacer()

                        // Version info
                        Text("Version 1.0.0")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                                )
                            )
                            .padding(AppTheme.Spacing.md)
                    }
                    .frame(width: min(geometry.size.width * 0.8, 300))
                    .background(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.surfaceLight,
                            dark: AppTheme.Colors.Fallback.surfaceDark
                        )
                    )
                    .offset(x: isPresented ? 0 : -min(geometry.size.width * 0.8, 300))

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Menu Row

struct MenuRow: View {
    let item: SideMenu.SideMenuItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )

                Text(item.rawValue)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SideMenu(isPresented: .constant(true))
}
