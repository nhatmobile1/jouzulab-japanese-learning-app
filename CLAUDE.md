# JouzuLab - Japanese Learning App

Personal Japanese learning application built from 12,000+ italki lesson notes with shadowing practice.

## Purpose

Self-directed Japanese language learning tool that converts personal lesson notes into an organized, searchable resource with flashcard drilling, shadowing practice, and progress tracking.

## Status

**Phase 1 iOS app created, data pipeline complete, shadowing tool ready**

## Current Stats

- 10,518 unique entries (deduplicated from 12,173 raw)
- 270 lesson sessions (Feb 2023 - Jan 2026)
- 89.3% have furigana readings
- 51.9% have English translations
- ~54% have JLPT level tags (enriched via Jisho API)

## Tech Stack

**Data Processing:**
- Python 3 (`scripts/parse_notes.py`) - Main parser with deduplication
- Python 3 (`scripts/enrich_jlpt.py`) - JLPT enrichment via Jisho.org API
- Python 3 (`scripts/shadowing_tool.py`) - Audio/video processing for shadowing
- JSON output

**iOS App:**
- iOS 17+ / SwiftUI / SwiftData
- MVVM architecture
- App name: JouzuLab (上手Lab)

## File Structure

```
japanese-learning-app/
├── CLAUDE.md                         # This file
├── PROJECT_STRUCTURE.md              # Detailed structure guide
│
├── data/
│   ├── japanese_data.json            # Main database (10,521 entries)
│   └── media/                        # Shadowing practice content
│       └── [source_name]/            # e.g., terrace_house_ep3/
│           ├── practice_data.json
│           ├── practice.html
│           └── segment_XXXX/
│
├── scripts/
│   ├── parse_notes.py                # Parse italki notes to JSON
│   ├── enrich_vocab.py               # Enrich vocab with readings/English via Jisho API
│   ├── enrich_jlpt.py                # JLPT level enrichment via Jisho API
│   └── shadowing_tool.py             # Process video/audio for shadowing
│
├── tasks/
│   └── todo.md                       # Task tracking and planning
│
├── source/
│   ├── 日本語のレッスンのノート App Edit.txt  # Primary source (ISO dates)
│   └── 日本語のレッスンノート.txt              # Legacy source
│
├── docs/
│   ├── DATA_STRUCTURE_GUIDE.md       # Schema & iOS integration guide
│   └── SHADOWING_TOOL_GUIDE.md       # Shadowing tool usage guide
│
└── JouzuLab/                         # iOS Xcode project
    └── JouzuLab/
        ├── JouzuLabApp.swift
        ├── Models/
        │   └── Entry.swift           # SwiftData model
        ├── Services/
        │   └── DataImportService.swift
        ├── Views/
        │   ├── ContentView.swift
        │   ├── Browse/
        │   │   ├── BrowseView.swift
        │   │   ├── EntryListView.swift
        │   │   └── EntryDetailView.swift
        │   └── Components/
        │       └── EntryCard.swift
        └── Resources/
            └── japanese_data.json    # Bundled data
```

## Data Schema

```json
{
  "id": "entry_00001",
  "japanese": "漢字",
  "reading": "かんじ",
  "english": "Chinese characters",
  "entry_type": "vocab",
  "lesson_date": "2023-02-26",
  "tags": ["general"],
  "grammar_patterns": [],
  "jlpt_level": "N5",
  "is_sub_entry": false,
  "lesson_frequency": 1
}
```

**Entry Types:** vocab (5,011), phrase (4,313), sentence (1,197)

**Auto-Tags:** restaurant, shopping, transportation, time, daily_life, family, travel, weather, health, greetings

**JLPT Levels:** N5, N4, N3, N2, N1 (enriched via Jisho API)

**Lesson Frequency:** Tracks how many times an entry appeared across lessons (high frequency = 3+)

## Data Pipeline

```
Source Notes (.txt) → parse_notes.py → japanese_data.json → iOS App
                            ↓
                 enrich_jlpt.py (optional)

Video/Audio → shadowing_tool.py → data/media/[source]/ → HTML Player / iOS App
```

## Common Commands

```bash
# Parse notes to JSON
python3 scripts/parse_notes.py \
  --input "source/日本語のレッスンのノート App Edit.txt" \
  --output "data/japanese_data.json"

# Enrich JLPT levels via Jisho API
python3 scripts/enrich_jlpt.py --input "data/japanese_data.json"

# Process shadowing content
python3 scripts/shadowing_tool.py video.mp4 \
  --output-dir data/media/source_name \
  --model large \
  --title "Source Title"

# Update iOS app data
cp data/japanese_data.json JouzuLab/JouzuLab/Resources/

# Open shadowing practice
open data/media/[source_name]/practice.html
```

## Development Phases

### Phase 1: Foundation (MVP) - COMPLETE
- [x] Project setup with SwiftUI + SwiftData
- [x] Data import from JSON (batch optimized)
- [x] Browse entries by scenario
- [x] Search functionality
- [x] Entry detail view
- [x] Shadowing tool ready
- [x] Favorites/starring (swipe to star, filter toggle)
- [x] Lesson frequency tracking
- [x] Vocab enrichment via Jisho API
- [ ] Basic filtering (entry type, JLPT level)

### Phase 2: Flashcards & Learning
- [ ] Flashcard view (flip animation)
- [ ] Study session configuration
- [ ] Self-grading (Easy/Good/Hard/Again)
- [ ] Basic SRS algorithm
- [ ] Daily review queue

### Phase 2.5: Shadowing Integration
- [ ] Process first shadowing content
- [ ] iOS audio playback for shadowing segments
- [ ] Link shadowing audio to matching entries
- [ ] Practice mode with speed controls

### Phase 3: Progress & Stats
- [ ] Mastery levels per entry
- [ ] Study streaks
- [ ] Stats dashboard
- [ ] Progress by scenario/JLPT level

### Phase 4: Polish & Advanced
- [ ] Custom study lists
- [ ] Dark mode
- [ ] Widgets
- [ ] iCloud sync

## Next Steps (Immediate)

1. **Add JLPT filter** - Allow filtering by N5/N4/N3/N2/N1 in browse view
2. **Add high-frequency filter** - Filter entries with 3+ lesson occurrences
3. **Process first shadowing content** - Use `shadowing_tool.py` on a video clip
4. **Build Phase 2** - Implement flashcard functionality

## Documentation

- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Complete folder structure and data flow
- [docs/DATA_STRUCTURE_GUIDE.md](docs/DATA_STRUCTURE_GUIDE.md) - Data schemas and iOS integration
- [docs/SHADOWING_TOOL_GUIDE.md](docs/SHADOWING_TOOL_GUIDE.md) - How to use the shadowing tool
