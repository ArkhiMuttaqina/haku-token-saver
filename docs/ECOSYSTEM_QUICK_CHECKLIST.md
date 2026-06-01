# Ecosystem Distribution — Quick Checklist

This is the short version of `ECOSYSTEM_DISTRIBUTION.md` for quick reference.

## Hermes Skills Hub

Run from repo root:

```bash
hermes skills publish $(pwd)/skills/hts-token-saver --to github --repo ArkhiMuttaqina/haku-token-saver
```

Requirements:
- `gh auth login` (GitHub CLI authenticated)
- Or `GITHUB_TOKEN` in `~/.hermes/.env`

The skill is now hub-friendly (scan SAFE) with complete frontmatter.

## Hermes Custom Tap

For users to discover HTS from your repo without going through the hub:

```bash
hermes skills tap add ArkhiMuttaqina/haku-token-saver
```

Then:

```bash
hermes skills search hts
hermes skills install hts-token-saver
```

## Clawhub.ai Positioning

Run these to update repo metadata (requires `gh` CLI):

```bash
# Topics
gh repo edit --add-topic "token-saving,shell,hermes,codex,claude-code,opencode,cursor,structured-output,cli-compression"

# Description
gh repo edit --description "Unified token-saving observation layer for shell-capable agents. Reduces noisy CLI output into structured packets, supports review workflows, and provides safe defaults for verbose commands."
```

## User Installation

Users can install HTS with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
```

The installer places:
- Binaries at `~/bin/hts`
- Skill at `~/.hermes/skills/development/hts-token-saver`
- Config at `~/.config/haku-token-saver/`

## Files Changed in This Sprint

- `LICENSE` — MIT license added
- `skills/hts-token-saver/SKILL.md` — frontmatter updated (version, author, license, platforms, metadata.hermes), scan-safe (removed curl|bash triggers)
- `docs/ECOSYSTEM_DISTRIBUTION.md` — full ecosystem guide created
- `README.md` — added Hermes ecosystem section (tap, publish, hub reference)

## Validation Done

- `bash -n install.sh` — OK
- `bash -n scripts/hts` — OK
- YAML frontmatter parse — OK (name, license, homepage)
- `hermes skills publish` scan — SAFE (blocked only by auth, not by supply-chain scan)
- Uninstall/reinstall cycle — OK, skill installed to `~/.hermes/skills/development/hts-token-saver`

## Next Steps (Manual)

- Run `gh auth login` (or set `GITHUB_TOKEN`) then run the publish command above
- Run the `gh repo edit` commands to update topics/description (for Clawhub positioning)
- Push all changes to `main` branch
- Verify skill appears in `hermes skills search` (after hub sync)