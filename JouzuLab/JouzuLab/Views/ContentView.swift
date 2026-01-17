import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true
    @State private var importError: String?
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case study = "Study"
        case shadow = "Shadow"
        case browse = "Browse"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .study: return "rectangle.stack.fill"
            case .shadow: return "waveform"
            case .browse: return "book.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = importError {
                ErrorView(message: error) {
                    Task { await importData() }
                }
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .task {
            await importData()
        }
    }

    private func importData() async {
        isLoading = true
        importError = nil

        let service = DataImportService(modelContext: modelContext)

        do {
            if try service.needsImport() {
                let result = try await service.performInitialImport()
                print("Imported \(result.imported) entries")
            }
            isLoading = false
        } catch {
            importError = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(ContentView.Tab.home.rawValue, systemImage: ContentView.Tab.home.icon)
                }
                .tag(ContentView.Tab.home)

            StudyView()
                .tabItem {
                    Label(ContentView.Tab.study.rawValue, systemImage: ContentView.Tab.study.icon)
                }
                .tag(ContentView.Tab.study)

            ShadowView()
                .tabItem {
                    Label(ContentView.Tab.shadow.rawValue, systemImage: ContentView.Tab.shadow.icon)
                }
                .tag(ContentView.Tab.shadow)

            BrowseView()
                .tabItem {
                    Label(ContentView.Tab.browse.rawValue, systemImage: ContentView.Tab.browse.icon)
                }
                .tag(ContentView.Tab.browse)

            SettingsView()
                .tabItem {
                    Label(ContentView.Tab.settings.rawValue, systemImage: ContentView.Tab.settings.icon)
                }
                .tag(ContentView.Tab.settings)
        }
        .tint(Color.adaptive(
            light: AppTheme.Colors.Fallback.primaryLight,
            dark: AppTheme.Colors.Fallback.primaryDark
        ))
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.adaptive(
                    light: AppTheme.Colors.Fallback.primaryLight,
                    dark: AppTheme.Colors.Fallback.primaryDark
                ))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("JouzuLab")
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )

                Text("Loading entries...")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.Colors.Fallback.warning)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Import Failed")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )

                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textSecondaryLight,
                            dark: AppTheme.Colors.Fallback.textSecondaryDark
                        )
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }

            Button {
                retryAction()
            } label: {
                Text("Retry")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    ))
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry importing data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.backgroundLight,
                dark: AppTheme.Colors.Fallback.backgroundDark
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
