# JouzuLab (上手Lab)

A personal Japanese learning app built from 12,000+ italki lesson notes, featuring vocabulary browsing, search, favorites, and shadowing practice tools.

## Features

- **10,521 vocabulary entries** parsed from 270 italki tutoring sessions
- **Browse by scenario** - Restaurant, Shopping, Travel, Daily Life, etc.
- **Search** - Find entries by Japanese, reading (hiragana), or English
- **Favorites** - Star important words for quick access
- **JLPT tagging** - Entries tagged with N5/N4/N3 levels
- **Shadowing tool** - Process video/audio for pronunciation practice

## Screenshots

*Coming soon*

## Tech Stack

**iOS App:**
- iOS 17+
- SwiftUI
- SwiftData

**Data Processing:**
- Python 3
- OpenAI Whisper (for shadowing)

## Project Structure

```
japanese-learning-app/
├── JouzuLab/              # iOS Xcode project
├── data/
│   ├── japanese_data.json # 10,521 parsed entries
│   └── media/             # Shadowing practice content
├── scripts/
│   ├── parse_notes.py     # Parse italki notes to JSON
│   ├── enrich_jlpt.py     # Add JLPT levels via Jisho API
│   └── shadowing_tool.py  # Process video/audio for shadowing
├── source/                # Original italki lesson notes
└── docs/                  # Guides and documentation
```

## Getting Started

### iOS App

1. Open `JouzuLab/JouzuLab.xcodeproj` in Xcode
2. Build and run on simulator or device (iOS 17+)

### Data Processing

```bash
# Parse notes to JSON
python3 scripts/parse_notes.py \
  --input "source/日本語のレッスンのノート App Edit.txt" \
  --output "data/japanese_data.json"

# Enrich with JLPT levels (optional)
python3 scripts/enrich_jlpt.py --input "data/japanese_data.json"

# Update iOS app data
cp data/japanese_data.json JouzuLab/JouzuLab/Resources/
```

### Shadowing Tool

```bash
# Install dependencies
pip install openai-whisper pydub ffmpeg-python

# Process video/audio
python3 scripts/shadowing_tool.py video.mp4 \
  --output-dir data/media/source_name \
  --model large \
  --title "Source Title"

# Open practice player
open data/media/source_name/practice.html
```

## Data Schema

Each entry contains:

```json
{
  "id": "entry_00001",
  "japanese": "質問",
  "reading": "しつもん",
  "english": "question",
  "entry_type": "vocab",
  "lesson_date": "2023-02-26",
  "tags": ["general"],
  "jlpt_level": "N4"
}
```

**Entry Types:** vocab, phrase, sentence

**Scenarios:** restaurant, shopping, transportation, time, daily_life, family, travel, weather, health, greetings

## Development Roadmap

- [x] Phase 1: Browse, search, favorites
- [ ] Phase 2: Flashcards with SRS
- [ ] Phase 2.5: Shadowing integration in iOS
- [ ] Phase 3: Progress tracking and stats
- [ ] Phase 4: Widgets, iCloud sync

## Documentation

- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Detailed folder structure
- [docs/DATA_STRUCTURE_GUIDE.md](docs/DATA_STRUCTURE_GUIDE.md) - Data schemas
- [docs/SHADOWING_TOOL_GUIDE.md](docs/SHADOWING_TOOL_GUIDE.md) - Shadowing tool usage

## License

Personal project - not licensed for redistribution.
