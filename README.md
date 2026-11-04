# bt7274-speaker

An [agent skill](https://agentskills.io) that turns reminders into spoken
audio through your speakers, in the voice of **BT-7274**, the Titan AI from
*Titanfall 2* — synthesized entirely locally with
[Piper](https://github.com/rhasspy/piper) TTS. No cloud service, no API key,
no data leaves your machine after setup.

Designed for coding agents (ZCode, Claude Code, etc.): tell your agent
something like *"call me out loud when it's done"* and it will speak the
reminder in English in BT's voice when the job finishes.

```text
$ ./speak.sh "The build finished, come take a look."
▶ playing… 3.4s
/tmp/bt7274-reminder-1787944143.wav
```

## Requirements

- A host that can run `bash` and play audio: macOS (`afplay`, built in),
  Windows (PowerShell + the .NET `SoundPlayer` that ships with the OS — no
  install needed, also works from Git Bash/WSL via `powershell.exe`), or
  Linux (`aplay` from alsa-utils, or `ffplay` from ffmpeg). `speak.sh`
  auto-detects in that order.
- `uv`, `pipx`, or `pip3` — only to install the `piper` CLI
- ~70 MB disk for the voice model
- Network access **once**, during setup, to download the model

## Install

```bash
# via the skills CLI (also lists it on skills.sh)
npx skills add howard3906/bt7274-speaker

# or clone directly
git clone https://github.com/howard3906/bt7274-speaker
./bt7274-speaker/setup.sh
```

`setup.sh` does three things:

1. Installs the `piper` CLI (`uv tool install piper-tts`, falling back to
   pipx/pip). Requires Python 3.9+.
2. Downloads the BT-7274 voice model (~63 MB `.onnx` + phoneme config) from
   [DJMalachite/PiperVoiceModels](https://github.com/DJMalachite/PiperVoiceModels)
   into `models/`, and verifies both files against pinned SHA256 checksums.
   Behind a proxy? `export https_proxy=...` first. If the upstream repo ever
   updates the model, the pin will catch it — re-pin or bypass with
   `BT7274_SKIP_CHECKSUM=1` (see *Model integrity* below).
3. Runs a smoke test: synthesizes one line and writes a wav, so you know the
   whole chain works.

## Usage

```bash
./speak.sh "Your reminder text, in English."
```

- Blocks until playback finishes, then prints the generated wav path under
  `/tmp/` for cheap replays with `afplay`.
- Override the model with `BT7274_MODEL=/path/to/BT7274.onnx`. Resolution
  order: `$BT7274_MODEL` → `models/BT7274.onnx` → `~/bt7274-voice/piper/`
  (legacy path).
- Want your own voice/character instead? Any Piper `.onnx` voice works —
  point `BT7274_MODEL` at it. Browse community voices in
  [rhasspy/piper-voices](https://github.com/rhasspy/piper-voices).

### Wiring it into an agent

The core of this package is the agent-facing [SKILL.md](SKILL.md), which tells
the agent when to trigger (phrases like "remind me out loud", "call me when
X is done"), how to compose the line (translate to English, keep it to 1–2
plain sentences), and how to pair the skill with scheduled jobs. Point your
agent at this directory as a skill folder and it will pick up the rest.

## Model integrity

Checksums are pinned so a truncated or tampered 63 MB download fails loudly
instead of producing garbled audio:

| File | Size | SHA256 |
|---|---|---|
| `BT7274.onnx` | 63122309 B | `aec69f5c…109adcf` |
| `BT7274.onnx.json` | 7095 B | `31d7694c…31c4456` |

Full hashes live in `setup.sh`. If
[upstream](https://github.com/DJMalachite/PiperVoiceModels) publishes a new
revision of the model, update the pins — or bypass verification for one run
with `BT7274_SKIP_CHECKSUM=1`.

## Troubleshooting

- **`piper: command not found` after setup** — the tool env's `bin` dir isn't
  on `PATH`; restart your shell or run `uv tool update-shell`.
- **Garbled/no audio on macOS with the official Piper release binary** — a
  known packaging bug in the old rhasspy/piper macOS tarballs (missing
  dylibs). This skill uses the pip-packaged `piper-tts` instead, which works.
- **Chinese text sounds broken** — expected: the voice is English-only.
  Compose the reminder in English (SKILL.md instructs the agent to do this
  automatically).

## Credits & legal

- Voice model: [DJMalachite/PiperVoiceModels](https://github.com/DJMalachite/PiperVoiceModels),
  trained on BT-7274's in-game lines by voice actor **Glenn Steinbaum**.
- TTS engine: [Piper](https://github.com/rhasspy/piper) (MIT).
- Skill scripts: MIT.

BT-7274, *Titanfall 2*, and the character's voice are the property of
Respawn Entertainment / Electronic Arts. The voice model is fan-made from
game audio. **Personal / non-commercial use only** — don't use this for
commercial products, impersonation, or anything you wouldn't put your name on.
