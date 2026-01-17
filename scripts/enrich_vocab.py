#!/usr/bin/env python3
"""
Vocab Enrichment via Jisho.org API
Looks up missing readings and English translations for vocab entries.

Usage:
    python enrich_vocab.py --input ../data/japanese_data.json
    python enrich_vocab.py --input ../data/japanese_data.json --limit 50  # Test with 50 entries
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


def fetch_from_jisho(word):
    """
    Query Jisho.org API for a word's reading and meaning.
    Returns: {
        'reading': str or None,
        'english': str or None,
        'jlpt_level': str or None
    }
    """
    result = {'reading': None, 'english': None, 'jlpt_level': None}

    # Clean the word
    clean_word = word.strip()

    # Remove trailing particles or spaces
    clean_word = re.sub(r'[\s　]+$', '', clean_word)

    try:
        encoded_word = urllib.parse.quote(clean_word)
        url = f"https://jisho.org/api/v1/search/words?keyword={encoded_word}"

        req = urllib.request.Request(url, headers={
            'User-Agent': 'JouzuLab Japanese Learning App/1.0'
        })

        with urllib.request.urlopen(req, timeout=10, context=ssl_context) as response:
            data = json.loads(response.read().decode('utf-8'))

        if not data.get('data'):
            return result

        # Find the best matching result
        best_match = None
        for entry in data['data']:
            for japanese in entry.get('japanese', []):
                entry_word = japanese.get('word', '')
                entry_reading = japanese.get('reading', '')

                # Exact match on word or reading
                if entry_word == clean_word or entry_reading == clean_word:
                    best_match = (entry, japanese)
                    break

            if best_match:
                break

        # If no exact match, use first result if query is short (likely a single word)
        if not best_match and len(clean_word) <= 6 and data['data']:
            first_entry = data['data'][0]
            if first_entry.get('japanese'):
                best_match = (first_entry, first_entry['japanese'][0])

        if not best_match:
            return result

        entry, japanese = best_match

        # Extract reading
        result['reading'] = japanese.get('reading')

        # Extract English meaning (first sense, first meaning)
        senses = entry.get('senses', [])
        if senses:
            english_defs = senses[0].get('english_definitions', [])
            if english_defs:
                # Join first few definitions
                result['english'] = '; '.join(english_defs[:3])

        # Extract JLPT level
        tags = entry.get('tags', [])
        for tag in tags:
            if tag.startswith('jlpt-n'):
                result['jlpt_level'] = tag.replace('jlpt-n', 'N').upper()
                break

        # Also check jlpt field
        if not result['jlpt_level']:
            jlpt = entry.get('jlpt', [])
            if jlpt:
                result['jlpt_level'] = jlpt[0].replace('jlpt-n', 'N').upper()

        return result

    except Exception as e:
        print(f"  Error fetching '{clean_word}': {e}")
        return result


def main():
    parser = argparse.ArgumentParser(description='Enrich vocab entries via Jisho API')
    parser.add_argument('--input', '-i', default='../data/japanese_data.json',
                        help='Input JSON file')
    parser.add_argument('--output', '-o', default=None,
                        help='Output JSON file (default: same as input)')
    parser.add_argument('--limit', '-l', type=int, default=0,
                        help='Limit number of lookups (0 = all)')
    parser.add_argument('--delay', '-d', type=float, default=0.3,
                        help='Delay between API calls in seconds')
    parser.add_argument('--vocab-only', action='store_true', default=True,
                        help='Only process vocab type entries (default: True)')
    parser.add_argument('--all-types', action='store_true',
                        help='Process all entry types, not just vocab')

    args = parser.parse_args()

    if args.output is None:
        args.output = args.input

    if args.all_types:
        args.vocab_only = False

    print("=" * 60)
    print("Vocab Enrichment via Jisho.org")
    print("=" * 60)

    # Load data
    with open(args.input, 'r', encoding='utf-8') as f:
        data = json.load(f)

    entries = data['entries']

    # Find entries that need enrichment
    needs_enrichment = []
    for entry in entries:
        # Skip if not vocab type (unless all-types is set)
        if args.vocab_only and entry.get('entry_type') != 'vocab':
            continue

        # Check if missing reading or english
        needs_reading = entry.get('reading') is None
        needs_english = entry.get('english') is None
        needs_jlpt = entry.get('jlpt_level') is None

        if needs_reading or needs_english:
            needs_enrichment.append({
                'entry': entry,
                'needs_reading': needs_reading,
                'needs_english': needs_english,
                'needs_jlpt': needs_jlpt
            })

    print(f"\nTotal entries: {len(entries)}")
    print(f"Vocab entries: {sum(1 for e in entries if e.get('entry_type') == 'vocab')}")
    print(f"Need enrichment: {len(needs_enrichment)}")
    print(f"  - Missing reading: {sum(1 for e in needs_enrichment if e['needs_reading'])}")
    print(f"  - Missing English: {sum(1 for e in needs_enrichment if e['needs_english'])}")

    if args.limit > 0:
        needs_enrichment = needs_enrichment[:args.limit]
        print(f"\nLimited to: {len(needs_enrichment)} entries")

    if not needs_enrichment:
        print("\nNo entries need enrichment!")
        return

    print(f"\nStarting lookups (delay: {args.delay}s between calls)...")
    print("-" * 60)

    stats = {
        'readings_added': 0,
        'english_added': 0,
        'jlpt_added': 0,
        'not_found': 0,
        'errors': 0
    }

    # Cache to avoid duplicate API calls
    cache = {}

    for i, item in enumerate(needs_enrichment, 1):
        entry = item['entry']
        japanese = entry['japanese']

        # Check cache first
        if japanese in cache:
            jisho_data = cache[japanese]
        else:
            # Query Jisho
            jisho_data = fetch_from_jisho(japanese)
            cache[japanese] = jisho_data

            # Rate limiting
            time.sleep(args.delay)

        # Update entry with found data
        updated = False
        updates = []

        if item['needs_reading'] and jisho_data['reading']:
            entry['reading'] = jisho_data['reading']
            stats['readings_added'] += 1
            updates.append(f"reading={jisho_data['reading']}")
            updated = True

        if item['needs_english'] and jisho_data['english']:
            entry['english'] = jisho_data['english']
            stats['english_added'] += 1
            updates.append(f"english={jisho_data['english'][:30]}...")
            updated = True

        if item['needs_jlpt'] and jisho_data['jlpt_level']:
            entry['jlpt_level'] = jisho_data['jlpt_level']
            stats['jlpt_added'] += 1
            updates.append(f"jlpt={jisho_data['jlpt_level']}")
            updated = True

        if updated:
            print(f"[{i}/{len(needs_enrichment)}] {japanese} -> {', '.join(updates)}")
        else:
            stats['not_found'] += 1
            if i <= 20 or i % 50 == 0:
                print(f"[{i}/{len(needs_enrichment)}] {japanese} -> not found")

        # Progress update every 100 entries
        if i % 100 == 0:
            print(f"\n--- Progress: {i}/{len(needs_enrichment)} ({100*i/len(needs_enrichment):.1f}%) ---")
            print(f"    Readings: +{stats['readings_added']}, English: +{stats['english_added']}, JLPT: +{stats['jlpt_added']}")
            print()

    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)

    print(f"\nLookups completed: {len(needs_enrichment)}")
    print(f"Readings added: {stats['readings_added']}")
    print(f"English added: {stats['english_added']}")
    print(f"JLPT levels added: {stats['jlpt_added']}")
    print(f"Not found: {stats['not_found']}")

    # Update metadata
    data['metadata']['entries_with_reading'] = sum(1 for e in entries if e.get('reading'))
    data['metadata']['entries_with_english'] = sum(1 for e in entries if e.get('english'))
    data['metadata']['entries_missing_reading'] = sum(1 for e in entries if not e.get('reading'))
    data['metadata']['entries_missing_english'] = sum(1 for e in entries if not e.get('english'))
    data['metadata']['vocab_enriched_date'] = time.strftime('%Y-%m-%d')

    # Save output
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nSaved to {args.output}")

    total = len(entries)
    with_reading = data['metadata']['entries_with_reading']
    with_english = data['metadata']['entries_with_english']
    print(f"\nFinal stats:")
    print(f"  With reading: {with_reading}/{total} ({100*with_reading/total:.1f}%)")
    print(f"  With English: {with_english}/{total} ({100*with_english/total:.1f}%)")


if __name__ == '__main__':
    main()
