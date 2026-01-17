#!/usr/bin/env python3
"""
Convert Genki vocabulary data to JouzuLab deck JSON format.

Usage:
    python3 create_genki_deck.py input.csv --output genki_1_deck.json --book 1
    python3 create_genki_deck.py input.tsv --output genki_2_deck.json --book 2

Input format (CSV/TSV with headers):
    Japanese, Reading, English translation, Lesson number
    あのう, あのう, I am...., 会G

Or tab-separated without headers - use --no-header flag.
"""

import argparse
import csv
import json
import re
import sys
from pathlib import Path
from datetime import datetime


def detect_delimiter(filepath: Path) -> str:
    """Auto-detect CSV delimiter (comma or tab)."""
    with open(filepath, 'r', encoding='utf-8') as f:
        first_line = f.readline()
        if '\t' in first_line:
            return '\t'
        return ','


def parse_lesson_number(lesson_str: str) -> tuple[str, int | None]:
    """
    Parse lesson string like '会G', 'L1', '第3課' into normalized form.
    Returns (normalized_string, lesson_number_if_available)
    """
    if not lesson_str:
        return ('', None)

    lesson_str = lesson_str.strip()

    # Try to extract a number
    match = re.search(r'(\d+)', lesson_str)
    lesson_num = int(match.group(1)) if match else None

    return (lesson_str, lesson_num)


def detect_entry_type(japanese: str) -> str:
    """Detect if entry is vocab, phrase, or sentence."""
    # If it contains sentence-ending punctuation
    if '。' in japanese or '？' in japanese or '?' in japanese:
        return 'sentence'
    # If it contains spaces or is long, likely a phrase
    if ' ' in japanese or '　' in japanese or len(japanese) > 10:
        return 'phrase'
    return 'vocab'


def create_deck(
    input_path: Path,
    output_path: Path,
    book_number: int = 1,
    deck_name: str | None = None,
    deck_id: str | None = None,
    has_header: bool = True,
    jlpt_level: str | None = None
):
    """
    Create a JouzuLab deck JSON from CSV/TSV input.

    Args:
        input_path: Path to input CSV/TSV file
        output_path: Path to output JSON file
        book_number: Genki book number (1 or 2)
        deck_name: Custom deck name (default: "Genki I/II Vocabulary")
        deck_id: Custom deck ID (default: "genki-1" or "genki-2")
        has_header: Whether input file has header row
        jlpt_level: Override JLPT level (default: N5 for book 1, N4 for book 2)
    """

    # Set defaults based on book number
    if deck_name is None:
        deck_name = f"Genki {'I' if book_number == 1 else 'II'} Vocabulary"

    if deck_id is None:
        deck_id = f"genki-{book_number}"

    if jlpt_level is None:
        jlpt_level = "N5" if book_number == 1 else "N4"

    # Detect delimiter
    delimiter = detect_delimiter(input_path)

    entries = []

    with open(input_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=delimiter)

        # Skip header if present
        if has_header:
            next(reader, None)

        for row_num, row in enumerate(reader, start=1):
            # Skip empty rows
            if not row or not any(row):
                continue

            # Parse columns - handle varying column counts
            japanese = row[0].strip() if len(row) > 0 else ''
            reading = row[1].strip() if len(row) > 1 else ''
            english = row[2].strip() if len(row) > 2 else ''
            lesson_raw = row[3].strip() if len(row) > 3 else ''

            # Skip if no Japanese text
            if not japanese:
                continue

            # Parse lesson
            lesson, lesson_num = parse_lesson_number(lesson_raw)

            # Build tags
            tags = ['genki', f'genki-{book_number}']
            if lesson:
                tags.append(f'lesson-{lesson}')

            # Create entry
            entry = {
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

    # Build deck structure
    deck = {
        'metadata': {
            'id': deck_id,
            'name': deck_name,
            'description': f'Vocabulary from Genki {"I" if book_number == 1 else "II"} textbook ({len(entries)} entries)',
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
    print(f"  - Entries: {len(entries)}")
    print(f"  - JLPT Level: {jlpt_level}")
    print(f"  - Output: {output_path}")

    return deck


def main():
    parser = argparse.ArgumentParser(
        description='Convert Genki vocabulary data to JouzuLab deck JSON format.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python3 create_genki_deck.py genki1_vocab.csv --output genki_1.json --book 1
    python3 create_genki_deck.py genki2_vocab.tsv --output genki_2.json --book 2
    python3 create_genki_deck.py data.csv --output custom.json --name "My Deck" --id my-deck

Input format (CSV or TSV):
    Japanese, Reading, English translation, Lesson number
    あのう, あのう, I am...., 会G
    なん/なに, なん/なに, Thank you., 会G
        """
    )

    parser.add_argument('input', type=Path, help='Input CSV/TSV file')
    parser.add_argument('--output', '-o', type=Path, required=True, help='Output JSON file')
    parser.add_argument('--book', '-b', type=int, choices=[1, 2], default=1,
                        help='Genki book number (1 or 2, affects JLPT level)')
    parser.add_argument('--name', type=str, help='Custom deck name')
    parser.add_argument('--id', type=str, help='Custom deck ID')
    parser.add_argument('--jlpt', type=str, choices=['N5', 'N4', 'N3', 'N2', 'N1'],
                        help='Override JLPT level')
    parser.add_argument('--no-header', action='store_true',
                        help='Input file has no header row')

    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    create_deck(
        input_path=args.input,
        output_path=args.output,
        book_number=args.book,
        deck_name=args.name,
        deck_id=args.id,
        has_header=not args.no_header,
        jlpt_level=args.jlpt
    )


if __name__ == '__main__':
    main()
