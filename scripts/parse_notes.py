#!/usr/bin/env python3
"""
Japanese Notes Parser
Parses raw lesson notes (.txt) directly into iOS-ready JSON format.

Usage:
    python parse_notes.py --input 日本語のレッスンノート.txt --output japanese_data.json
"""

import json
import re
import argparse
from datetime import datetime
from collections import defaultdict


class JapaneseNotesParser:
    def __init__(self):
        # Scenario keyword mapping for auto-tagging
        self.scenario_keywords = {
            "restaurant": [
                "レストラン", "料理", "食堂", "注文", "メニュー",
                "食べ", "飲み", "ごはん", "会計", "おいしい",
                "寿司", "ラーメン", "焼", "丼", "弁当",
                "eat", "drink", "food", "menu", "order", "restaurant",
                "delicious", "dish", "cuisine", "hungry"
            ],
            "shopping": [
                "店", "買", "売", "レジ", "ポイント", "セール",
                "買い物", "かいもの", "値段", "高い", "安い",
                "shop", "store", "buy", "sell", "price"
            ],
            "transportation": [
                "駅", "電車", "バス", "切符", "乗", "地下鉄",
                "新幹線", "タクシー", "飛行機", "空港",
                "station", "train", "bus", "subway", "taxi", "airport"
            ],
            "time": [
                "時", "分", "日", "月", "曜日", "年",
                "今日", "明日", "昨日", "週", "朝", "夜", "午後",
                "time", "hour", "day", "week", "month", "year",
                "today", "tomorrow", "yesterday", "morning", "night"
            ],
            "daily_life": [
                "仕事", "勉強", "寝", "起き", "散歩", "働",
                "家", "部屋", "料理", "洗濯", "掃除",
                "work", "study", "sleep", "wake", "walk", "home"
            ],
            "family": [
                "家族", "母", "父", "娘", "息子", "兄", "姉",
                "弟", "妹", "祖父", "祖母", "犬", "猫",
                "family", "mother", "father", "daughter", "son", "dog", "cat"
            ],
            "travel": [
                "旅行", "ホテル", "予約", "観光", "温泉",
                "travel", "hotel", "reservation", "sightseeing"
            ],
            "weather": [
                "天気", "雨", "晴", "曇", "雪", "暑い", "寒い",
                "weather", "rain", "sunny", "cloudy", "snow", "hot", "cold"
            ],
            "health": [
                "病院", "医者", "薬", "痛い", "具合", "熱",
                "hospital", "doctor", "medicine", "pain", "sick"
            ],
            "greetings": [
                "おはよう", "こんにちは", "こんばんは", "さようなら",
                "ありがとう", "すみません", "ごめん",
                "hello", "goodbye", "thank", "sorry"
            ]
        }

        # Grammar patterns with JLPT levels
        self.grammar_jlpt = {
            # N5 Grammar
            "です": "N5", "ます": "N5", "ません": "N5", "ました": "N5",
            "ませんでした": "N5", "てください": "N5", "ている": "N5",
            "たい": "N5", "たくない": "N5", "ないです": "N5",
            "から": "N5", "けど": "N5", "が": "N5",
            # N4 Grammar
            "ていただけますか": "N4", "てもらえますか": "N4",
            "てもいいですか": "N4", "てはいけません": "N4",
            "なければなりません": "N4", "ことができます": "N4",
            "ことがあります": "N4", "と思います": "N4",
            "つもりです": "N4", "予定です": "N4", "ようにする": "N4",
            "たことがある": "N4", "たり": "N4", "ながら": "N4",
            # N3 Grammar
            "そうです": "N3", "ようです": "N3", "らしいです": "N3",
            "ほうがいい": "N3", "すぎる": "N3", "やすい": "N3",
            "にくい": "N3", "ために": "N3", "ようになる": "N3",
            "ことにする": "N3", "ばかり": "N3", "はず": "N3",
            # N2 Grammar
            "わけではない": "N2", "というのは": "N2", "ことになる": "N2",
            "ざるを得ない": "N2", "に関して": "N2", "において": "N2",
        }

        # Common JLPT vocabulary (key words to detect level)
        self.vocab_jlpt = {
            # N5 Vocabulary
            "N5": [
                "食べる", "飲む", "行く", "来る", "見る", "聞く", "読む", "書く",
                "話す", "買う", "寝る", "起きる", "会う", "待つ", "作る", "使う",
                "今日", "明日", "昨日", "今", "朝", "夜", "午後", "午前",
                "時", "分", "月", "日", "年", "週", "曜日",
                "人", "男", "女", "子供", "友達", "先生", "学生",
                "家", "部屋", "学校", "会社", "駅", "店", "病院",
                "水", "お茶", "ご飯", "パン", "肉", "魚", "野菜", "果物",
                "大きい", "小さい", "高い", "安い", "新しい", "古い",
                "いい", "悪い", "多い", "少ない", "長い", "短い",
                "おいしい", "まずい", "暑い", "寒い", "暖かい", "涼しい",
            ],
            # N4 Vocabulary
            "N4": [
                "届ける", "届く", "預ける", "預かる", "捨てる", "拾う",
                "変える", "変わる", "決める", "決まる", "集める", "集まる",
                "経験", "習慣", "予定", "準備", "説明", "紹介", "相談",
                "関係", "理由", "意味", "興味", "趣味", "性格", "気持ち",
                "複雑", "簡単", "普通", "特別", "必要", "大切", "大事",
                "残念", "心配", "安心", "緊張", "恥ずかしい",
            ],
            # N3 Vocabulary
            "N3": [
                "影響", "効果", "原因", "結果", "目的", "方法", "状況",
                "責任", "義務", "権利", "自由", "平和", "環境", "社会",
                "経済", "政治", "文化", "歴史", "科学", "技術",
                "増える", "減る", "伸びる", "縮む", "広がる", "狭まる",
                "複雑", "単純", "具体的", "抽象的", "積極的", "消極的",
            ],
        }

        # Legacy grammar patterns list (for detection)
        self.grammar_patterns = list(self.grammar_jlpt.keys())

    def has_kanji(self, text):
        """Check if text contains kanji characters"""
        return bool(re.search(r'[一-龯]', text))

    def is_all_hiragana_katakana(self, text):
        """Check if text is only hiragana/katakana (no kanji)"""
        # Remove spaces and punctuation for check
        clean = re.sub(r'[\s\-\.\,\?\!]', '', text)
        # Hiragana: 3040-309F, Katakana: 30A0-30FF
        return bool(re.match(r'^[\u3040-\u309F\u30A0-\u30FF\u30FC\u3000-\u303Fー]+$', clean))

    def extract_furigana(self, text):
        """
        Extract reading from furigana notation: 漢字（かんじ）
        Returns: (clean_japanese, reading)
        """
        # Pattern matches: word（reading）
        pattern = r'([^（\s]+?)（([^）]+?)）'

        reading_parts = []
        clean_parts = []
        last_end = 0

        for match in re.finditer(pattern, text):
            # Add text before this match
            before = text[last_end:match.start()]
            clean_parts.append(before)
            reading_parts.append(before)

            # Add the kanji to clean, reading to reading
            clean_parts.append(match.group(1))
            reading_parts.append(match.group(2))
            last_end = match.end()

        # Add remaining text
        remaining = text[last_end:]
        clean_parts.append(remaining)
        reading_parts.append(remaining)

        clean_japanese = ''.join(clean_parts).strip()
        reading = ''.join(reading_parts).strip()

        # If reading still has kanji, we don't have complete furigana
        if self.has_kanji(reading):
            return clean_japanese, None

        return clean_japanese, reading

    def parse_entry_line(self, line):
        """
        Parse a single entry line.
        Formats:
          * Japanese（reading）- English
          * Japanese - English
          * Japanese（reading）
          * Japanese
        """
        # Remove bullet point
        line = re.sub(r'^\*\s*', '', line).strip()
        if not line:
            return None

        japanese = None
        reading = None
        english = None

        # Check for English translation (after " - " or "- ")
        # Handle both "Japanese - English" and "Japanese- English"
        if ' - ' in line:
            parts = line.split(' - ', 1)
            japanese_part = parts[0].strip()
            english = parts[1].strip()
        elif '- ' in line and re.search(r'[）a-zA-Z]\- ', line):
            # Handle "漢字（かんじ）- meaning" format
            parts = line.split('- ', 1)
            japanese_part = parts[0].strip()
            english = parts[1].strip()
        else:
            japanese_part = line

        # Extract furigana from Japanese part
        japanese, reading = self.extract_furigana(japanese_part)

        # If no furigana but text is all hiragana/katakana, it IS the reading
        if reading is None and self.is_all_hiragana_katakana(japanese):
            reading = japanese

        return {
            'japanese': japanese,
            'reading': reading,
            'english': english
        }

    def detect_entry_type(self, japanese, english):
        """Classify entry as vocab, phrase, sentence, or note"""
        if not japanese:
            return "note"

        # Count characters (excluding spaces)
        char_count = len(japanese.replace(' ', '').replace('　', ''))

        # Very short = vocab
        if char_count <= 5 and not any(p in japanese for p in ['ます', 'です', 'か']):
            return "vocab"

        # Has sentence-ending patterns = sentence
        if any(japanese.endswith(p) for p in ['ます', 'ました', 'ません', 'です', 'か', 'よ', 'ね']):
            if char_count > 12:
                return "sentence"
            return "phrase"

        # Medium length with verb patterns = phrase
        if any(p in japanese for p in ['ます', 'です', 'て', 'た']):
            return "phrase"

        # Default short = vocab, long = phrase
        return "vocab" if char_count <= 8 else "phrase"

    def detect_scenarios(self, japanese, english):
        """Auto-tag scenarios based on keywords"""
        text = f"{japanese} {english or ''}".lower()
        scenarios = []

        for scenario, keywords in self.scenario_keywords.items():
            for keyword in keywords:
                if keyword.lower() in text:
                    scenarios.append(scenario)
                    break

        return scenarios if scenarios else ["general"]

    def detect_grammar_patterns(self, japanese):
        """Detect grammar patterns in entry"""
        found = []
        for pattern in self.grammar_patterns:
            if pattern in japanese:
                found.append(pattern)
        return found

    def detect_jlpt_level(self, japanese, reading, english):
        """Detect JLPT level based on vocabulary and grammar patterns"""
        levels_found = []

        # Check grammar patterns
        for pattern, level in self.grammar_jlpt.items():
            if pattern in japanese:
                levels_found.append(level)

        # Check vocabulary
        for level, vocab_list in self.vocab_jlpt.items():
            for vocab in vocab_list:
                if vocab in japanese:
                    levels_found.append(level)
                    break

        # Return the highest (most difficult) level found
        if levels_found:
            level_order = {"N5": 1, "N4": 2, "N3": 3, "N2": 4, "N1": 5}
            return max(levels_found, key=lambda x: level_order.get(x, 0))

        return None

    def parse_lesson_date(self, line):
        """
        Parse lesson date from header line.
        Formats:
          - ISO: 2023-02-26 (from App Edit file)
          - Old: 日本語のレッスン MM/DD
        Returns: (full_date, needs_year) tuple
          - full_date: YYYY-MM-DD for ISO, or MM-DD for old format
          - needs_year: True if old format (needs year context), False for ISO
        """
        # Try ISO format first: YYYY-MM-DD at start of line
        iso_match = re.match(r'^(20\d{2}-\d{2}-\d{2})\s*$', line.strip())
        if iso_match:
            return iso_match.group(1), False

        # Try old format: 日本語のレッスン MM/DD
        old_match = re.search(r'日本語のレッスン\s*(\d{1,2})/(\d{1,2})', line)
        if old_match:
            month = int(old_match.group(1))
            day = int(old_match.group(2))
            return f"{month:02d}-{day:02d}", True

        return None, False

    def parse_file(self, input_path):
        """Parse the entire notes file"""
        print(f"Reading {input_path}...")

        with open(input_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        raw_entries = []
        current_date = None
        current_year = "2023"  # Default, updated if we find year markers

        stats = {
            'total_lines': len(lines),
            'entries': 0,
            'with_reading': 0,
            'with_english': 0,
            'entry_types': defaultdict(int),
            'scenarios': defaultdict(int),
            'lesson_dates': set(),
            'duplicates_merged': 0,
            'raw_entries': 0
        }

        for line_num, line in enumerate(lines, 1):
            line = line.strip()

            # Skip empty lines
            if not line:
                continue

            # Check for year marker (e.g., "2023年" or "2023ねん")
            year_match = re.search(r'(20\d{2})', line)
            if year_match and ('年' in line or 'ねん' in line):
                current_year = year_match.group(1)
                continue

            # Check for lesson date header
            date_result, needs_year = self.parse_lesson_date(line)
            if date_result:
                if needs_year:
                    # Old format: prepend current year
                    current_date = f"{current_year}-{date_result}"
                else:
                    # ISO format: already has full date, extract year for context
                    current_date = date_result
                    current_year = date_result[:4]
                stats['lesson_dates'].add(current_date)
                continue

            # Check for entry line (starts with * or is indented with *)
            if line.startswith('*') or (line.startswith(' ') and '*' in line):
                # Handle indented sub-entries
                is_sub_entry = line.startswith(' ') or line.startswith('\t')
                line = line.lstrip()

                if not line.startswith('*'):
                    continue

                parsed = self.parse_entry_line(line)
                if not parsed or not parsed['japanese']:
                    continue

                entry = {
                    'japanese': parsed['japanese'],
                    'reading': parsed['reading'],
                    'english': parsed['english'],
                    'entry_type': self.detect_entry_type(parsed['japanese'], parsed['english']),
                    'lesson_date': current_date,
                    'tags': self.detect_scenarios(parsed['japanese'], parsed['english']),
                    'grammar_patterns': self.detect_grammar_patterns(parsed['japanese']),
                    'jlpt_level': self.detect_jlpt_level(parsed['japanese'], parsed['reading'], parsed['english']),
                    'context_note': None,
                    'is_sub_entry': is_sub_entry,
                    'source_line': line_num
                }

                raw_entries.append(entry)
                stats['raw_entries'] += 1

        # Deduplicate and merge entries
        entries, stats['duplicates_merged'] = self.deduplicate_entries(raw_entries)

        # Assign IDs and update stats
        for i, entry in enumerate(entries, 1):
            entry['id'] = f"entry_{i:05d}"
            stats['entries'] += 1
            if entry['reading']:
                stats['with_reading'] += 1
            if entry['english']:
                stats['with_english'] += 1
            stats['entry_types'][entry['entry_type']] += 1
            for tag in entry['tags']:
                stats['scenarios'][tag] += 1

        return entries, stats

    def deduplicate_entries(self, entries):
        """
        Deduplicate entries by japanese text, merging info from duplicates.
        Returns: (deduplicated_entries, num_duplicates_merged)
        """
        # Group entries by japanese text
        grouped = defaultdict(list)
        for entry in entries:
            grouped[entry['japanese']].append(entry)

        deduplicated = []
        duplicates_merged = 0

        for japanese, group in grouped.items():
            if len(group) == 1:
                deduplicated.append(group[0])
            else:
                # Merge multiple entries
                merged = self.merge_entries(group)
                deduplicated.append(merged)
                duplicates_merged += len(group) - 1

        # Sort by first lesson date (earliest first)
        deduplicated.sort(key=lambda e: e['lesson_date'] or '9999-99-99')

        return deduplicated, duplicates_merged

    def merge_entries(self, entries):
        """
        Merge multiple entries with the same japanese text.
        Priority: prefer non-None values, combine tags/grammar patterns.
        """
        # Start with the first entry as base
        merged = entries[0].copy()

        # Track all lesson dates for reference
        all_dates = [e['lesson_date'] for e in entries if e['lesson_date']]

        for entry in entries[1:]:
            # Reading: prefer non-None
            if merged['reading'] is None and entry['reading'] is not None:
                merged['reading'] = entry['reading']

            # English: prefer non-None, or prefer longer/more complete
            if merged['english'] is None and entry['english'] is not None:
                merged['english'] = entry['english']
            elif merged['english'] and entry['english']:
                # If both have English, prefer the longer one
                if len(entry['english']) > len(merged['english']):
                    merged['english'] = entry['english']

            # Entry type: prefer more specific (sentence > phrase > vocab)
            type_priority = {'sentence': 3, 'phrase': 2, 'vocab': 1, 'note': 0}
            if type_priority.get(entry['entry_type'], 0) > type_priority.get(merged['entry_type'], 0):
                merged['entry_type'] = entry['entry_type']

            # Tags: combine unique
            merged['tags'] = list(set(merged['tags'] + entry['tags']))

            # Grammar patterns: combine unique
            merged['grammar_patterns'] = list(set(merged['grammar_patterns'] + entry['grammar_patterns']))

            # JLPT level: prefer non-None
            if merged['jlpt_level'] is None and entry['jlpt_level'] is not None:
                merged['jlpt_level'] = entry['jlpt_level']

            # Context note: prefer non-None
            if merged['context_note'] is None and entry['context_note'] is not None:
                merged['context_note'] = entry['context_note']

        # Use earliest lesson date
        if all_dates:
            merged['lesson_date'] = min(all_dates)

        # Remove 'general' tag if there are more specific tags
        if len(merged['tags']) > 1 and 'general' in merged['tags']:
            merged['tags'].remove('general')

        return merged

    def create_output(self, entries, stats, output_path):
        """Create the final JSON output"""
        data = {
            'metadata': {
                'version': '2.0',
                'created_date': datetime.now().strftime('%Y-%m-%d'),
                'total_entries': len(entries),
                'entries_with_reading': stats['with_reading'],
                'entries_with_english': stats['with_english'],
                'entries_missing_reading': stats['entries'] - stats['with_reading'],
                'entries_missing_english': stats['entries'] - stats['with_english'],
                'lesson_count': len(stats['lesson_dates']),
                'source': 'Parsed from 日本語のレッスンノート.txt'
            },
            'entries': entries
        }

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"\nSaved to {output_path}")
        return data


def main():
    parser = argparse.ArgumentParser(description='Parse Japanese lesson notes to JSON')
    parser.add_argument('--input', '-i',
                        default='original_working_files/日本語のレッスンのノート App Edit.txt',
                        help='Input notes file (.txt)')
    parser.add_argument('--output', '-o',
                        default='japanese_data.json',
                        help='Output JSON file')

    args = parser.parse_args()

    print("=" * 60)
    print("Japanese Notes Parser")
    print("=" * 60)

    parser = JapaneseNotesParser()
    entries, stats = parser.parse_file(args.input)

    print("\n" + "=" * 60)
    print("PARSING STATISTICS")
    print("=" * 60)

    print(f"\nRaw entries:   {stats['raw_entries']:,}")
    print(f"Duplicates:    {stats['duplicates_merged']:,} merged")
    print(f"Final entries: {stats['entries']:,}")
    print(f"With reading:  {stats['with_reading']:,} ({100*stats['with_reading']/stats['entries']:.1f}%)")
    print(f"With English:  {stats['with_english']:,} ({100*stats['with_english']/stats['entries']:.1f}%)")
    print(f"Lesson dates:  {len(stats['lesson_dates'])}")

    print("\nEntry Types:")
    for entry_type, count in sorted(stats['entry_types'].items(), key=lambda x: -x[1]):
        print(f"  {entry_type}: {count:,}")

    print("\nTop Scenarios:")
    for scenario, count in sorted(stats['scenarios'].items(), key=lambda x: -x[1])[:10]:
        print(f"  {scenario}: {count:,}")

    parser.create_output(entries, stats, args.output)

    print("\n" + "=" * 60)
    print("COMPLETE")
    print("=" * 60)


if __name__ == '__main__':
    main()
