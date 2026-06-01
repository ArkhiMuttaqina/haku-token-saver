# Installation

HTS is a shell-only tool (Bash). Tested platforms:

- ✅ Linux (Debian/Ubuntu, Arch, Alpine)
- ✅ macOS
- ✅ Windows via Git Bash or WSL
- ❌ Windows PowerShell / CMD (not supported)

## Quick install (Linux/macOS)

### One-line curl (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
```

### Clone install (fallback)

```bash
git clone https://github.com/ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

## Windows via Git Bash / WSL

HTS runs inside Git Bash or WSL (same as Unix-like).

```bash
# In Git Bash or WSL:
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
hts --doctor
```

If your Git Bash `~/.local/bin` is not on PATH, add it to Git Bash `.bashrc`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Install path rules

HTS uses portable, predictable paths. You can override via environment or installer flag.

| Component | Default path | Override |
|-----------|--------------|----------|
| **Binaries** (`hts`, wrappers) | First writable in order: <br>1. `/usr/local/bin` <br>2. `~/.local/bin` <br>3. `~/bin` | `export PREFIX=/custom/bin` <br>or `./install.sh --prefix /custom/bin` |
| **Config** (filters, templates, backend cache) | `${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver` | `export HTS_CONFIG_DIR=/custom/config` |
| **Hermes skills** | `~/.hermes/skills/development/hts-token-saver` | Hardcoded by Hermes; do not override |

### Behavior

- **Binaries**: Installer tries `/usr/local/bin` first. If not writable, falls back to `~/.local/bin`, then `~/bin`. Creates missing directories automatically.
- **Config**: Always under XDG base `~/.config/haku-token-saver` unless `HTS_CONFIG_DIR` is set.
- **Hermes skills**: Placed at `~/.hermes/skills/development/hts-token-saver` by the installer.

### Windows (Git Bash / WSL)

HTS on Windows uses Unix paths inside Git Bash/WSL:

- Binaries: `~/.local/bin` (recommended) or `~/bin`
- Config: `~/.config/haku-token-saver`
- Skills: `~/.hermes/skills/development/hts-token-saver`

HTS does **not** support native Windows PowerShell paths like `$HOME\AppData\Local`. Use Git Bash or WSL.

## Verify installation

```bash
hts --doctor
hts --which
```

Backend priority: `snip > rtk > raw-limited`.

## Uninstall

```bash
# From the original clone or any shell:
./install.sh --uninstall
```

Or from a tarball bootstrapped install:

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash -s -- --uninstall
```

Removes binaries, config, templates, and Hermes skills.

## Dependency installation

The installer (`--install-deps` flag) automatically installs or verifies:

- `snip` (binary Go tool) — primary filter backend
- `rtk` (Node) — fallback compression backend
- `caveman` (Node) — template formatting

If auto-install fails, install manually:

```bash
# snip
brew install edouard-claude/tap/snip   # macOS/Homebrew
go install github.com/edouard-claude/snip/cmd/snip@latest  # Go
curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh  # Linux

# rtk + caveman
npm install -g rtk caveman
```

## Environment variables

Canonical namespace: `HTS_*`. Place in shell profile (`.bashrc`, `.zshrc`) or `.env` file.

| Variable | Purpose | Example |
|----------|---------|---------|
| `HTS_BACKEND` | Force backend: `snip`, `rtk`, or `raw` | `export HTS_BACKEND=snip` |
| `HTS_CONFIG_DIR` | Override config directory | `export HTS_CONFIG_DIR=/opt/hts-config` |
| `HTS_STRICT` | Fail if selected backend unavailable | `export HTS_STRICT=1` |
| `HTS_SNIP_REF` | Local snip repo path | `export HTS_SNIP_REF=~/repo/snip` |
| `HTS_RAW_MAX_LINES` | Raw fallback line cap | `export HTS_RAW_MAX_LINES=500` |
| `HTS_RAW_MAX_BYTES` | Raw fallback byte cap | `export HTS_RAW_MAX_BYTES=100000` |

Legacy aliases supported: `HAKU_TOKEN_SAVER_BACKEND`, `HAKU_TOKEN_SAVER_STRICT`.