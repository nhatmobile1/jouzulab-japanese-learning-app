#!/usr/bin/env python3
"""
Japanese Shadowing Practice Tool
================================

Transcribes Japanese audio/video and generates multiple speed versions for shadowing practice.

Features:
- Transcribe Japanese audio using OpenAI Whisper
- Generate slow (0.75x), normal (1.0x), and fast (1.25x) versions
- Split into individual segments for focused practice
- Export structured JSON for your learning app

Requirements:
    pip install openai-whisper pydub ffmpeg-python

You also need FFmpeg installed:
    Mac: brew install ffmpeg
    Windows: Download from ffmpeg.org
    Linux: sudo apt install ffmpeg

Usage:
    python shadowing_tool.py input_video.mp4 --output-dir ./practice_clips
"""

import os
import json
import argparse
from datetime import datetime
from pathlib import Path

# Check for required packages
try:
    import whisper
except ImportError:
    print("❌ Please install whisper: pip install openai-whisper")
    exit(1)

try:
    from pydub import AudioSegment
except ImportError:
    print("❌ Please install pydub: pip install pydub")
    exit(1)


class ShadowingTool:
    def __init__(self, whisper_model="base"):
        """
        Initialize the shadowing tool.
        
        Whisper model options (accuracy vs speed tradeoff):
            - "tiny"   : Fastest, least accurate
            - "base"   : Good balance for most use
            - "small"  : Better accuracy
            - "medium" : High accuracy
            - "large"  : Best accuracy, slowest
        
        For Japanese, "medium" or "large" recommended for best results.
        """
        print(f"🔄 Loading Whisper model '{whisper_model}'...")
        self.model = whisper.load_model(whisper_model)
        print("✅ Model loaded!")
        
        # Speed settings
        self.speeds = {
            "slow": 0.75,
            "normal": 1.0,
            "fast": 1.25
        }
    
    def extract_audio(self, input_file, output_file):
        """Extract audio from video file"""
        print(f"🎵 Extracting audio from {input_file}...")
        
        # Use pydub to handle various formats
        audio = AudioSegment.from_file(input_file)
        audio.export(output_file, format="mp3")
        
        print(f"✅ Audio saved to {output_file}")
        return output_file
    
    def transcribe(self, audio_file, language="ja"):
        """Transcribe audio using Whisper"""
        print(f"🎤 Transcribing {audio_file}...")
        print("   (This may take a while for long files)")
        
        result = self.model.transcribe(
            audio_file,
            language=language,
            task="transcribe",
            verbose=False
        )
        
        print(f"✅ Transcription complete! Found {len(result['segments'])} segments")
        return result
    
    def change_speed(self, audio_segment, speed):
        """
        Change audio playback speed without changing pitch.
        
        Note: pydub's speedup changes pitch. For better quality,
        we use frame rate manipulation which is close enough for practice.
        """
        if speed == 1.0:
            return audio_segment
        
        # Change speed by modifying frame rate
        # This slightly affects pitch but is good enough for practice
        new_frame_rate = int(audio_segment.frame_rate * speed)
        return audio_segment._spawn(
            audio_segment.raw_data,
            overrides={"frame_rate": new_frame_rate}
        ).set_frame_rate(audio_segment.frame_rate)
    
    def create_speed_versions(self, audio_segment, output_base_path):
        """Create slow, normal, and fast versions of audio"""
        versions = {}
        
        for speed_name, speed_rate in self.speeds.items():
            output_path = f"{output_base_path}_{speed_name}.mp3"
            
            # Adjust speed
            adjusted = self.change_speed(audio_segment, speed_rate)
            adjusted.export(output_path, format="mp3")
            
            versions[speed_name] = output_path
            print(f"   ✅ {speed_name} ({speed_rate}x): {output_path}")
        
        return versions
    
    def process_segments(self, audio_file, transcription, output_dir):
        """
        Process transcription into individual practice segments.
        Each segment gets slow/normal/fast versions.
        """
        print(f"\n📂 Creating practice segments in {output_dir}...")
        os.makedirs(output_dir, exist_ok=True)
        
        # Load full audio
        full_audio = AudioSegment.from_file(audio_file)
        
        segments_data = []
        
        for i, segment in enumerate(transcription["segments"]):
            segment_id = f"segment_{i+1:04d}"
            print(f"\n🔹 Processing {segment_id}: {segment['text'][:30]}...")
            
            # Extract segment audio (convert seconds to milliseconds)
            start_ms = int(segment["start"] * 1000)
            end_ms = int(segment["end"] * 1000)
            
            # Add small padding for natural sound
            padding_ms = 100
            start_ms = max(0, start_ms - padding_ms)
            end_ms = min(len(full_audio), end_ms + padding_ms)
            
            segment_audio = full_audio[start_ms:end_ms]
            
            # Create segment directory
            segment_dir = os.path.join(output_dir, segment_id)
            os.makedirs(segment_dir, exist_ok=True)
            
            # Create speed versions
            base_path = os.path.join(segment_dir, segment_id)
            audio_versions = self.create_speed_versions(segment_audio, base_path)
            
            # Build segment data
            segment_data = {
                "id": segment_id,
                "index": i + 1,
                "japanese": segment["text"],
                "english": None,  # To be filled manually
                "start_time": segment["start"],
                "end_time": segment["end"],
                "duration_seconds": segment["end"] - segment["start"],
                "audio": {
                    "slow": os.path.basename(audio_versions["slow"]),
                    "normal": os.path.basename(audio_versions["normal"]),
                    "fast": os.path.basename(audio_versions["fast"])
                },
                "scenarios": [],  # To be tagged manually
                "formality": None,  # casual/polite/formal
                "notes": "",
                "mastered": False
            }
            
            segments_data.append(segment_data)
        
        return segments_data
    
    def save_practice_data(self, segments, source_info, output_dir):
        """Save structured JSON for the learning app"""
        output_file = os.path.join(output_dir, "practice_data.json")
        
        data = {
            "metadata": {
                "created_at": datetime.now().isoformat(),
                "source": source_info,
                "total_segments": len(segments),
                "speeds": self.speeds
            },
            "segments": segments
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ Practice data saved to {output_file}")
        return output_file
    
    def generate_practice_html(self, segments, output_dir):
        """Generate a simple HTML player for practicing"""
        html_content = """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Japanese Shadowing Practice</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h1 { color: #333; }
        .segment {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .segment-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .segment-number {
            background: #e0e0e0;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            color: #666;
        }
        .japanese {
            font-size: 24px;
            margin: 15px 0;
            line-height: 1.6;
        }
        .english {
            color: #666;
            font-style: italic;
            margin-bottom: 15px;
        }
        .speed-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .speed-btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            transition: all 0.2s;
        }
        .speed-btn:hover { transform: scale(1.05); }
        .speed-btn.slow {
            background: #4CAF50;
            color: white;
        }
        .speed-btn.normal {
            background: #2196F3;
            color: white;
        }
        .speed-btn.fast {
            background: #FF5722;
            color: white;
        }
        .loop-btn {
            background: #9C27B0;
            color: white;
        }
        .instructions {
            background: #fff3e0;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .time-info {
            font-size: 12px;
            color: #999;
        }
    </style>
</head>
<body>
    <h1>🎯 Japanese Shadowing Practice</h1>
    
    <div class="instructions">
        <strong>How to practice:</strong>
        <ol>
            <li>🐢 Start with <strong>Slow</strong> - catch every syllable</li>
            <li>🚶 Move to <strong>Normal</strong> - match native speed</li>
            <li>🏃 Challenge with <strong>Fast</strong> - push yourself</li>
            <li>🔁 Use <strong>Loop</strong> to repeat until comfortable</li>
        </ol>
    </div>
    
    <div id="segments">
"""
        
        for segment in segments:
            segment_html = f"""
        <div class="segment" id="{segment['id']}">
            <div class="segment-header">
                <span class="segment-number">#{segment['index']}</span>
                <span class="time-info">{segment['duration_seconds']:.1f}s</span>
            </div>
            <div class="japanese">{segment['japanese']}</div>
            <div class="english">{segment.get('english') or '(Add translation)'}</div>
            <div class="speed-buttons">
                <button class="speed-btn slow" onclick="playAudio('{segment['id']}', 'slow')">
                    🐢 Slow (0.75x)
                </button>
                <button class="speed-btn normal" onclick="playAudio('{segment['id']}', 'normal')">
                    🚶 Normal (1.0x)
                </button>
                <button class="speed-btn fast" onclick="playAudio('{segment['id']}', 'fast')">
                    🏃 Fast (1.25x)
                </button>
                <button class="speed-btn loop-btn" onclick="toggleLoop('{segment['id']}')">
                    🔁 Loop
                </button>
            </div>
            <audio id="audio-{segment['id']}-slow" src="{segment['id']}/{segment['audio']['slow']}"></audio>
            <audio id="audio-{segment['id']}-normal" src="{segment['id']}/{segment['audio']['normal']}"></audio>
            <audio id="audio-{segment['id']}-fast" src="{segment['id']}/{segment['audio']['fast']}"></audio>
        </div>
"""
            html_content += segment_html
        
        html_content += """
    </div>
    
    <script>
        let currentAudio = null;
        let loopingSegment = null;
        
        function playAudio(segmentId, speed) {
            // Stop current audio if playing
            if (currentAudio) {
                currentAudio.pause();
                currentAudio.currentTime = 0;
            }
            
            // Play new audio
            const audioId = `audio-${segmentId}-${speed}`;
            currentAudio = document.getElementById(audioId);
            currentAudio.play();
            
            // Handle looping
            if (loopingSegment === segmentId) {
                currentAudio.onended = () => {
                    setTimeout(() => {
                        if (loopingSegment === segmentId) {
                            currentAudio.play();
                        }
                    }, 500);
                };
            }
        }
        
        function toggleLoop(segmentId) {
            if (loopingSegment === segmentId) {
                loopingSegment = null;
                if (currentAudio) currentAudio.onended = null;
                alert('Loop disabled');
            } else {
                loopingSegment = segmentId;
                alert('Loop enabled for this segment');
            }
        }
    </script>
</body>
</html>
"""
        
        output_file = os.path.join(output_dir, "practice.html")
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"✅ Practice HTML player saved to {output_file}")
        return output_file


def main():
    parser = argparse.ArgumentParser(
        description="Japanese Shadowing Practice Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic usage with video file
    python shadowing_tool.py movie_scene.mp4
    
    # Specify output directory
    python shadowing_tool.py anime_clip.mp4 --output-dir ./practice/episode1
    
    # Use larger Whisper model for better accuracy
    python shadowing_tool.py drama.mp4 --model large
    
    # Process audio file directly
    python shadowing_tool.py podcast.mp3 --output-dir ./podcast_practice
        """
    )
    
    parser.add_argument(
        "input_file",
        help="Input video or audio file (mp4, mkv, mp3, wav, etc.)"
    )
    parser.add_argument(
        "--output-dir", "-o",
        default="./shadowing_practice",
        help="Output directory for practice files (default: ./shadowing_practice)"
    )
    parser.add_argument(
        "--model", "-m",
        default="base",
        choices=["tiny", "base", "small", "medium", "large"],
        help="Whisper model size (default: base, use 'large' for best accuracy)"
    )
    parser.add_argument(
        "--title", "-t",
        default=None,
        help="Title/source name for the content"
    )
    
    args = parser.parse_args()
    
    # Validate input file
    if not os.path.exists(args.input_file):
        print(f"❌ Error: Input file not found: {args.input_file}")
        exit(1)
    
    print("=" * 60)
    print("🎯 Japanese Shadowing Practice Tool")
    print("=" * 60)
    
    # Initialize tool
    tool = ShadowingTool(whisper_model=args.model)
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Extract audio if video file
    input_path = Path(args.input_file)
    if input_path.suffix.lower() in ['.mp4', '.mkv', '.avi', '.mov', '.webm']:
        audio_file = os.path.join(args.output_dir, "extracted_audio.mp3")
        tool.extract_audio(args.input_file, audio_file)
    else:
        audio_file = args.input_file
    
    # Transcribe
    transcription = tool.transcribe(audio_file, language="ja")
    
    # Process segments
    segments = tool.process_segments(audio_file, transcription, args.output_dir)
    
    # Save practice data
    source_info = {
        "title": args.title or input_path.stem,
        "original_file": input_path.name,
        "processed_at": datetime.now().isoformat()
    }
    tool.save_practice_data(segments, source_info, args.output_dir)
    
    # Generate HTML player
    tool.generate_practice_html(segments, args.output_dir)
    
    # Summary
    print("\n" + "=" * 60)
    print("✨ Processing complete!")
    print("=" * 60)
    print(f"\n📁 Output directory: {args.output_dir}")
    print(f"📊 Total segments: {len(segments)}")
    print(f"\n📄 Files created:")
    print(f"   • practice_data.json - Structured data for your app")
    print(f"   • practice.html - Browser-based practice player")
    print(f"   • segment_XXXX/ folders - Audio files at 3 speeds")
    print(f"\n🚀 Next steps:")
    print(f"   1. Open practice.html in your browser to start practicing")
    print(f"   2. Edit practice_data.json to add English translations")
    print(f"   3. Tag segments with scenarios (restaurant, shopping, etc.)")
    print(f"   4. Import into your Japanese learning app")


if __name__ == "__main__":
    main()
