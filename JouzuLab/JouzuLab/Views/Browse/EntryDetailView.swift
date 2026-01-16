import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: Entry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Main Content Card
                mainContentCard

                // Metadata Section
                if !entry.tags.isEmpty || !entry.grammarPatterns.isEmpty {
                    metadataSection
                }

                // Info Section
                infoSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    entry.isFavorite.toggle()
                } label: {
                    Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(entry.isFavorite ? .red : .secondary)
                }
            }
        }
    }

    // MARK: - Main Content Card

    private var mainContentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Japanese
            VStack(alignment: .leading, spacing: 4) {
                Text("Japanese")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(entry.japanese)
                    .font(.system(size: 32, weight: .medium))
            }

            Divider()

            // Reading
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let reading = entry.reading {
                    Text(reading)
                        .font(.title2)
                        .foregroundStyle(.primary)
                } else {
                    Text("No reading available")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }

            Divider()

            // English
            VStack(alignment: .leading, spacing: 4) {
                Text("English")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                if let english = entry.english {
                    Text(english)
                        .font(.title3)
                        .foregroundStyle(.primary)
                } else {
                    Text("No translation available")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }

            // Completion Status
            if !entry.isComplete {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Incomplete entry")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tags
            if !entry.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scenarios")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 8) {
                        ForEach(entry.tags, id: \.self) { tag in
                            TagChip(text: tag, color: .blue)
                        }
                    }
                }
            }

            // Grammar Patterns
            if !entry.grammarPatterns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grammar Patterns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    FlowLayout(spacing: 8) {
                        ForEach(entry.grammarPatterns, id: \.self) { pattern in
                            TagChip(text: pattern, color: .purple)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                InfoRow(label: "Type", value: entry.entryType.capitalized)
                Divider().padding(.leading)

                if let lessonDate = entry.lessonDate {
                    InfoRow(label: "Lesson Date", value: lessonDate)
                    Divider().padding(.leading)
                }

                if let jlptLevel = entry.jlptLevel {
                    InfoRow(label: "JLPT Level", value: jlptLevel)
                    Divider().padding(.leading)
                }

                InfoRow(label: "Entry ID", value: entry.id)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
                grammarPatterns: ["ますか"]
            )
        )
    }
    .modelContainer(for: Entry.self, inMemory: true)
}
