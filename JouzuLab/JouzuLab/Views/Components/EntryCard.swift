import SwiftUI

struct EntryCard: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Japanese Text
            HStack {
                Text(entry.japanese)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Favorite indicator
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }

                // Completion indicator
                if !entry.isComplete {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }

                // Entry type badge
                Text(entry.entryType.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entryTypeColor.opacity(0.15))
                    .foregroundStyle(entryTypeColor)
                    .clipShape(Capsule())
            }

            // Reading
            if let reading = entry.reading {
                Text(reading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // English
            if let english = entry.english {
                Text(english)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var entryTypeColor: Color {
        switch entry.entryType {
        case "vocab": return .blue
        case "phrase": return .green
        case "sentence": return .purple
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        EntryCard(
            entry: Entry(
                id: "entry_00001",
                japanese: "質問が ありますか",
                reading: "しつもんが ありますか",
                english: "Do you have any questions?",
                entryType: "phrase"
            )
        )

        EntryCard(
            entry: Entry(
                id: "entry_00002",
                japanese: "発音",
                reading: "はつおん",
                english: "pronunciation",
                entryType: "vocab"
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
    .modelContainer(for: Entry.self, inMemory: true)
}
