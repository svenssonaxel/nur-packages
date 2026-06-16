# Swedish audio transcription via faster-whisper (KB-Whisper-large), CPU/float32.
# Runtime-impure: the model (~3 GB) is downloaded to ~/.cache/whisper on first use.
{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.faster-whisper ]);
in
pkgs.writeShellScriptBin "transcribe-swedish" ''
  set -euo pipefail

  OUTDIR=""
  FILES=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--outdir)
        OUTDIR="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: transcribe-swedish [-o/--outdir DIR] file1 [file2...]"
        echo ""
        echo "Transcribes Swedish audio using KB-Whisper-large (high-quality model)."
        echo ""
        echo "Options:"
        echo "  -o, --outdir DIR    Output directory. Default: same as input file"
        echo "  -h, --help          Show this help message"
        echo ""
        echo "Examples:"
        echo "  transcribe-swedish recording.wav"
        echo "  transcribe-swedish -o ~/transcripts *.wav"
        echo "  transcribe-swedish file1.mp3 file2.mp3"
        echo ""
        echo "Model: KBLab/kb-whisper-large (KB-Whisper-large)"
        echo "Engine: faster-whisper (CTranslate2)"
        echo "Precision: float32 (maximum quality)"
        echo ""
        echo "Note: runs on CPU and is slow; expect several times realtime."
        echo ""
        echo "Note: Model downloads automatically on first use (~3 GB to ~/.cache/whisper)"
        exit 0
        ;;
      -*)
        echo "Error: Unknown option: $1" >&2
        exit 1
        ;;
      *)
        FILES+=("$1")
        shift
        ;;
    esac
  done

  if [ ''${#FILES[@]} -eq 0 ]; then
    echo "Error: No files specified" >&2
    echo "Usage: transcribe-swedish [-o/--outdir DIR] file1 [file2...]" >&2
    exit 1
  fi

  # Create output directory if specified
  if [ -n "$OUTDIR" ]; then
    mkdir -p "$OUTDIR"
  fi

  TRANSCRIBED=0
  SKIPPED=0

  # Transcribe each file sequentially (single job, all CPU)
  for FILE in "''${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
      echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Skipping (not found): $FILE" >&2
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    # Determine output directory
    if [ -n "$OUTDIR" ]; then
      OUTPUT_DIR="$OUTDIR"
    else
      OUTPUT_DIR="$(dirname "$FILE")"
    fi

    BASENAME="$(basename "$FILE" | sed 's/\.[^.]*$//')"
    OUTPUT_FILE="$OUTPUT_DIR/''${BASENAME}.txt"

    if [ -f "$OUTPUT_FILE" ]; then
      echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Skipping (output exists): $OUTPUT_FILE" >&2
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Transcribing: $FILE"
    echo "   Language: Swedish"
    echo "   Model: KB-Whisper-large (float32)"
    echo "   Output: $OUTPUT_FILE"

    # Run transcription with low priority, all CPU cores
    export AUDIO_FILE="$FILE"
    export OUTPUT_FILE="$OUTPUT_FILE"
    export OMP_NUM_THREADS=$(nproc)

    nice -n 19 ${python}/bin/python3 ${./transcribe-swedish.py}

    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Done: $OUTPUT_FILE"
    echo ""
    TRANSCRIBED=$((TRANSCRIBED + 1))
  done

  echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Transcribed $TRANSCRIBED file(s), skipped $SKIPPED"

  if [ $SKIPPED -gt 0 ]; then
    exit 1
  else
    exit 0
  fi
''
