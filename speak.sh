#!/bin/bash
# Synthesize an English line with the BT-7274 Piper voice and play it.
# Usage: speak.sh "English text to speak"
set -euo pipefail

TEXT="${1:?Usage: speak.sh \"English text\"}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Model resolution: $BT7274_MODEL > <skill>/models/ > legacy ~/bt7274-voice
if [ -n "${BT7274_MODEL:-}" ]; then
  MODEL="$BT7274_MODEL"
elif [ -f "$SKILL_DIR/models/BT7274.onnx" ]; then
  MODEL="$SKILL_DIR/models/BT7274.onnx"
else
  MODEL="$HOME/bt7274-voice/piper/BT7274.onnx"
fi

OUT="/tmp/bt7274-reminder-$(date +%s).wav"

[ -f "$MODEL" ] || {
  echo "ERROR: BT model not found at $MODEL — run $SKILL_DIR/setup.sh first" >&2
  exit 1
}
command -v piper >/dev/null || {
  echo "ERROR: piper CLI not found — run $SKILL_DIR/setup.sh first" >&2
  exit 1
}

printf '%s' "$TEXT" | piper --model "$MODEL" --output-file "$OUT"

# Play through the speakers with whatever the platform offers.
# macOS has afplay; Windows has no dedicated CLI player but ships the .NET
# SoundPlayer reachable via PowerShell; Linux/Unix: aplay (ALSA) or ffplay.
if command -v afplay >/dev/null 2>&1; then
  afplay "$OUT"
elif command -v powershell.exe >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
  POWERSHELL="$(command -v powershell.exe || command -v powershell)"
  WOUT="$(cygpath -w "$OUT" 2>/dev/null || echo "$OUT")"
  "$POWERSHELL" -NoProfile -Command "(New-Object Media.SoundPlayer '$WOUT').PlaySync()"
elif command -v aplay >/dev/null 2>&1; then
  aplay -q "$OUT"
elif command -v ffplay >/dev/null 2>&1; then
  ffplay -nodisp -autoexit -loglevel quiet "$OUT"
else
  echo "ERROR: no audio player found (tried afplay, PowerShell SoundPlayer, aplay, ffplay)" >&2
  echo "Audio was synthesized to: $OUT" >&2
  exit 1
fi
echo "$OUT"
