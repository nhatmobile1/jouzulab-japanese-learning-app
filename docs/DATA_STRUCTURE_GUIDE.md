# Japanese Learning App - Data Structure Guide

## Overview

Personal Japanese learning app built from 12,000+ italki lesson notes, designed for iOS/Swift.

---

## Project Structure

```
japanese-learning-app/
├── DATA_STRUCTURE_GUIDE.md      # This file
├── parse_notes.py               # Parser script
├── japanese_data.json           # Generated output (for iOS)
└── original_working_files/
    └── 日本語のレッスンノート.txt  # Source notes
```

---

## Notes File Format

Your source file uses this format:

```
日本語のレッスン 02/26              ← Lesson date marker

* 質問（しつもん）が ありますか - do you have any questions?
* 発音（はつおん）- pronunciation
* 図書館（としょかん）
* まだ - still, as of yet
   * 子供の例 - example with children   ← Sub-entry (indented)
```

**Entry patterns:**
| Pattern | Example |
|---------|---------|
| Full entry | `* 漢字（かんじ）- meaning` |
| No translation | `* 漢字（かんじ）` |
| Hiragana only | `* ひらがな - meaning` |
| Sub-entry | `   * 例文 - example` |

---

## Entry Schema (JSON Output)

```json
{
  "id": "entry_00001",
  "japanese": "質問が ありますか",
  "reading": "しつもんが ありますか",
  "english": "do you have any questions?",
  "entry_type": "phrase",
  "lesson_date": "2023-02-26",
  "tags": ["general"],
  "grammar_patterns": [],
  "jlpt_level": null,
  "context_note": null,
  "is_sub_entry": false,
  "source_line": 10
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (entry_00001 - entry_NNNNN) |
| `japanese` | string | Clean Japanese text (furigana removed) |
| `reading` | string? | Full hiragana reading (null if missing) |
| `english` | string? | English translation (null if missing) |
| `entry_type` | string | `vocab` \| `phrase` \| `sentence` |
| `lesson_date` | string? | When learned (YYYY-MM-DD) |
| `tags` | [string] | Auto-detected scenario tags |
| `grammar_patterns` | [string] | Detected grammar patterns |
| `jlpt_level` | string? | N5-N1 (future enhancement) |
| `context_note` | string? | Usage context (future enhancement) |
| `is_sub_entry` | bool | True if indented under parent entry |
| `source_line` | int | Line number in original notes |

### Entry Types

- **vocab**: Single words or short compounds (≤5 chars, no verb endings)
- **phrase**: Short expressions with verb patterns
- **sentence**: Longer complete sentences (>12 chars with endings)

### Auto-Tagged Scenarios

| Tag | Keywords |
|-----|----------|
| `restaurant` | 食べ, 飲み, 料理, メニュー, 注文, おいしい |
| `shopping` | 店, 買, 売, 値段, 高い, 安い |
| `transportation` | 駅, 電車, バス, 地下鉄, タクシー |
| `time` | 時, 分, 日, 月, 今日, 明日, 昨日 |
| `daily_life` | 仕事, 勉強, 寝, 起き, 家 |
| `family` | 家族, 母, 父, 娘, 息子, 犬, 猫 |
| `travel` | 旅行, ホテル, 予約, 観光 |
| `weather` | 天気, 雨, 晴, 暑い, 寒い |
| `health` | 病院, 医者, 薬, 痛い |
| `greetings` | おはよう, こんにちは, ありがとう |
| `general` | Default when no keywords match |

---

## Usage

### Parse Notes to JSON

```bash
python3 parse_notes.py \
  --input "original_working_files/日本語のレッスンノート.txt" \
  --output "japanese_data.json"
```

### Output

```
Total entries: 12,097
With reading:  10,720 (88.6%)
With English:  5,060 (41.8%)
Lesson dates:  264
```

---

## iOS/Swift Integration

### Option 1: Bundle JSON (Recommended for V1)

1. Add `japanese_data.json` to Xcode project
2. Parse at app launch into Swift models
3. Simple, no database setup required

```swift
struct Entry: Codable, Identifiable {
    let id: String
    let japanese: String
    let reading: String?
    let english: String?
    let entryType: String
    let lessonDate: String?
    let tags: [String]
    let grammarPatterns: [String]
    let jlptLevel: String?
    let contextNote: String?
    let isSubEntry: Bool
    let sourceLine: Int

    enum CodingKeys: String, CodingKey {
        case id, japanese, reading, english
        case entryType = "entry_type"
        case lessonDate = "lesson_date"
        case tags
        case grammarPatterns = "grammar_patterns"
        case jlptLevel = "jlpt_level"
        case contextNote = "context_note"
        case isSubEntry = "is_sub_entry"
        case sourceLine = "source_line"
    }
}

struct JapaneseData: Codable {
    let metadata: Metadata
    let entries: [Entry]
}
```

### Option 2: Core Data (For Future)

Convert JSON to Core Data for:
- Faster queries on large datasets
- User progress tracking
- Favorites/bookmarks
- Spaced repetition data

### Option 3: SQLite with GRDB (Advanced)

For complex queries and relationships:
- Filter by scenario + JLPT level
- Full-text search
- Grammar pattern relationships

---

## Data Pipeline

```
┌─────────────────────────────────┐
│  日本語のレッスンノート.txt       │  Source notes (you edit this)
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  python3 parse_notes.py         │  Parser script
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  japanese_data.json             │  iOS-ready data
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  iOS App (Swift/SwiftUI)        │  Your app
└─────────────────────────────────┘
```

---

## Current Stats

| Metric | Value |
|--------|-------|
| Total entries | 12,097 |
| With reading | 10,720 (88.6%) |
| With English | 5,060 (41.8%) |
| Lesson sessions | 264 |
| Date range | Feb 2023 - Present |

**Entry Types:**
- vocab: 6,473
- phrase: 4,422
- sentence: 1,202

**Top Scenarios:**
- general: 10,084
- time: 849
- restaurant: 394
- daily_life: 271
- family: 208

---

## Next Steps

1. **Complete source notes** - Add missing readings and English translations
2. **Re-run parser** - Generate updated JSON
3. **Create iOS project** - Set up Xcode with SwiftUI
4. **Build V1 features:**
   - Browse entries by scenario
   - Search functionality
   - Flashcard mode
   - Progress tracking

---

**Last Updated:** 2026-01-09
**Status:** Parser complete, ready for iOS development
