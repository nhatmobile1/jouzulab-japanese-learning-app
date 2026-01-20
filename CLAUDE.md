# JouzuLab - Japanese Learning App

Personal Japanese learning application built from 12,000+ italki lesson notes with shadowing practice.

## Purpose

Self-directed Japanese language learning tool that converts personal lesson notes into an organized, searchable resource with flashcard drilling, shadowing practice, and progress tracking.

## Status

**Phase 2 complete - Flashcards with SRS and custom deck import working**

## Current Stats

- 10,518 unique entries (deduplicated from 12,173 raw)
- ~4,000 complete entries imported (with Japanese + reading + English)
- 270 lesson sessions (Feb 2023 - Jan 2026)
- 89.3% have furigana readings
- 51.9% have English translations
- ~54% have JLPT level tags (enriched via Jisho API)

## Tech Stack

**Data Processing:**
- Python 3 (`scripts/parse_notes.py`) - Main parser with deduplication
- Python 3 (`scripts/enrich_jlpt.py`) - JLPT enrichment via Jisho.org API
- Python 3 (`scripts/shadowing_tool.py`) - Audio/video processing for shadowing
- Python 3 (`scripts/create_genki_deck.py`) - Convert CSV/TSV vocab lists to deck JSON
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
│   ├── shadowing_tool.py             # Process video/audio for shadowing
│   └── create_genki_deck.py          # Convert CSV/TSV to deck JSON format
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
    ├── project.yml                   # XcodeGen project spec (optional)
    └── JouzuLab/
        ├── JouzuLabApp.swift
        ├── Models/
        │   ├── Entry.swift           # SwiftData model for vocabulary entries
        │   └── Deck.swift            # SwiftData model for imported decks
        ├── Services/
        │   ├── DataImportService.swift   # Initial data import from bundle
        │   ├── DeckCatalog.swift         # Bundled deck catalog (italki, Genki)
        │   ├── DeckService.swift         # Import/manage custom JSON decks
        │   ├── SRSService.swift          # SM-2 spaced repetition algorithm
        │   └── AudioService.swift        # Japanese TTS via AVSpeechSynthesizer
        ├── Theme/
        │   └── Theme.swift           # AppTheme colors, typography, spacing
        ├── Views/
        │   ├── ContentView.swift     # Main tab view (Home, Study, Decks, Browse, Settings)
        │   ├── Dashboard/
        │   │   └── DashboardView.swift   # Home tab with stats
        │   ├── Study/
        │   │   ├── StudyView.swift           # Study session launcher
        │   │   ├── SessionConfigView.swift   # Pre-session setup (card count, filters)
        │   │   ├── FlashcardSessionView.swift # Main study session with card queue
        │   │   ├── FlashcardView.swift       # Single card with 3D flip animation
        │   │   ├── GradeButtonsView.swift    # Again/Hard/Good/Easy with intervals
        │   │   └── SessionSummaryView.swift  # Post-session stats
        │   ├── Shadow/
        │   │   └── ShadowView.swift      # Shadowing practice (Phase 2.5, not in tab bar)
        │   ├── Browse/
        │   │   ├── BrowseView.swift      # Unified filter system with search
        │   │   ├── BrowseFilters.swift   # Filter state and data provider
        │   │   ├── FilterBarView.swift   # Filter chips and filter sheet
        │   │   ├── EntryListView.swift
        │   │   └── EntryDetailView.swift
        │   ├── Decks/
        │   │   ├── DecksView.swift       # List installed decks, import new
        │   │   └── DeckDetailView.swift  # Deck info and entry list
        │   ├── Settings/
        │   │   └── SettingsView.swift    # App settings with deck management link
        │   └── Components/
        │       ├── EntryCard.swift
        │       ├── AppHeader.swift       # Reusable header with menu/profile
        │       └── SideMenu.swift        # Slide-out navigation menu
        └── Resources/
            └── japanese_data.json    # Bundled data
```

## Data Schema

### Entry (vocabulary item)
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
  "lesson_frequency": 1,
  "lesson": "L1"
}
```

### Deck JSON format (for importing custom decks)
```json
{
  "metadata": {
    "id": "genki-1",
    "name": "Genki I Vocabulary",
    "description": "Vocabulary from Genki I textbook",
    "author": "JouzuLab",
    "version": "1.0",
    "created_date": "2026-01-17",
    "total_entries": 500
  },
  "entries": [
    {
      "japanese": "あのう",
      "reading": "あのう",
      "english": "um...",
      "jlpt_level": "N5",
      "lesson": "会G"
    }
  ]
}
```

**Entry fields:** Only `japanese` is required. Optional fields auto-fill:
- `id`: Auto-generated as `{deckId}_{index}` if not provided
- `entry_type`: Auto-detected (vocab/phrase/sentence) based on content
- `tags`, `grammar_patterns`: Default to empty arrays
- Other fields: Default to nil/false/0

**Entry Types:** vocab, phrase, sentence

**Auto-Tags:** restaurant, shopping, transportation, time, daily_life, family, travel, weather, health, greetings

**JLPT Levels:** N5, N4, N3, N2, N1

## Data Pipeline

```
Source Notes (.txt) → parse_notes.py → japanese_data.json → iOS App
                            ↓
                 enrich_jlpt.py (optional)

Video/Audio → shadowing_tool.py → data/media/[source]/ → HTML Player / iOS App

CSV/TSV vocab → create_genki_deck.py → deck.json → Import via app
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

# Create Genki deck from CSV
python3 scripts/create_genki_deck.py genki1_vocab.csv --output genki_1.json --book 1

# Update iOS app data
cp data/japanese_data.json JouzuLab/JouzuLab/Resources/

# Open shadowing practice
open data/media/[source_name]/practice.html

# Regenerate Xcode project (requires: brew install xcodegen)
cd JouzuLab && xcodegen generate
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
- [x] UI redesign with Organic/Natural theme
- [x] AppHeader component with hamburger menu and profile button
- [x] SideMenu slide-out navigation
- [x] Tab order: Home → Study → Decks → Browse → Settings (5 tabs, no "More" menu)
- [x] Dark mode (adaptive colors throughout)

### Phase 2: Flashcards & Learning - COMPLETE
- [x] Flashcard view with 3D flip animation
- [x] Study session configuration (card count, JLPT filter)
- [x] Self-grading (Again/Hard/Good/Easy) with interval preview
- [x] SM-2 spaced repetition algorithm (SRSService)
- [x] Japanese text-to-speech audio (AudioService)
- [x] Session summary with accuracy stats
- [x] Custom deck import (JSON files)
- [x] Deck management (install, view, delete)
- [x] Flexible deck format (auto-generated IDs, optional fields)
- [x] Unified BrowseView filter system (works with any deck type)

### Phase 2.5: Shadowing Integration
- [ ] Process first shadowing content
- [ ] iOS audio playback for shadowing segments
- [ ] Link shadowing audio to matching entries
- [ ] Practice mode with speed controls

### Phase 3: Progress & Stats
- [ ] Mastery levels per entry (tracking exists, UI needed)
- [ ] Study streaks
- [ ] Stats dashboard
- [ ] Progress by scenario/JLPT level

### Phase 4: Polish & Advanced
- [ ] Custom study lists
- [ ] Widgets
- [ ] iCloud sync
- [ ] Wire up side menu navigation to switch tabs

## UI Design

**Theme:** Organic/Natural with earthy green tones
- Primary: #4A6741 (light) / #7C9A6D (dark)
- Background: #F5F2EB (light) / #1C2419 (dark)
- Cards with subtle shadows, 8pt corner radius
- Rounded system font throughout

**Navigation:**
- Bottom tab bar: Home, Study, Decks, Browse, Settings (5 tabs)
- Standard iOS navigation bars with back buttons
- Each tab has its own NavigationStack for proper navigation flow

**BrowseView:**
- Search bar at top
- Filter bar with active filter chips (removable)
- Filter sheet for selecting: Deck, JLPT, Entry Type, Lesson, Tags, Favorites
- Entry list with JLPT badge, lesson indicator, favorite star

**StudyView:**
- Session config: Select new card count (5/10/15/20), optional JLPT filter
- Flashcard: Front (Japanese), Back (reading + English + audio button)
- Grade buttons: Again (red), Hard (orange), Good (green), Easy (blue)
- Summary: Cards reviewed, accuracy %, option to continue

## Recent Changes (January 18-19, 2026)

### Study Session Flow Fix (Critical Bug)
- **Problem:** On first app launch, pressing "Start Session" showed "No Cards Available" despite entries being loaded
- **Root Cause:** SwiftUI's `fullScreenCover(isPresented:)` captures closure variables at view build time, not presentation time
- **Solution:**
  1. Changed SessionConfigView to use two-step flow: "Apply Settings" → "Start Session"
  2. Changed StudyView to use `fullScreenCover(item:)` with `FlashcardSessionData` struct
  3. Removed `@Query` from SessionConfigView, now fetches directly from `modelContext`
- **Key Learning:** When passing data to sheets/covers, use item-based presentation (`sheet(item:)`) to ensure data is captured at presentation time, not view build time

### SessionConfigView Refactor
- Removed `@Query` - now fetches decks and entries directly from `modelContext`
- Two-step button flow: "Apply Settings" loads cards, then "Start Session" becomes available
- Stats preview only shows after settings are applied
- Changing deck or JLPT filter resets to require re-applying settings

### Deck Detail View Improvements
- Entries now grouped by month/year for italki notes (e.g., "January 2024")
- Genki entries grouped by lesson (e.g., "L1", "会G") with natural sorting
- Entries are clickable → navigates to EntryDetailView
- Entry rows show type badge, mastery indicator, and navigation chevron
- Collapsible sections show entry count and type summary when collapsed
- Large groups limited to 50 entries for performance

### Complete Entries Filter
- Only imports entries with Japanese + reading + English translation
- Reduces italki notes from ~10,500 to ~4,000 usable flashcard entries
- Applied in both DeckCatalog (bundled) and DeckService (file import)

### Genki Deck Update
- Reparsed Genki 3rd Edition deck from Excel source file
- 1774 complete entries with correct readings and translations
- Entries organized by lesson (会G, L1-L23)

### Navigation Cleanup
- Reduced to 5 tabs: Home, Study, Decks, Browse, Settings
- Removed Shadow tab (not implemented yet) to eliminate iOS "More" menu
- BrowseView uses standard navigation bar (removed custom sidebar button)
- Clean single back button navigation from EntryDetailView

### Dashboard Updates
- "Total Entries" → "Total Studying" (entries with masteryLevel != .new)
- "Entry Types" breakdown now shows only entries being studied

### Bug Fixes
- Fixed italki deck not showing as installed (migration for existing users)
- Fixed "Import Failed" error (DeckCatalog handles both DeckJSON and JapaneseData formats)
- Fixed duplicate back button issue in EntryDetailView
- Added app icon (koi fish design)

## Next Steps (Immediate)

1. **Test flashcard flow end-to-end** - Verify SRS intervals persist correctly
2. **Import a Genki deck** - Use create_genki_deck.py to create and import
3. **Process first shadowing content** - Use `shadowing_tool.py` on a video clip
4. **Build stats dashboard** - Show study progress, streaks, mastery breakdown

## SwiftUI/SwiftData Troubleshooting Patterns

### Data Not Available in Sheets/Covers

**Problem:** Data passed to `sheet(isPresented:)` or `fullScreenCover(isPresented:)` is empty or stale.

**Why it happens:** SwiftUI captures closure variables when the view body is built, not when the sheet is presented. If your data changes after the view is built but before presentation, the sheet receives the old (possibly empty) data.

**Solution:** Use item-based presentation:
```swift
// BAD - data captured at view build time
@State private var entries: [Entry] = []
.fullScreenCover(isPresented: $showSession) {
    SessionView(entries: entries)  // May be empty!
}

// GOOD - data passed at presentation time
struct SessionData: Identifiable {
    let id = UUID()
    let entries: [Entry]
}
@State private var activeSession: SessionData? = nil
.fullScreenCover(item: $activeSession) { data in
    SessionView(entries: data.entries)  // Always has the data
}
```

### @Query Not Updating During Async Operations

**Problem:** `@Query` results don't update inside a `Task` loop or async polling.

**Why it happens:** `@Query` updates trigger SwiftUI view re-renders. Inside a Task, the view isn't re-rendering, so the query results don't change.

**Solution:** Fetch directly from `modelContext` instead of relying on `@Query`:
```swift
// Instead of waiting for @Query to update
@Query private var entries: [Entry]

// Fetch directly when you need current data
let descriptor = FetchDescriptor<Entry>()
let entries = try modelContext.fetch(descriptor)
```

### Race Conditions on First App Launch

**Problem:** Data import happens async on first launch, but views try to use the data before it's ready.

**Solution patterns:**
1. **Two-step UI flow:** Show "Apply Settings" button that loads data, then show action button
2. **Loading states:** Track `isDataLoaded` state, show spinner until data is available
3. **Direct context fetch:** Don't rely on `@Query` for time-sensitive operations
4. **Item-based presentation:** Pass loaded data directly to presented views

### General Debugging Tips

1. Add `print()` statements to trace data flow through callbacks
2. Check if variables are captured at the right time (view build vs presentation)
3. For sheets/covers: Always prefer `sheet(item:)` over `sheet(isPresented:)` when passing data
4. For SwiftData: Use `modelContext.fetch()` when you need guaranteed fresh data

## Documentation

- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Complete folder structure and data flow
- [docs/DATA_STRUCTURE_GUIDE.md](docs/DATA_STRUCTURE_GUIDE.md) - Data schemas and iOS integration
- [docs/SHADOWING_TOOL_GUIDE.md](docs/SHADOWING_TOOL_GUIDE.md) - How to use the shadowing tool
