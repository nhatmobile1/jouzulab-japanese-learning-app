import Foundation
import AVFoundation

// MARK: - Speech Speed

enum SpeechSpeed: String, CaseIterable, Identifiable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"

    var id: String { rawValue }

    var rate: Float {
        switch self {
        case .slow: return 0.35
        case .normal: return 0.5
        case .fast: return 0.65
        }
    }

    var icon: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "hare.fill"
        case .fast: return "bolt.fill"
        }
    }
}

// MARK: - Audio Service

class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()

    @Published var isSpeaking: Bool = false
    @Published var currentSpeed: SpeechSpeed = .normal
    @Published var volume: Float = 1.0 // 0.0 to 1.0

    private let synthesizer = AVSpeechSynthesizer()
    private var japaneseVoice: AVSpeechSynthesisVoice?

    private override init() {
        super.init()
        synthesizer.delegate = self
        findJapaneseVoice()
        loadSettings()
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        volume = UserDefaults.standard.object(forKey: "audioVolume") as? Float ?? 1.0
        if let speedRaw = UserDefaults.standard.string(forKey: "audioSpeed"),
           let speed = SpeechSpeed(rawValue: speedRaw) {
            currentSpeed = speed
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(volume, forKey: "audioVolume")
        UserDefaults.standard.set(currentSpeed.rawValue, forKey: "audioSpeed")
    }

    // MARK: - Voice Setup

    private func findJapaneseVoice() {
        // Try to find a Japanese voice
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let japaneseVoices = voices.filter { $0.language.hasPrefix("ja") }

        // Prefer enhanced/premium voices if available
        if let enhancedVoice = japaneseVoices.first(where: { $0.quality == .enhanced }) {
            japaneseVoice = enhancedVoice
        } else if let defaultVoice = japaneseVoices.first {
            japaneseVoice = defaultVoice
        } else {
            // Fallback to language identifier
            japaneseVoice = AVSpeechSynthesisVoice(language: "ja-JP")
        }
    }

    // MARK: - Speak

    /// Speak Japanese text
    /// - Parameters:
    ///   - text: The text to speak (preferably hiragana/katakana for accuracy)
    ///   - speed: Speech speed (default: current speed setting)
    func speak(_ text: String, speed: SpeechSpeed? = nil) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = japaneseVoice
        utterance.rate = (speed ?? currentSpeed).rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = volume

        // Add slight pause before and after for natural feel
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    /// Speak an entry - uses reading (hiragana) for better pronunciation
    func speakEntry(_ entry: Entry, speed: SpeechSpeed? = nil) {
        // Prefer reading (hiragana) over japanese (kanji) for accurate pronunciation
        let textToSpeak = entry.reading ?? entry.japanese
        speak(textToSpeak, speed: speed)
    }

    // MARK: - Control

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func continueSpeaking() {
        synthesizer.continueSpeaking()
    }

    func setSpeed(_ speed: SpeechSpeed) {
        currentSpeed = speed
        saveSettings()
    }

    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        saveSettings()
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
