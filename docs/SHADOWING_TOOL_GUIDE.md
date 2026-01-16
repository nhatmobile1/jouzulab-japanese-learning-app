# Japanese Shadowing Practice Tool Guide

## Overview

This tool helps you create shadowing practice materials from Japanese movies, anime, dramas, or any audio/video content. It automatically:

1. **Transcribes** Japanese audio using OpenAI Whisper
2. **Splits** into individual segments (sentences/phrases)
3. **Generates 3 speed versions** for each segment:
   - 🐢 **Slow (0.75x)** - Learn new phrases, catch every syllable
   - 🚶 **Normal (1.0x)** - Original native speed
   - 🏃 **Fast (1.25x)** - Challenge mode, prepare for real conversations
4. **Creates a practice interface** (HTML player you can use immediately)
5. **Exports structured JSON** for integration with your learning app

---

## Installation

### Step 1: Install Python Dependencies

```bash
pip install openai-whisper pydub ffmpeg-python
```

### Step 2: Install FFmpeg

**Mac:**
```bash
brew install ffmpeg
```

**Windows:**
Download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH

**Linux:**
```bash
sudo apt install ffmpeg
```

### Step 3: Verify Installation

```bash
python shadowing_tool.py --help
```

---

## Usage

### Basic Usage

```bash
# Process a video file
python shadowing_tool.py movie_scene.mp4

# Process an audio file
python shadowing_tool.py podcast_episode.mp3
```

### With Options

```bash
# Specify output directory
python shadowing_tool.py anime_clip.mp4 --output-dir ./practice/episode1

# Use larger model for better accuracy (recommended for Japanese)
python shadowing_tool.py drama.mp4 --model large

# Add a title for the content
python shadowing_tool.py scene.mp4 --title "Terrace House S1E3"
```

### Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output-dir` | `-o` | Where to save practice files |
| `--model` | `-m` | Whisper model: tiny/base/small/medium/large |
| `--title` | `-t` | Name for the source content |

### Whisper Model Selection

| Model | Speed | Accuracy | Recommended For |
|-------|-------|----------|-----------------|
| `tiny` | ⚡⚡⚡⚡ | ⭐ | Quick tests |
| `base` | ⚡⚡⚡ | ⭐⭐ | Default, good balance |
| `small` | ⚡⚡ | ⭐⭐⭐ | Better accuracy |
| `medium` | ⚡ | ⭐⭐⭐⭐ | Recommended for Japanese |
| `large` | 🐌 | ⭐⭐⭐⭐⭐ | Best accuracy, slow |

**For Japanese content**, use `medium` or `large` for best results:
```bash
python shadowing_tool.py video.mp4 --model large
```

---

## Output Structure

After processing, you'll get:

```
shadowing_practice/
├── practice_data.json      # Structured data for your app
├── practice.html           # Browser-based practice player
├── extracted_audio.mp3     # Full audio (if input was video)
├── segment_0001/
│   ├── segment_0001_slow.mp3
│   ├── segment_0001_normal.mp3
│   └── segment_0001_fast.mp3
├── segment_0002/
│   ├── segment_0002_slow.mp3
│   ├── segment_0002_normal.mp3
│   └── segment_0002_fast.mp3
└── ... (more segments)
```

---

## Practice Data Format

Each segment in `practice_data.json`:

```json
{
  "id": "segment_0001",
  "index": 1,
  "japanese": "すみません、注文をお願いします",
  "english": null,
  "start_time": 0.0,
  "end_time": 2.3,
  "duration_seconds": 2.3,
  "audio": {
    "slow": "segment_0001_slow.mp3",
    "normal": "segment_0001_normal.mp3",
    "fast": "segment_0001_fast.mp3"
  },
  "scenarios": [],
  "formality": null,
  "notes": "",
  "mastered": false
}
```

### Fields to Fill Manually

After processing, edit `practice_data.json` to add:

- **english**: Your translation
- **scenarios**: Tags like "restaurant", "shopping", etc.
- **formality**: "casual", "polite", or "formal"
- **notes**: Context, usage tips, tutor explanations
- **mastered**: Track your progress

---

## How to Practice (Shadowing Method)

### Step 1: Open the Practice Player

```bash
open shadowing_practice/practice.html  # Mac
start shadowing_practice/practice.html # Windows
```

### Step 2: Follow the Shadowing Progression

**Phase 1: Listening (Slow)**
1. Click 🐢 **Slow (0.75x)**
2. Listen carefully to each syllable
3. Read along with the Japanese text
4. Repeat 3-5 times until you can hear every sound

**Phase 2: Shadowing (Normal)**
1. Click 🚶 **Normal (1.0x)**
2. Speak along WITH the audio (not after)
3. Match the rhythm and intonation
4. Use 🔁 **Loop** to repeat until comfortable

**Phase 3: Challenge (Fast)**
1. Click 🏃 **Fast (1.25x)**
2. Try to keep up with the faster speed
3. This prepares you for real native conversations
4. Don't worry about perfection - build speed

### Step 3: Track Progress

Mark segments as `"mastered": true` in the JSON when you can:
- Shadow at normal speed without hesitation
- Understand the meaning without reading English
- Use the phrase naturally in conversation

---

## Integration with Your Learning App

### Import into Your App Data Structure

The segments follow a similar structure to your italki notes. You can merge them:

```python
import json

# Load your existing data
with open('parsed_japanese_notes.json', 'r') as f:
    notes_data = json.load(f)

# Load shadowing practice data
with open('shadowing_practice/practice_data.json', 'r') as f:
    shadowing_data = json.load(f)

# Add media source flag
for segment in shadowing_data['segments']:
    segment['source_type'] = 'media'
    segment['source'] = shadowing_data['metadata']['source']

# Merge into your main database
# ... your merge logic here
```

### Recommended Workflow

1. **Capture**: Record/download Japanese content
2. **Process**: Run shadowing_tool.py
3. **Curate**: Add translations, tags, notes
4. **Practice**: Use HTML player for shadowing
5. **Integrate**: Import best segments into your app
6. **Review**: Use your app for spaced repetition

---

## Tips for Best Results

### Content Selection

**Good sources for shadowing:**
- Slice-of-life anime (natural conversation)
- Japanese dramas (realistic dialogue)
- Terrace House (unscripted, natural)
- YouTube vlogs (casual Japanese)
- NHK News (clear, formal Japanese)
- Podcasts (conversational topics)

**Avoid for beginners:**
- Fast-paced action anime (yelling, sound effects)
- Historical dramas (archaic language)
- Heavy dialect content (until you're ready)

### Recording Tips

**From streaming services:**
1. Use screen recording with audio
2. Record just the Japanese audio track
3. Clip to 1-5 minute segments (easier to process)

**Tools:**
- **Mac**: QuickTime Player, OBS
- **Windows**: OBS, Xbox Game Bar
- **Audio only**: Audacity

### Processing Tips

1. **Start small**: Process 1-2 minute clips first
2. **Use large model**: `--model large` for Japanese
3. **Review transcripts**: Whisper isn't perfect - correct errors
4. **Add context**: Your translations are better than machine translations

---

## Troubleshooting

### "No module named 'whisper'"
```bash
pip install openai-whisper
```

### "FFmpeg not found"
Install FFmpeg (see Installation section)

### Transcription is inaccurate
- Use `--model large` for better accuracy
- Ensure clear audio without background music
- Check that the audio is actually Japanese

### Audio speeds sound weird
The speed adjustment uses a simple technique. For production quality:
- Consider using `rubberband` library
- Or generate with proper pitch correction

### Out of memory with large model
- Use `--model medium` instead
- Or process shorter clips

---

## Advanced: Customization

### Adjust Speed Settings

Edit `shadowing_tool.py` to change speeds:

```python
self.speeds = {
    "slow": 0.6,      # Even slower
    "normal": 1.0,
    "fast": 1.5       # Even faster
}
```

### Add More Speed Levels

```python
self.speeds = {
    "very_slow": 0.5,
    "slow": 0.75,
    "normal": 1.0,
    "fast": 1.25,
    "very_fast": 1.5
}
```

### Custom HTML Template

Modify the `generate_practice_html()` function to customize the player interface.

---

## Example Workflow

### Processing a Terrace House Scene

```bash
# 1. Record a 2-minute scene with interesting conversation
# Save as: terrace_house_dinner.mp4

# 2. Process with large model for accuracy
python shadowing_tool.py terrace_house_dinner.mp4 \
    --output-dir ./practice/terrace_house_ep3 \
    --model large \
    --title "Terrace House - Dinner Conversation"

# 3. Open practice player
open ./practice/terrace_house_ep3/practice.html

# 4. Edit practice_data.json to add translations
# 5. Practice shadowing at all three speeds
# 6. Import good segments into your learning app
```

---

## Combining with Your italki Notes

Your italki notes provide:
- ✅ Structured grammar explanations
- ✅ Tutor-verified translations
- ✅ Learning progression

Media shadowing provides:
- ✅ Native speed audio
- ✅ Natural intonation
- ✅ Real conversational patterns
- ✅ Listening practice

**Together they cover all four skills:**
- Reading: Your notes + transcripts
- Writing: Grammar practice
- Listening: Shadowing audio
- Speaking: Shadowing practice

---

## Next Steps

1. **Try it out**: Process a short clip (1-2 minutes)
2. **Practice**: Use the HTML player for 10-15 minutes
3. **Curate**: Add translations to good segments
4. **Integrate**: Plan how to add media content to your app
5. **Expand**: Build a library of practice content by topic

---

**Happy shadowing! 頑張って！**
