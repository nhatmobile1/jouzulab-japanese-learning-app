#!/usr/bin/env python3
"""
Convert QUARTET vocabulary Excel data to JouzuLab deck JSON format.

Usage:
    python3 create_quartet_deck.py QUARTET_word_index.xlsx --output quartet_deck.json

Input format (Excel with columns):
    Reading, Japanese, English translation, Lesson reference
    かみ, 髪, hair, L1-読1

QUARTET is an intermediate-level textbook, typically N3-N2 level.
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from datetime import datetime


def generate_content_id(deck_id: str, japanese: str, reading: str | None) -> str:
    """
    Generate a stable ID based on content, not position.
    Uses hash of deck_id + japanese + reading to ensure uniqueness.
    """
    # Combine fields for hashing (use empty string for None reading)
    content = f"{deck_id}:{japanese}:{reading or ''}"
    # Create a short hash (first 12 chars of SHA-256)
    hash_hex = hashlib.sha256(content.encode('utf-8')).hexdigest()[:12]
    return f"{deck_id}_{hash_hex}"

try:
    import openpyxl
except ImportError:
    print("Error: openpyxl is required. Install with: pip3 install openpyxl", file=sys.stderr)
    sys.exit(1)


def detect_entry_type(japanese: str) -> str:
    """Detect if entry is vocab, phrase, or sentence."""
    # If it contains sentence-ending punctuation
    if '。' in japanese or '？' in japanese or '?' in japanese:
        return 'sentence'
    # If it contains spaces or is long, likely a phrase
    if ' ' in japanese or '　' in japanese or len(japanese) > 10:
        return 'phrase'
    return 'vocab'


def parse_lesson_reference(lesson_ref: str) -> tuple[str, int | None]:
    """
    Parse lesson reference like 'L1-読1', 'L10-読2' into normalized form.
    Returns (normalized_string, lesson_number)
    """
    if not lesson_ref:
        return ('', None)

    lesson_ref = lesson_ref.strip()

    # Extract lesson number
    match = re.search(r'L(\d+)', lesson_ref)
    lesson_num = int(match.group(1)) if match else None

    return (lesson_ref, lesson_num)


def clean_reading(reading: str) -> str:
    """Clean up reading text - remove any annotations like (する)."""
    if not reading:
        return ''

    # Handle readings like 'しょうかい（する）' -> 'しょうかい'
    # Keep the base reading, remove verb annotations
    reading = re.sub(r'（[^）]*）', '', reading)
    reading = re.sub(r'\([^)]*\)', '', reading)

    return reading.strip()


def create_quartet_deck(
    input_path: Path,
    output_path: Path,
    volume: int = 1,
    deck_name: str | None = None,
    deck_id: str | None = None,
    jlpt_level: str | None = None
):
    """
    Create a JouzuLab deck JSON from QUARTET Excel file.

    Args:
        input_path: Path to input Excel file
        output_path: Path to output JSON file
        volume: QUARTET volume number (1 or 2)
        deck_name: Custom deck name
        deck_id: Custom deck ID
        jlpt_level: Override JLPT level (default: N3 for vol 1, N2 for vol 2)
    """

    # Set defaults based on volume
    if deck_name is None:
        deck_name = f"QUARTET {'I' if volume == 1 else 'II'} Vocabulary"

    if deck_id is None:
        deck_id = f"quartet-{volume}"

    if jlpt_level is None:
        # QUARTET is intermediate level: Vol 1 is roughly N3, Vol 2 is N2
        jlpt_level = "N3" if volume == 1 else "N2"

    # Load workbook
    wb = openpyxl.load_workbook(input_path)
    sheet = wb.active

    entries = []
    lesson_counts = {}

    # Process rows (skip header)
    for row in sheet.iter_rows(min_row=2, values_only=True):
        reading_raw, japanese, english, lesson_ref = row

        # Skip empty rows
        if not japanese:
            continue

        # Clean up data
        japanese = str(japanese).strip()
        reading = clean_reading(str(reading_raw)) if reading_raw else ''
        english = str(english).strip() if english else ''
        lesson_ref = str(lesson_ref).strip() if lesson_ref else ''

        # Parse lesson
        lesson, lesson_num = parse_lesson_reference(lesson_ref)

        # Track lesson counts
        if lesson:
            lesson_counts[lesson] = lesson_counts.get(lesson, 0) + 1

        # Build tags
        tags = ['quartet', f'quartet-{volume}']
        if lesson_num:
            tags.append(f'lesson-{lesson_num}')

        # Generate content-based ID
        entry_id = generate_content_id(deck_id, japanese, reading if reading else None)

        # Create entry
        entry = {
            'id': entry_id,
            'japanese': japanese,
            'reading': reading if reading else None,
            'english': english if english else None,
            'entry_type': detect_entry_type(japanese),
            'jlpt_level': jlpt_level,
            'lesson': lesson if lesson else None,
            'tags': tags
        }

        # Remove None values for cleaner JSON
        entry = {k: v for k, v in entry.items() if v is not None}

        entries.append(entry)

    # Count complete entries (have all three: japanese, reading, english)
    complete_count = sum(1 for e in entries
                        if e.get('reading') and e.get('english'))

    # Build deck structure
    deck = {
        'metadata': {
            'id': deck_id,
            'name': deck_name,
            'description': f'Vocabulary from QUARTET {"I" if volume == 1 else "II"} textbook ({len(entries)} entries)',
            'author': 'JouzuLab',
            'version': '1.0',
            'created_date': datetime.now().strftime('%Y-%m-%d'),
            'total_entries': len(entries)
        },
        'entries': entries
    }

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(deck, f, ensure_ascii=False, indent=2)

    print(f"✓ Created deck: {deck_name}")
    print(f"  - Total entries: {len(entries)}")
    print(f"  - Complete entries (with reading + English): {complete_count}")
    print(f"  - JLPT Level: {jlpt_level}")
    print(f"  - Lessons: {len(lesson_counts)}")
    print(f"  - Output: {output_path}")
    print()
    print("Entries per lesson:")
    for lesson in sorted(lesson_counts.keys(), key=lambda x: (int(re.search(r'\d+', x).group()), x)):
        print(f"  {lesson}: {lesson_counts[lesson]}")

    return deck


def main():
    parser = argparse.ArgumentParser(
        description='Convert QUARTET vocabulary Excel data to JouzuLab deck JSON format.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python3 create_quartet_deck.py QUARTET_word_index.xlsx --output quartet_1.json
    python3 create_quartet_deck.py QUARTET_vol2.xlsx --output quartet_2.json --volume 2

Input format (Excel):
    Reading | Japanese | English translation | Lesson reference
    かみ    | 髪       | hair                | L1-読1
        """
    )

    parser.add_argument('input', type=Path, help='Input Excel file (.xlsx)')
    parser.add_argument('--output', '-o', type=Path, required=True, help='Output JSON file')
    parser.add_argument('--volume', '-v', type=int, choices=[1, 2], default=1,
                        help='QUARTET volume number (1 or 2, affects JLPT level)')
    parser.add_argument('--name', type=str, help='Custom deck name')
    parser.add_argument('--id', type=str, help='Custom deck ID')
    parser.add_argument('--jlpt', type=str, choices=['N5', 'N4', 'N3', 'N2', 'N1'],
                        help='Override JLPT level')

    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    create_quartet_deck(
        input_path=args.input,
        output_path=args.output,
        volume=args.volume,
        deck_name=args.name,
        deck_id=args.id,
        jlpt_level=args.jlpt
    )


if __name__ == '__main__':
    main()
