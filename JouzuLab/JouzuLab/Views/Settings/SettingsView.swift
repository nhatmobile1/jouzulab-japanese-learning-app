import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    @State private var showingResetAlert = false

    private var totalEntries: Int { allEntries.count }
    private var entriesWithReading: Int { allEntries.filter { $0.reading != nil }.count }
    private var entriesWithEnglish: Int { allEntries.filter { $0.english != nil }.count }
    private var favoritesCount: Int { allEntries.filter { $0.isFavorite }.count }

    var body: some View {
        NavigationStack {
            List {
                // Data Stats Section
                Section {
                    StatRow(label: "Total Entries", value: "\(totalEntries.formatted())")
                    StatRow(label: "With Reading", value: "\(entriesWithReading.formatted())")
                    StatRow(label: "With English", value: "\(entriesWithEnglish.formatted())")
                    StatRow(label: "Favorites", value: "\(favoritesCount)")
                } header: {
                    Text("Data")
                } footer: {
                    Text("Parsed from 270 italki lesson sessions")
                }

                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                    }

                    HStack {
                        Text("Data Version")
                        Spacer()
                        Text("2.1")
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                    }
                } header: {
                    Text("App")
                }

                // Data Management Section
                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Progress")
                        }
                    }
                    .accessibilityLabel("Reset all learning progress")
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("This will reset all mastery levels, review dates, and study progress. Your favorites will be preserved.")
                }

                // About Section
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("JouzuLab (上手Lab)")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.primaryLight,
                                    dark: AppTheme.Colors.Fallback.primaryDark
                                )
                            )

                        Text("A personal Japanese learning app built from italki lesson notes.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(
                                Color.adaptive(
                                    light: AppTheme.Colors.Fallback.textSecondaryLight,
                                    dark: AppTheme.Colors.Fallback.textSecondaryDark
                                )
                            )
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.backgroundLight,
                    dark: AppTheme.Colors.Fallback.backgroundDark
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset Progress?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetProgress()
                }
            } message: {
                Text("This will reset all mastery levels and review schedules. This action cannot be undone.")
            }
        }
    }

    private func resetProgress() {
        for entry in allEntries {
            entry.masteryLevel = .new
            entry.lastReviewed = nil
            entry.nextReview = nil
            entry.easeFactor = 2.5
            entry.reviewCount = 0
            entry.correctCount = 0
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.primaryLight,
                        dark: AppTheme.Colors.Fallback.primaryDark
                    )
                )
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Entry.self, inMemory: true)
}
