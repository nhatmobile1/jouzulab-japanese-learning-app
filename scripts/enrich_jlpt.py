#!/usr/bin/env python3
"""
JLPT Level Enrichment via Jisho.org API
Looks up JLPT levels for entries that don't have one.

Usage:
    python enrich_jlpt.py --input japanese_data.json --output japanese_data.json
"""

import json
import re
import time
import argparse
import urllib.request
import urllib.parse
import ssl
from collections import Counter

# Create SSL context that doesn't verify certificates (for development)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE


def fetch_jlpt_from_jisho(word):
    """
    Query Jisho.org API for a word's JLPT level.
    Returns: 'N5', 'N4', 'N3', 'N2', 'N1', or None
    """
    # Clean the word - extract first meaningful part
    # Remove particles and get the main word
    clean_word = word.strip()

    # For phrases, try to extract the main verb/noun
    # Split on common particles and take first substantial part
    if len(clean_word) > 10:
        # Try to find a verb or noun
        parts = re.split(r'[をがはにでとも、\s]', clean_word)
        for part in parts:
            if len(part) >= 2:
                clean_word = part
                break

    try:
        encoded_word = urllib.parse.quote(clean_word)
        url = f"https://jisho.org/api/v1/search/words?keyword={encoded_word}"

        req = urllib.request.Request(url, headers={
            'User-Agent': 'JouzuLab Japanese Learning App/1.0'
        })

        with urllib.request.urlopen(req, timeout=10, context=ssl_context) as response:
            data = json.loads(response.read().decode('utf-8'))

        if data.get('data'):
            for result in data['data']:
                # Check if this result matches our word
                for japanese in result.get('japanese', []):
                    word_match = japanese.get('word', '') == clean_word
                    reading_match = japanese.get('reading', '') == clean_word

                    if word_match or reading_match or len(data['data']) == 1:
                        # Look for JLPT tag
                        tags = result.get('tags', [])
                        for tag in tags:
                            if tag.startswith('jlpt-n'):
                                level = tag.replace('jlpt-n', 'N')
                                return level.upper()

                        # Also check jlpt field
                        jlpt = result.get('jlpt', [])
                        if jlpt:
                            level = jlpt[0].replace('jlpt-n', 'N')
                            return level.upper()

        return None

    except Exception as e:
        print(f"  Error fetching '{clean_word}': {e}")
        return None


def extract_base_word(japanese):
    """Extract the base word from a phrase for JLPT lookup"""
    # Remove common verb endings to get dictionary form
    text = japanese.strip()

    # If it's short, use as-is
    if len(text) <= 6:
        return text

    # Try to extract the main word (first noun or verb)
    # Split on particles
    parts = re.split(r'[をがはにでとも、\s]', text)
    parts = [p for p in parts if len(p) >= 2]

    if parts:
        return parts[0]

    return text[:6]  # Just use first 6 chars as fallback


def main():
    parser = argparse.ArgumentParser(description='Enrich JLPT levels via Jisho API')
    parser.add_argument('--input', '-i', default='japanese_data.json',
                        help='Input JSON file')
    parser.add_argument('--output', '-o', default='japanese_data.json',
                        help='Output JSON file')
    parser.add_argument('--limit', '-l', type=int, default=0,
                        help='Limit number of lookups (0 = all)')
    parser.add_argument('--delay', '-d', type=float, default=0.5,
                        help='Delay between API calls in seconds')

    args = parser.parse_args()

    print("=" * 60)
    print("JLPT Enrichment via Jisho.org")
    print("=" * 60)

    # Load data
    with open(args.input, 'r', encoding='utf-8') as f:
        data = json.load(f)

    entries = data['entries']

    # Find entries without JLPT level
    needs_jlpt = [e for e in entries if e.get('jlpt_level') is None]

    print(f"\nTotal entries: {len(entries)}")
    print(f"Already have JLPT: {len(entries) - len(needs_jlpt)}")
    print(f"Need JLPT lookup: {len(needs_jlpt)}")

    if args.limit > 0:
        needs_jlpt = needs_jlpt[:args.limit]
        print(f"Limited to: {len(needs_jlpt)}")

    print(f"\nStarting lookups (delay: {args.delay}s between calls)...")
    print("-" * 60)

    found = 0
    not_found = 0
    errors = 0
    jlpt_counts = Counter()

    # Create a lookup cache to avoid duplicate API calls
    cache = {}

    for i, entry in enumerate(needs_jlpt, 1):
        japanese = entry['japanese']
        base_word = extract_base_word(japanese)

        # Check cache first
        if base_word in cache:
            level = cache[base_word]
        else:
            # Query Jisho
            level = fetch_jlpt_from_jisho(base_word)
            cache[base_word] = level

            # Rate limiting
            time.sleep(args.delay)

        if level:
            entry['jlpt_level'] = level
            found += 1
            jlpt_counts[level] += 1
            print(f"[{i}/{len(needs_jlpt)}] {base_word} -> {level}")
        else:
            not_found += 1
            if i <= 20 or i % 100 == 0:  # Only print first 20 and every 100th
                print(f"[{i}/{len(needs_jlpt)}] {base_word} -> not found")

        # Progress update every 100 entries
        if i % 100 == 0:
            print(f"\n--- Progress: {i}/{len(needs_jlpt)} ({100*i/len(needs_jlpt):.1f}%) ---")
            print(f"    Found: {found}, Not found: {not_found}")
            print()

    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)

    print(f"\nLookups completed: {len(needs_jlpt)}")
    print(f"JLPT levels found: {found}")
    print(f"Not found: {not_found}")

    print("\nNew JLPT distribution:")
    for level in ['N5', 'N4', 'N3', 'N2', 'N1']:
        count = jlpt_counts.get(level, 0)
        print(f"  {level}: {count}")

    # Update metadata
    total_with_jlpt = sum(1 for e in entries if e.get('jlpt_level'))
    data['metadata']['entries_with_jlpt'] = total_with_jlpt
    data['metadata']['jlpt_enriched_date'] = time.strftime('%Y-%m-%d')

    # Save output
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nSaved to {args.output}")
    print(f"Total entries with JLPT: {total_with_jlpt}/{len(entries)} ({100*total_with_jlpt/len(entries):.1f}%)")


if __name__ == '__main__':
    main()
