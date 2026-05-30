# Claude Clipboard Bridge

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Seamless cross-environment clipboard sync for **Claude Code** (the terminal-based agentic coding tool by Anthropic). Sync code snippets, terminal logs, diffs, and text from remote terminals, WSL, SSH, and isolated Docker sandboxes back to your physical host clipboard automatically.

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
   /plugin marketplace add aaronbronow/claude-clipboard-bridge
   ```

2. **Install the Plugin**:
   ```bash
   /plugin install claude-clipboard-bridge
   ```

3. **Reload Plugins**:
   ```bash
   /reload-plugins
   ```

### Local Development / Manual Installation
To load the plugin directly from a local folder:
```bash
/plugin install /path/to/claude-clipboard-bridge
/reload-plugins
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

On Windows hosts running standard PowerShell shells, Claude Code executes commands in a containerized sandbox. 

> [!IMPORTANT]
> To allow copy commands to escape the container and propagate to your host's native Windows clipboard, Claude will prompt for **unsandboxed execution** (`BypassSandbox` or host permission). Denying this permission will cause the copy to succeed silently inside the container without updating your physical clipboard.

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
