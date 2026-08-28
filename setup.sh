#!/bin/bash
# One-time setup for the bt7274-speaker skill:
#   1. Install the piper-tts CLI (via uv, falling back to pip)
#   2. Download the BT-7274 Piper voice model and verify its checksums
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="${BT7274_MODEL_DIR:-$SKILL_DIR/models}"
mkdir -p "$MODEL_DIR"

REPO="https://raw.githubusercontent.com/DJMalachite/PiperVoiceModels/main/Titanfall2/BT7274"

# --- 1. piper CLI -----------------------------------------------------------
if command -v piper >/dev/null 2>&1; then
  echo "[setup] piper CLI found: $(command -v piper)"
else
  echo "[setup] installing piper-tts ..."
  if command -v uv >/dev/null 2>&1; then
    uv tool install piper-tts
  elif command -v pipx >/dev/null 2>&1; then
    pipx install piper-tts
  else
    echo "[setup] neither uv nor pipx found; trying pip3 --user" >&2
    pip3 install --user piper-tts
  fi
  command -v piper >/dev/null 2>&1 || {
    echo "ERROR: piper installed but not on PATH. Restart your shell or fix PATH." >&2
    exit 1
  }
fi

# --- 2. model download + checksum verification ------------------------------
download() {
  local file="$1" size="$2" sha="$3"
  local dest="$MODEL_DIR/$file"
  if [ -f "$dest" ]; then
    echo "[setup] $file already present"
  else
    echo "[setup] downloading $file ($(( size / 1024 / 1024 )) MB) ..."
    curl -fL --retry 3 -o "$dest" "$REPO/$file"
  fi
  if [ "${BT7274_SKIP_CHECKSUM:-0}" = "1" ]; then
    echo "[setup] WARNING: checksum verification skipped for $file (BT7274_SKIP_CHECKSUM=1)" >&2
    return 0
  fi
  if echo "$sha  $dest" | shasum -a 256 -c - >/dev/null 2>&1; then
    echo "[setup] $file checksum OK"
  else
    # The pinned sha matches the upstream revision this skill was verified
    # against. A mismatch usually means a corrupted download; if the upstream
    # repo has since updated the model, re-pin the sha or skip with
    # BT7274_SKIP_CHECKSUM=1.
    cat >&2 <<EOF
ERROR: checksum mismatch for $dest
  expected (pinned): $sha
  actual:            $(shasum -a 256 "$dest" | cut -d' ' -f1)
This is usually a corrupted/truncated download and the file has been removed.
If the upstream PiperVoiceModels repo updated the model file, either update
the pinned checksum in this script or run again with BT7274_SKIP_CHECKSUM=1.
EOF
    rm -f "$dest"
    exit 1
  fi
}

download "BT7274.onnx" \
  63122309 \
  aec69f5cb0b1bb3329a4f2294d2afc7c50149f82798e97d2cd9c8b450109adcf
download "BT7274.onnx.json" \
  7095 \
  31d7694c5f6053b5794cb0ee2d50105790fd078442a43e62a30324c4631c4456

# --- 3. smoke test -----------------------------------------------------------
echo "[setup] synthesizing a test line to verify the whole pipeline ..."
echo "Setup complete. The pilot is ready." | \
  piper --model "$MODEL_DIR/BT7274.onnx" --output-file "$MODEL_DIR/.smoke-test.wav" >/dev/null 2>&1
[ -s "$MODEL_DIR/.smoke-test.wav" ] || { echo "ERROR: smoke test produced no audio" >&2; exit 1; }

echo "[setup] all done. Model dir: $MODEL_DIR"
echo "[setup] try it:  $SKILL_DIR/speak.sh \"Everything is ready.\""
