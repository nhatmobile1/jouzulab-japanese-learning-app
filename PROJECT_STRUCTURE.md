# JouzuLab - Project Structure

## Overview

This document defines the folder structure for the JouzuLab Japanese learning app. The project combines:
1. **italki lesson notes** (10,521 entries) - vocabulary, phrases, sentences from tutoring sessions
2. **Shadowing practice** - audio/video content processed for pronunciation practice
3. **iOS app** - SwiftUI app for studying and drilling

---

## Folder Structure

```
japanese-learning-app/
│
├── CLAUDE.md                          # Primary project documentation
├── PROJECT_STRUCTURE.md               # This file
│
├── data/                              # All learning content
│   ├── japanese_data.json             # Main database (10,521 entries from italki)
│   │
│   └── media/                         # Shadowing practice content
│       └── [source_name]/             # e.g., terrace_house_ep3/
│           ├── practice_data.json     # Segment data with transcriptions
│           ├── practice.html          # Browser-based practice player
│           └── segment_XXXX/          # Audio files at 3 speeds
│               ├── segment_XXXX_slow.mp3
│               ├── segment_XXXX_normal.mp3
│               └── segment_XXXX_fast.mp3
│
├── scripts/                           # Data processing tools
│   ├── parse_notes.py                 # Parse italki notes to JSON
│   ├── enrich_jlpt.py                 # Add JLPT levels via Jisho API
│   └── shadowing_tool.py              # Process video/audio for shadowing
│
├── source/                            # Original source files
│   ├── 日本語のレッスンのノート App Edit.txt   # Primary italki notes
│   └── 日本語のレッスンノート.txt              # Legacy notes file
│
├── docs/                              # Documentation and guides
│   ├── DATA_STRUCTURE_GUIDE.md        # Data schemas, iOS integration
│   └── SHADOWING_TOOL_GUIDE.md        # How to use the shadowing tool
│
└── JouzuLab/                          # iOS Xcode project
    ├── JouzuLab.xcodeproj
    └── JouzuLab/
        ├── JouzuLabApp.swift
        ├── Models/
        │   └── Entry.swift            # SwiftData model
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
            ├── Assets.xcassets
            └── japanese_data.json     # Bundled copy for app
```

---

## Folder Descriptions

### `/data`
**Purpose:** All learning content and processed data

| Item | Description |
|------|-------------|
| `japanese_data.json` | 10,521 entries parsed from italki notes |
| `media/` | Shadowing practice content organized by source |

The `media/` folder will contain subfolders for each processed video/audio source. Each source folder includes:
- `practice_data.json` - Transcribed segments with timestamps
- `practice.html` - Standalone browser player for practice
- `segment_XXXX/` - Audio clips at slow/normal/fast speeds

---

### `/scripts`
**Purpose:** Python scripts for data processing

| Script | Purpose | Usage |
|--------|---------|-------|
| `parse_notes.py` | Parse italki .txt notes to JSON | After editing source notes |
| `enrich_jlpt.py` | Add JLPT levels via Jisho API | After parsing (optional) |
| `shadowing_tool.py` | Process video/audio for shadowing | When adding media content |

---

### `/source`
**Purpose:** Original source files (input to processing scripts)

Keep your original italki notes here. The `App Edit.txt` version uses ISO date format and is the primary source.

---

### `/docs`
**Purpose:** Detailed documentation and guides

| Document | Description |
|----------|-------------|
| `DATA_STRUCTURE_GUIDE.md` | Data schemas, entry types, iOS integration code |
| `SHADOWING_TOOL_GUIDE.md` | Complete guide for shadowing tool usage |

---

### `/JouzuLab`
**Purpose:** iOS application (Xcode project)

This is a complete SwiftUI + SwiftData iOS app. The app has its own copy of `japanese_data.json` in Resources that must be updated separately when data changes.

---

## Data Flow

```
                    ┌─────────────────┐
                    │  Source Files   │
                    │  (source/*.txt) │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ parse_notes.py  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ enrich_jlpt.py  │ (optional)
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │    data/japanese_data.json  │
              └──────────────┬──────────────┘
                             │
                    ┌────────▼────────┐
                    │   Copy to iOS   │
                    │    Resources    │
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │   JouzuLab iOS App          │
              │   (SwiftData import)        │
              └─────────────────────────────┘


                    ┌─────────────────┐
                    │  Video/Audio    │
                    │  (any source)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │shadowing_tool.py│
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │    data/media/[source]/     │
              │    - practice_data.json     │
              │    - practice.html          │
              │    - segment_XXXX/*.mp3     │
              └─────────────────────────────┘
```

---

## Common Commands

### Parse italki Notes
```bash
python3 scripts/parse_notes.py \
  --input "source/日本語のレッスンのノート App Edit.txt" \
  --output "data/japanese_data.json"
```

### Enrich with JLPT Levels
```bash
python3 scripts/enrich_jlpt.py --input "data/japanese_data.json"
```

### Process Shadowing Content
```bash
python3 scripts/shadowing_tool.py path/to/video.mp4 \
  --output-dir data/media/video_name \
  --model large \
  --title "Descriptive Title"
```

### Update iOS App Data
```bash
cp data/japanese_data.json JouzuLab/JouzuLab/Resources/
```

### Open Shadowing Practice
```bash
open data/media/[source_name]/practice.html
```

---

## Integration: Shadowing + italki Entries

The shadowing feature can be linked to your italki entries:

1. **Standalone shadowing** - Practice any Japanese media with the HTML player
2. **Entry-linked audio** - Match shadowing segments to existing entries by Japanese text

Future iOS integration could:
- Show audio playback for entries that have matching shadowing segments
- Filter shadowing content by scenario tags
- Track mastery across both text entries and audio practice

---

## Adding New Content

### New Shadowing Content
1. Record or download Japanese video/audio
2. Run `shadowing_tool.py` with `--model large` for best accuracy
3. Edit `practice_data.json` to add English translations and tags
4. Practice with `practice.html`

### New italki Notes
1. Update `source/日本語のレッスンのノート App Edit.txt`
2. Run `parse_notes.py`
3. Optionally run `enrich_jlpt.py`
4. Copy updated JSON to iOS app Resources

---

## Git Ignore Recommendations

```gitignore
# OS files
.DS_Store

# Python
__pycache__/
*.pyc
venv/

# Xcode
*.xcuserstate
xcuserdata/
DerivedData/

# Large media files (optional - may want to track)
# data/media/**/*.mp3

# Whisper models (downloaded automatically)
*.pt

# Environment
.env
```

---

**Last Updated:** 2026-01-16
