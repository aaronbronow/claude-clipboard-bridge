---
name: clipboard
description: Copy any text to the clipboard over SSH, Tmux, WSL, Powershell
---

# Instructions

When the user asks to copy text, code blocks, logs, or command output to their clipboard, follow these steps.

### Step 1: Execute the Staged Helper Script (Primary Method)
To avoid sandbox/container prompt overhead and handle complex environmental configurations automatically, your **primary** and preferred action is to execute the centralized `copy_to_clipboard.sh` helper script.

#### 1. Locate the Script Path
Locate the helper script relative to this skill's installation directory. Claude plugins reside inside the `~/.claude/plugins/` or `~/.claude/plugins/marketplaces/` subdirectory structure on Unix/WSL, or under `C:\Users\<username>\.claude\plugins\marketplaces\` on Windows PowerShell hosts. 

- **If in a development/workspace directory**, the script is located at:
  `./skills/copy/copy_to_clipboard.sh`
- **If installed in a Claude marketplace/plugins environment**, search or list your plugin's install directories to find the absolute path of `copy_to_clipboard.sh`.

#### 2. Execute via Stdin (Recommended for Escape Safety)
To prevent shell-parsing errors or escaping bugs with double quotes (`"`), single quotes (`'`), or backticks (`` ` ``), always stream the text to copy into the script's standard input (stdin), and capture stderr to read the transport status line:

```bash
printf "%s" "YOUR_TEXT_TO_COPY" | /path/to/copy_to_clipboard.sh
```

On success the script writes exactly one line to stderr in the form `Copied via <transport>`, for example:
- `Copied via PowerShell (WSL → Windows)`
- `Copied via clip.exe (WSL)`
- `Copied via pbcopy (macOS)`
- `Copied via wl-copy (Wayland)`
- `Copied via xclip (X11)`
- `Copied via xsel (X11)`
- `Copied via SSH TTY (OSC 52)`
- `Copied via sandbox bypass file (.clipboard_bypass)`
- `Copied via direct TTY (OSC 52)`
- `Copied via stdout (OSC 52)`

Use this stderr line — not assumptions about the environment — when reporting the transport in Step 3.

> [!IMPORTANT]
> **Windows Host & Sandbox Bypass**: When executing PowerShell commands or unified helper scripts on Windows hosts, **always request unsandboxed command execution** (e.g., specifying `BypassSandbox: true` in your command execution config, or requesting `unsandboxed` execution). If you fail to bypass the container sandbox, the clipboard action will succeed silently *inside* the containerized shell without updating the user's host OS clipboard.

---

### Step 2: Platform-Native Fallbacks (Use ONLY if the script is missing or fails)
If executing the helper script fails or is blocked by local system execution policies, execute the native platform command:

#### A. Windows (PowerShell Shell)
If the active terminal is PowerShell, request unsandboxed command execution and run:
```powershell
Set-Clipboard -Value "YOUR_TEXT_TO_COPY"
```
*(If a clipboard lock is encountered, run a retry loop with a 100ms sleep up to 5 times).*

#### B. Windows (WSL or CMD Shell)
If running under WSL or standard Command Prompt:
```bash
echo -n "YOUR_TEXT_TO_COPY" | clip.exe
```

#### C. macOS (zsh/bash)
If running on macOS:
```bash
echo -n "YOUR_TEXT_TO_COPY" | pbcopy
```

#### D. Linux (Desktop Display Servers)
If on standard Linux with a GUI server running, use the first available tool:
- **Wayland**: `echo -n "YOUR_TEXT_TO_COPY" | wl-copy`
- **X11 (xclip)**: `echo -n "YOUR_TEXT_TO_COPY" | xclip -selection clipboard`
- **X11 (xsel)**: `echo -n "YOUR_TEXT_TO_COPY" | xsel --clipboard --input`

#### E. Remote SSH Session
If operating on a remote server over a writable terminal (`$SSH_TTY` is present):
```bash
printf "\033]52;c;$(echo -n "YOUR_TEXT_TO_COPY" | base64 | tr -d '\r\n')\007" > "$SSH_TTY"
```

#### F. Sandbox Isolation (Docker/Containers)
If running inside an isolated Docker sandbox with no host device exposure, output the OSC 52 escape sequence directly into the shared bypass file:
```bash
printf "\033]52;c;$(echo -n "YOUR_TEXT_TO_COPY" | base64 | tr -d '\r\n')\007" > .clipboard_bypass
```

---

### Step 3: Verify and Confirm
After performing the copy, confirm to the user with a single sentence that states:
1. The text was copied successfully.
2. The **exact transport** used, taken from the debug log (e.g., "via PowerShell", "via clip.exe", "via SSH TTY (OSC 52)", "via sandbox bypass file"). Never guess or infer the transport from environment variables — always read it from the log.

If the transport used was the sandbox bypass file (i.e. `.clipboard_bypass`), notify the user that they must run `tail -F .clipboard_bypass > $(tty)` in another terminal on their host machine to stream the escape sequences and complete the copy operation.
