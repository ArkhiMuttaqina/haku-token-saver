# Haku Token Saver Troubleshooting

Common issues and fixes for HTS installation and runtime.

---

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [PATH and Environment Issues](#path-and-environment-issues)
3. [Backend Issues](#backend-issues)
4. [Windows-Specific Issues](#windows-specific-issues)
5. [Agent Integration Issues](#agent-integration-issues)

---

## Installation Issues

### `hts: command not found`

**Symptom:** After installation, `hts --doctor` fails with command not found.

**Cause:** The bin directory is not on PATH.

**Fix:**

```bash
# Run diagnostics to see bin_dir and PATH status
hts --fix-env

# To apply the fix automatically (safe, idempotent):
HTS_APPLY_FIX_ENV=1 hts --fix-env

# Then restart your shell or run:
export PATH="$HOME/.local/bin:$PATH"
# OR
export PATH="/usr/local/bin:$PATH"
```

**Verify:**

```bash
hts --which
hts --doctor
```

---

### Permission denied when running `./install.sh`

**Symptom:** `bash: ./install.sh: Permission denied`

**Cause:** The script is not executable.

**Fix:**

```bash
chmod +x ./install.sh
./install.sh --install-deps
```

---

### `jq: command not found` during install

**Symptom:** Installer exits with `[err] missing dependency: jq`

**Cause:** `jq` is required for JSON processing.

**Fix:**

```bash
# macOS
brew install jq

# Debian/Ubuntu
sudo apt-get install jq

# Alpine
apk add jq

# Fedora
sudo dnf install jq

# Arch
sudo pacman -S jq
```

---

## PATH and Environment Issues

### `hts` not found even though it is installed

**Diagnose:**

```bash
hts --fix-env
# This will show:
# - bin_dir where hts is installed
# - on_path whether it is currently on PATH
# - rc_file to edit
# - export_line to add
```

**Fix:**

Add the bin directory to PATH in your shell profile:

```bash
# For Bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# For Zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For macOS (using .zprofile if using Zsh)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zprofile
source ~/.zprofile
```

**Note:** Use `hts --fix-env` to auto-apply safely:

```bash
HTS_APPLY_FIX_ENV=1 hts --fix-env
```

---

### Config directory not found

**Symptom:** `hts --doctor` shows packs directory not found or filter-map.yaml missing.

**Cause:** HTS_CONFIG_DIR is set incorrectly or XDG_CONFIG_HOME points to non-existent path.

**Fix:**

```bash
# Reset to default
unset HTS_CONFIG_DIR

# Or set explicitly
export HTS_CONFIG_DIR="$HOME/.config/haku-token-saver"

# Run doctor to verify
hts --doctor
```

---

### Backend cache stale or wrong

**Symptom:** `hts --which` shows wrong backend even after installing/uninstalling tools.

**Fix:**

```bash
# Remove cache and let hts detect fresh
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver/backend"

# Verify
hts --which
```

---

## Backend Issues

### `snip: command not found` but should be installed

**Symptom:** `hts --which` shows raw backend even though snip was installed.

**Cause:** snip binary path not on PATH.

**Fix:**

```bash
# Find where snip is installed
which snip
# If empty, check these common locations:
ls -la ~/.local/bin/snip
ls -la ~/go/bin/snip

# Add to PATH if needed
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Re-verify
hts --which
hts --self-test
```

**To install snip:**

```bash
# macOS/Homebrew
brew install edouard-claude/tap/snip

# Go
go install github.com/edouard-claude/snip/cmd/snip@latest

# Linux (curl)
curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh
```

---

### `rtk: command not found` but should be installed

**Cause:** npm global prefix not on PATH or rtk not installed globally.

**Fix:**

```bash
# Check npm global prefix
npm config get prefix

# Check if rtk is installed
npm list -g rtk

# If prefix not writable, install under $HOME/.local
npm install -g --prefix ~/.local rtk caveman

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
```

---

### `caveman: command not found`

**Note:** caveman is optional for template workflows. Not required for basic hts routing.

**Fix (if you want template mode):**

```bash
npm install -g caveman

# Or with specific prefix
npm install -g --prefix ~/.local caveman

# Verify
command -v caveman
```

---

### All backends missing, raw-limited fallback

**Symptom:** `hts --which` shows raw, `hts --doctor` shows all backends missing.

**Fix:** Install at least one backend:

```bash
# snip (recommended)
brew install edouard-claude/tap/snip   # macOS
go install github.com/edouard-claude/snip/cmd/snip@latest  # Go

# rtk (Node)
npm install -g rtk

# Verify
hts --self-test
```

---

## Windows-Specific Issues

### Windows PowerShell/CMD not supported

**Cause:** HTS is a Bash tool only.

**Fix:** Use Git Bash or WSL (Windows Subsystem for Linux).

**To install Git Bash:**

1. Download Git for Windows: https://git-scm.com/download/win
2. During install, choose "Git Bash" as default shell.
3. Open Git Bash and install HTS:

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
hts --doctor
```

**To use WSL:**

```bash
# In WSL
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
hts --doctor
```

---

### Git Bash PATH not updated after install

**Symptom:** `hts: command not found` in Git Bash.

**Fix:**

```bash
# In Git Bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

hts --doctor
```

Or use auto-fix:

```bash
HTS_APPLY_FIX_ENV=1 hts --fix-env
```

---

### Line ending issues (CRLF vs LF)

**Symptom:** Script fails with `/bin/bash^M: bad interpreter` or similar.

**Cause:** Files have Windows CRLF line endings instead of Unix LF.

**Fix:** Use Git Bash or configure Git to autocorrect:

```bash
# In Git Bash
git config --global core.autocrlf input

# Or convert line endings manually
dos2unix ./install.sh
dos2unix ./scripts/hts
```

---

## Agent Integration Issues

### Agent reports `hts --doctor failed` during installation

**Cause:** PATH not updated in the agent's shell session.

**Fix:** Add export in agent's runtime profile or run fix-env:

```bash
# In agent session
export PATH="$HOME/.local/bin:$PATH"
hts --doctor
hts --which

# Or install directly to /usr/local/bin (if writable)
./install.sh --prefix /usr/local/bin
```

---

### Hermes authentication 401 or credential errors

**Note:** HTS itself does not perform HTTP auth. This is a Hermes issue.

**Workaround:** Ensure Hermes auth config is separate from HTS config.

```bash
# HTS config dir
echo "$HTS_CONFIG_DIR"  # or ~/.config/haku-token-saver

# Hermes config
echo "$HOME/.hermes"

# Do not mix configs
```

---

### Agent does not respect `hts` routing

**Cause:** Agent instructions missing or overridden.

**Fix:** Add agent rule to project instructions:

```markdown
Use hts as the default interface for verbose terminal inspection. Prefer hts -- <command> or hts workflow commands before raw git diff, git log, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with hts when output is large.
```

**Common recipe:**

```bash
# For observation
hts -- git status
hts -- git log -20
hts -- pytest
hts -- npm test
hts -- docker ps

# For mutation (raw terminal)
npm install
pip install -r requirements.txt
git push

# Then summarize
hts -- git status
```

---

### Claude Code / Cursor / Codex cannot find hts

**Fix:** Ensure hts is on PATH for the IDE's shell:

```bash
# Run this in your terminal, then restart IDE
export PATH="$HOME/.local/bin:$PATH"

# Or add to IDE's shell profile
# VS Code uses /bin/bash or your system shell
# Cursor uses your default shell
```

**Verify from within IDE terminal:**

```bash
hts --doctor
hts --which
```

---

## Self-Test

Run self-test to verify internal checks:

```bash
hts --self-test
hts --self-test --json
```

Expected output (human-readable):

```
hts self-test
passed=7
failed=0
bash_available:pass
backend_valid:pass
config_dir_set:pass
raw_limits_numeric:pass
packs_dir_present:pass
filter_map_present:pass
structured_wrapper_present:pass
```

---

## Getting Help

If issues persist:

1. Run `hts --doctor --json` for full diagnostic output.
2. Run `hts --self-test --json` for internal validation.
3. Run `hts --fix-env` for PATH/environment suggestions.
4. Check [docs/INSTALL.md](INSTALL.md) for platform-specific details.
5. Open an issue with: OS, shell, `hts --doctor --json` output.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `hts --doctor` | Human-readable diagnostics |
| `hts --doctor --json` | Machine-readable diagnostics |
| `hts --self-test` | Internal checks (human-readable) |
| `hts --self-test --json` | Internal checks (JSON) |
| `hts --fix-env` | Show PATH fix suggestions |
| `HTS_APPLY_FIX_ENV=1 hts --fix-env` | Apply PATH fix (safe, idempotent) |
| `hts --which` | Show selected backend |
| `hts --which --json` | Show backend info as JSON |
| `hts --explain -- <cmd>` | Show routing decision |
| `hts --explain --json -- <cmd>` | Routing decision as JSON |