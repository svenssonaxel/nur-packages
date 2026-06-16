#!/usr/bin/env python3
"""Transcribe English audio using OpenAI Whisper large-v3 via faster-whisper."""
import os
import sys
import time
from faster_whisper import WhisperModel

def main():
    audio_file = os.environ.get("AUDIO_FILE")
    output_file = os.environ.get("OUTPUT_FILE")
    num_threads = int(os.environ.get("OMP_NUM_THREADS", "1"))

    if not audio_file or not output_file:
        print("Error: AUDIO_FILE and OUTPUT_FILE environment variables required", file=sys.stderr)
        sys.exit(1)

    print(f"   Using {num_threads} CPU threads")
    print("   Loading Whisper large-v3 model...")
    start_time = time.time()

    # OpenAI Whisper large-v3 via faster-whisper
    model = WhisperModel(
        "large-v3",
        device="cpu",
        compute_type="float32",
        download_root=os.path.expanduser("~/.cache/whisper"),
    )

    print(f"   Model loaded in {time.time() - start_time:.1f}s")
    print("   Transcribing...")

    transcribe_start = time.time()
    segments, info = model.transcribe(
        audio_file,
        language="en",
        condition_on_previous_text=False
    )
    transcribe_time = time.time() - transcribe_start

    with open(output_file, "w") as f:
        for segment in segments:
            f.write(segment.text.strip() + "\n")

    speed_ratio = transcribe_time / info.duration if info.duration > 0 else 0
    print(f"   Transcribed {info.duration:.1f}s audio in {transcribe_time:.1f}s")
    print(f"   Speed: {speed_ratio:.1f}x realtime")
    print(f"   Total time: {time.time() - start_time:.1f}s")

if __name__ == "__main__":
    main()
