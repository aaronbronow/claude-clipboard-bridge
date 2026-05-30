# Claude Clipboard Bridge

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Seamless cross-environment clipboard sync for **Claude Code** (the terminal-based agentic coding tool by Anthropic). Sync code snippets, terminal logs, diffs, and text from remote terminals, WSL, SSH, and isolated Docker sandboxes back to your physical host clipboard automatically.

---

## Why?

Long links can't be clicked or easily copied out of CLI.

<img width="632" height="255" alt="gemini-copy-link1" src="https://github.com/user-attachments/assets/511c2f99-ab98-4196-bf06-1d63b168bfb0" />

Anything that can be written to the terminal can be sent to the clipboard.

---

## Usage

**Prompt**
```
> Give me a find command to delete all node_modules folders older than 30 days and copy it to my clipboard.
```
**Response**
```
◇ I've sent the following command to your clipboard:
  find . -name "node_modules" -type d -mtime +30 -prune -exec rm -rf {} +
```

**Prompt**
```
> Generate a sha256 password and copy it to my clipboard.
```
**Response**
```
◇ I've generated a SHA256 password and sent the clipboard sequence to your terminal.
  a9d5e46b3a02af97e6b80734d64d3d42e10b2da110d6ed9f04df33879a1f16ee
```

**Prompt**
```
> Copy that very long URL from the last message to my clipboard.
```
**Response**
```
◇ Copied just the URL to your clipboard.
  https://accounts.google.com/o/oauth2/v2/auth?client_id=109283746556-c9i8u7y6t5r4e3w2q1a0s9d8f7g
  6h5j4.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fmyapp.example.com%2Fauth%2Fgoogle%2
  Fcallback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdrive.readonly%20h
  ttps%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.events%20https%3A%2F%2Fwww.googleapis.com%2Fa
  uth%2Fgmail.readonly%20openid%20profile%20email&access_type=offline&include_granted_scopes=true
  &state=af0ifjsldjkshfjksdhfksjdhfksjdhf&prompt=consent&code_challenge=E9Melho2Vp7j9vYJDe69Hq5H9
  _P5H76S9g1eA&code_challenge_method=S256
```

---

## Key Features

- **SSH & Multiplexer Support**: Automatically forwards copy commands through nested `SSH`, `Tmux`, and `GNU Screen` connections using secure terminal sequences.
- **WSL & Windows Native**: Natively syncs WSL-based terminal sessions to Windows hosts using standard utilities (`clip.exe` or robust PowerShell retry-loops).
- **Docker/Sandbox Isolation**: Automatically writes copy streams to secure bypass channels (like `.clipboard_bypass` or named pipes) so that containerized development sessions can still sync to the host.
- **Secure & Trusted by Design**: **OSC 52 is write-only.** The plugin is completely incapable of reading your host clipboard. It only sends text to be copied, ensuring absolute privacy.
- **Contextual Automation**: Built as a background Claude Skill with progressive disclosure. It automatically activates *only* when needed, saving context window tokens.

---

## Installation

Once the plugin is published or added to your marketplace registry:

1. **Add the Marketplace Source** (if using custom repositories):
   ```bash
   /plugin marketplace add aaronbronow/agent-clipboard-marketplace
   ```

2. **Install the Plugin**:
   ```bash
   /plugin install claude-clipboard-bridge
   # Or explicitly target the marketplace:
   /plugin install claude-clipboard-bridge@agent-clipboard-marketplace
   ```

3. **Reload Plugins**:
   ```bash
   /reload-plugins
   ```

### Local Development & Ad-hoc Loading
For local development, testing, or session-only runs, you can launch Claude Code with the plugin loaded temporarily:

* **Load from a local directory**:
  ```bash
  claude --plugin-dir /path/to/claude-clipboard-bridge
  ```
* **Load from a remote ZIP archive**:
  ```bash
  claude --plugin-url https://github.com/aaronbronow/claude-clipboard-bridge/archive/refs/tags/v1.0.4.zip
  ```

---

## How It Works

This plugin operates as a background **Claude Skill**. You do not need to memorize any custom slash commands.

1. Simply ask Claude:
   - *"Copy the active test output to my clipboard."*
   - *"Please copy the latest database schema."*
2. Claude automatically detects the intent, progressively loads the `copy` skill, and determines the most stable transport mechanism.
3. The plugin executes the unified `copy_to_clipboard.sh` script, which attempts transports in order:
   - **Platform-Native Tools** (WSL/macOS/Linux Desktop)
   - **SSH Terminal Sequence** (Direct `$SSH_TTY` write)
   - **Sandbox Bypass Channels** (Writes to `.clipboard_bypass` for host listeners)
   - **Fallback Terminal stdout / /dev/tty**

---

## Security & Sandboxing

By default, Claude Code runs terminal operations inside a containerized sandbox.

### 🛡️ Sandbox-Safe Transport (OSC 52)
Because this plugin relies primarily on **OSC 52 terminal escape sequences** written directly to `stdout` or `/dev/tty`, it operates **fully within sandboxed and containerized environments**. The escape sequences are securely processed by your physical host's terminal emulator (e.g., Windows Terminal, iTerm2, Alacritty, or VS Code Terminal), which runs natively outside the sandbox. Therefore, **no special host permissions or unsandboxed shell privileges are required** for copy operations to succeed via OSC 52.

### 🔌 Host-Utility Fallbacks
If the terminal emulator does not support OSC 52, or if you run under a restricted TTY, the plugin will attempt to fall back to platform-native tools (such as `clip.exe` / PowerShell under WSL, or `pbcopy` on macOS).
- Calling host utilities directly from within an isolated sandboxed container may fail or trigger shell sandbox alerts.
- To prevent this, the bridge automatically utilizes **Sandbox Bypass Channels** by writing the copy stream to a local workspace file (`.clipboard_bypass`). Since writing within the workspace is a standard sandboxed operation, a simple host-side background listener (such as `tail -F .clipboard_bypass > $(tty)`) bridges the copy stream to the host clipboard securely and transparently, **with zero sandbox bypass prompts or privilege escalation required**.

---

## Debugging

To diagnose copy paths, enable debug logging by setting `CLAUDE_CLIPBOARD_DEBUG=1` in your shell environment, or by creating a file named `.clipboard_debug` in the working directory:

```bash
export CLAUDE_CLIPBOARD_DEBUG=1
```
Logs will write directly to `clipboard_debug.log` in the active workspace.

---

## License

This project is licensed under the [MIT License](LICENSE).
