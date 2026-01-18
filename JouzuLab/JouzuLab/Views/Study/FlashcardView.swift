import SwiftUI

struct FlashcardView: View {
    let entry: Entry
    let deckName: String?
    @Binding var isFlipped: Bool
    @ObservedObject var audioService: AudioService

    init(entry: Entry, deckName: String? = nil, isFlipped: Binding<Bool>, audioService: AudioService) {
        self.entry = entry
        self.deckName = deckName
        self._isFlipped = isFlipped
        self.audioService = audioService
    }

    var body: some View {
        ZStack {
            // Back side (shown when flipped)
            CardBackView(entry: entry, deckName: deckName, audioService: audioService)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)

            // Front side (shown when not flipped)
            CardFrontView(entry: entry, deckName: deckName)
                .rotation3DEffect(
                    .degrees(isFlipped ? -180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
        }
        .onTapGesture {
            withAnimation(AppTheme.Animation.smooth) {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - Card Front

struct CardFrontView: View {
    let entry: Entry
    let deckName: String?

    init(entry: Entry, deckName: String? = nil) {
        self.entry = entry
        self.deckName = deckName
    }

    /// Check if the Japanese text contains kanji
    private var containsKanji: Bool {
        entry.japanese.unicodeScalars.contains { scalar in
            // CJK Unified Ideographs range
            (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF) ||
            // CJK Unified Ideographs Extension A
            (scalar.value >= 0x3400 && scalar.value <= 0x4DBF)
        }
    }

    /// Check if there's a reading available and it's different from the Japanese
    private var shouldShowReading: Bool {
        guard let reading = entry.reading else { return false }
        return containsKanji && reading != entry.japanese
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Deck badge at top
            if let deckName = deckName {
                HStack {
                    DeckBadge(name: deckName)
                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            Spacer()

            // Japanese text with optional reading
            VStack(spacing: AppTheme.Spacing.sm) {
                // Japanese text (large)
                Text(entry.japanese)
                    .font(AppTheme.Typography.japaneseTitle)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.textPrimaryLight,
                            dark: AppTheme.Colors.Fallback.textPrimaryDark
                        )
                    )
                    .multilineTextAlignment(.center)

                // Reading below kanji (shown on front if kanji exists)
                if shouldShowReading, let reading = entry.reading {
                    Text(reading)
                        .font(AppTheme.Typography.reading)
                        .foregroundStyle(
                            Color.adaptive(
                                light: AppTheme.Colors.Fallback.textSecondaryLight,
                                dark: AppTheme.Colors.Fallback.textSecondaryDark
                            )
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

            // Tap hint
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 14))
                Text("Tap to reveal")
                    .font(AppTheme.Typography.caption)
            }
            .foregroundStyle(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.textTertiaryLight,
                    dark: AppTheme.Colors.Fallback.textTertiaryDark
                )
            )
            .padding(.bottom, AppTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .shadow(
            color: .black.opacity(0.1),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Card Back

struct CardBackView: View {
    let entry: Entry
    let deckName: String?
    @ObservedObject var audioService: AudioService

    init(entry: Entry, deckName: String? = nil, audioService: AudioService) {
        self.entry = entry
        self.deckName = deckName
        self.audioService = audioService
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Deck badge at top
            if let deckName = deckName {
                HStack {
                    DeckBadge(name: deckName)
                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            Spacer()

            // Japanese text (smaller on back)
            Text(entry.japanese)
                .font(AppTheme.Typography.japaneseHeadline)
                .foregroundStyle(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textPrimaryLight,
                        dark: AppTheme.Colors.Fallback.textPrimaryDark
                    )
                )
                .multilineTextAlignment(.center)

            // Reading (hiragana)
            if let reading = entry.reading {
                Text(reading)
                    .font(AppTheme.Typography.reading)
                    .foregroundStyle(
                        Color.adaptive(
                            light: AppTheme.Colors.Fallback.primaryLight,
                            dark: AppTheme.Colors.Fallback.primaryDark
                        )
                    )
            }

            // Divider
            Rectangle()
                .fill(
                    Color.adaptive(
                        light: AppTheme.Colors.Fallback.textTertiaryLight,
                        dark: AppTheme.Colors.Fallback.textTertiaryDark
                    ).opacity(0.3)
                )
                .frame(width: 60, height: 2)
                .padding(.vertical, AppTheme.Spacing.sm)

            // English translation
            if let english = entry.english {
                Text(english)
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

            Spacer()

            // Audio button
            AudioButton(entry: entry, audioService: audioService)
                .padding(.bottom, AppTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.surfaceLight,
                dark: AppTheme.Colors.Fallback.surfaceDark
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        .shadow(
            color: .black.opacity(0.1),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Audio Button

struct AudioButton: View {
    let entry: Entry
    @ObservedObject var audioService: AudioService

    var body: some View {
        Button {
            audioService.speakEntry(entry)
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: audioService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .medium))
                    .symbolEffect(.pulse, options: .repeating, isActive: audioService.isSpeaking)
                Text("Play Audio")
                    .font(AppTheme.Typography.callout)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Color.adaptive(
                    light: AppTheme.Colors.Fallback.primaryLight,
                    dark: AppTheme.Colors.Fallback.primaryDark
                )
            )
            .clipShape(Capsule())
        }
        .disabled(audioService.isSpeaking)
    }
}

// MARK: - Deck Badge

struct DeckBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 10, weight: .medium))
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.primaryLight,
                dark: AppTheme.Colors.Fallback.primaryDark
            )
        )
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Color.adaptive(
                light: AppTheme.Colors.Fallback.primaryLight,
                dark: AppTheme.Colors.Fallback.primaryDark
            )
            .opacity(0.1)
        )
        .clipShape(Capsule())
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
        FlashcardView(
            entry: entry,
            isFlipped: .constant(false),
            audioService: AudioService.shared
        )
        .padding(AppTheme.Spacing.lg)
        .frame(height: 400)
    }
    .background(
        Color.adaptive(
            light: AppTheme.Colors.Fallback.backgroundLight,
            dark: AppTheme.Colors.Fallback.backgroundDark
        )
    )
}
