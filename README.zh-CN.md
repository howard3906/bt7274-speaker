<p align="right">简体中文 | <a href="README.md">English</a></p>

# bt7274-speaker

一个 [agent skill](https://agentskills.io)：把提醒事项变成从扬声器播出的语音，
用《泰坦陨落2》里泰坦 AI **BT-7274** 的声线，基于
[Piper](https://github.com/rhasspy/piper) TTS 完全本地合成——不依赖云端服务、
不需要 API key，安装完成后断网也能用。

为编程 agent（ZCode、Claude Code 等）设计：对 agent 说一句
"干完了就用扬声器叫我"，任务结束时它就会用 BT 的声线用英文播报提醒。

```text
$ ./speak.sh "The build finished, come take a look."
▶ playing… 3.4s
/tmp/bt7274-reminder-1787944143.wav
```

## 环境要求

- 能跑 `bash` 并播放音频的主机：macOS（自带 `afplay`）、Windows（PowerShell
  调用系统内置的 .NET `SoundPlayer`，无需安装任何东西，Git Bash/WSL 里也能
  通过 `powershell.exe` 调用）、Linux（alsa-utils 的 `aplay` 或 ffmpeg 的
  `ffplay`）。`speak.sh` 按此顺序自动探测。
- `uv`、`pipx` 或 `pip3`——只为安装 `piper` CLI
- 约 70 MB 磁盘空间存放声学模型
- 仅安装阶段需要联网下载模型

## 安装

```bash
# 通过 skills CLI 安装（同时会被 skills.sh 目录收录）
npx skills add howard3906/bt7274-speaker

# 或直接 clone
git clone https://github.com/howard3906/bt7274-speaker
./bt7274-speaker/setup.sh
```

`setup.sh` 做三件事：

1. 安装 `piper` CLI（优先 `uv tool install piper-tts`，回退 pipx/pip）。需要
   Python 3.9+。
2. 从
   [DJMalachite/PiperVoiceModels](https://github.com/DJMalachite/PiperVoiceModels)
   下载 BT-7274 语音模型（约 63 MB 的 `.onnx` + 音素配置）到 `models/`，并对
   两个文件做固定 SHA256 校验和验证。网络受限时先 `export https_proxy=...`。
   如果上游仓库更新了模型，固定校验会第一时间拦住——重新固定或用
   `BT7274_SKIP_CHECKSUM=1` 跳过（见下方"模型完整性"）。
3. 跑一次冒烟测试：合成一句话并生成 wav，确认整条链路可用。

## 使用

```bash
./speak.sh "要说的话，用英文。"
```

- 阻塞直到播放结束，然后打印生成的 wav 路径（在 `/tmp/` 下），之后可用
  `afplay <wav>` 直接重放，无需重新合成。
- 用 `BT7274_MODEL=/path/to/BT7274.onnx` 指定模型。解析顺序：
  `$BT7274_MODEL` → `models/BT7274.onnx` → `~/bt7274-voice/piper/`（历史路径）。
- 想换成自己的音色/其他角色？任何 Piper `.onnx` 语音都能用，把
  `BT7274_MODEL` 指过去即可。社区语音见
  [rhasspy/piper-voices](https://github.com/rhasspy/piper-voices)。

### 接入 agent

本包的核心是面向 agent 的 [SKILL.md](SKILL.md)：它告诉 agent 何时触发
（"用扬声器提醒我"、"叫我"、"干完 XX 就叫我"这类说法）、如何组织台词
（翻译成英文、保持 1–2 句平常语气），以及如何与定时任务配合。把本目录作为
skill 目录指给你的 agent 即可。

## 模型完整性

固定校验和是为了让被截断或被篡改的 63 MB 下载在第一时间报错，而不是合成出
乱糟糟的音频：

| 文件 | 大小 | SHA256 |
|---|---|---|
| `BT7274.onnx` | 63122309 B | `aec69f5c…109adcf` |
| `BT7274.onnx.json` | 7095 B | `31d7694c…31c4456` |

完整哈希值在 `setup.sh` 里。若
[上游](https://github.com/DJMalachite/PiperVoiceModels)发布了新版本模型，
更新脚本中的固定值即可——或单次运行时用 `BT7274_SKIP_CHECKSUM=1` 跳过校验。

## 故障排查

- **安装后 `piper: command not found`**——工具环境的 `bin` 目录不在 `PATH`
  里；重启 shell 或运行 `uv tool update-shell`。
- **macOS 上用官方 Piper 发布的二进制没声音/乱码**——旧版 rhasspy/piper 的
  macOS 压缩包有已知打包缺陷（缺动态库）。本 skill 使用 pip 包 `piper-tts`，
  没有这个问题。
- **中文文本听起来是坏的**——符合预期：该语音仅支持英文。请用英文组织提醒
  内容（SKILL.md 已指示 agent 自动完成翻译）。

## 署名与版权

- 语音模型：[DJMalachite/PiperVoiceModels](https://github.com/DJMalachite/PiperVoiceModels)，
  基于 BT-7274 游戏内台词（配音演员 **Glenn Steinbaum**）训练的粉丝作品。
- TTS 引擎：[Piper](https://github.com/rhasspy/piper)（MIT）。
- Skill 脚本：MIT。

BT-7274、《泰坦陨落2》及角色声线的版权归 Respawn Entertainment / Electronic
Arts 所有。语音模型是基于游戏音频的粉丝作品，**仅供个人/非商业使用**——
不要用于商业产品、冒充用途或任何你不好意思署名的事情。
