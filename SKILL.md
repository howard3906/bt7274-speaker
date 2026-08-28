---
name: bt7274-speaker
description: Voice a reminder through the local speakers in BT-7274's voice (Titanfall 2), synthesized locally with Piper TTS and spoken in English. Trigger when the user explicitly asks to be called or reminded out loud ("用扬声器提醒我", "语音提醒我", "用 BT 的声音提醒我", "叫我"), including phrasings like "干完 XX 就叫我" / "到时候叫我" — any explicit request to be called out loud, whether immediate, after finishing a task, or scheduled. Do NOT use for silent or text-only notifications.
---

# BT-7274 Speaker Reminder

Turn reminders into spoken audio through the machine's speakers, using a Piper
TTS voice model trained on BT-7274 (the Titan AI from Titanfall 2). Everything
runs locally — no cloud TTS, no network needed after setup. Reminders are
**spoken in English** even when the user phrases the request in Chinese.

## First-time setup

Run once, then never again:

```bash
./setup.sh
```

The script installs the `piper` CLI (via uv/pipx/pip), downloads the voice
model (~63 MB, from [DJMalachite/PiperVoiceModels](https://github.com/DJMalachite/PiperVoiceModels)),
verifies SHA256 checksums, and runs a smoke test. If downloads fail behind a
restrictive network, export `https_proxy` first. See README.md for details.

## Voicing a reminder

Compose the English line, then run the bundled script. It synthesizes with
Piper and plays through the speakers, blocking until playback finishes:

```bash
./speak.sh "The build finished, come take a look."
```

The script prints the generated wav path (`/tmp/bt7274-reminder-<ts>.wav`) so
a later "再放一遍 / play it again" can be answered with `afplay <wav>` — no
re-synthesis needed.

## Composing the line

- Translate the reminder into natural English before synthesizing; Piper is
  English-only and will butcher Chinese input.
- Speak normally and plainly — the value is that it's BT's voice, not that it
  roleplays Titanfall. No canon quotes, no "Protocol" lines, no "Pilot"
  address; just state the reminder directly.
- Address the user by their preferred name. Keep it to 1–2 short sentences.

## Scheduled reminders

For delayed/scheduled speaker reminders, pair this skill with the scheduling
tool. The scheduled prompt must explicitly say to invoke the bt7274-speaker
skill and contain the exact English line to speak, so the future run delivers
audio instead of a silent notification.

## Model resolution order

`speak.sh` finds the voice model in this order:

1. `$BT7274_MODEL` environment variable (explicit override)
2. `<skill dir>/models/BT7274.onnx` (where `setup.sh` puts it)
3. `~/bt7274-voice/piper/BT7274.onnx` (legacy local install)

## Dependencies

- An audio player: macOS `afplay`, Windows PowerShell `SoundPlayer`, or Linux
  `aplay`/`ffplay` — `speak.sh` auto-detects in that order.
- Python 3.9+ via uv, pipx, or pip — only to provide the `piper` CLI.
- The `piper` CLI installed as a **pip package** (`piper-tts`). Do not use the
  old rhasspy/piper GitHub release binaries for macOS — those tarballs ship
  without required dylibs and crash on launch.
