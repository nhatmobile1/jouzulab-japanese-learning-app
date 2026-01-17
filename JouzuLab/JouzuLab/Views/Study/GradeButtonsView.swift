import SwiftUI

struct GradeButtonsView: View {
    let entry: Entry
    let onGrade: (SRSGrade) -> Void

    private let srsService = SRSService.shared

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(SRSGrade.allCases, id: \.rawValue) { grade in
                GradeButton(
                    grade: grade,
                    intervalPreview: srsService.formatInterval(
                        srsService.previewInterval(entry: entry, grade: grade)
                    ),
                    action: { onGrade(grade) }
                )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Grade Button

struct GradeButton: View {
    let grade: SRSGrade
    let intervalPreview: String
    let action: () -> Void

    private var buttonColor: Color {
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
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text(grade.displayName)
                    .font(AppTheme.Typography.captionBold)
                    .foregroundStyle(.white)

                Text(intervalPreview)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let entry = Entry(
        id: "preview_001",
        japanese: "漢字",
        reading: "かんじ",
        english: "Chinese characters"
    )

    return VStack {
        Spacer()
        GradeButtonsView(entry: entry) { grade in
            print("Graded: \(grade.displayName)")
        }
        .padding()
    }
    .background(
        Color.adaptive(
            light: AppTheme.Colors.Fallback.backgroundLight,
            dark: AppTheme.Colors.Fallback.backgroundDark
        )
    )
}
