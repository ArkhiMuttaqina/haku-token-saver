# Ecosystem Distribution

Haku Token Saver (HTS) is designed to integrate seamlessly with AI agent ecosystems and coding assistants. This document explains how to:

1. Use HTS with Hermes Agent
2. Submit the `hts-token-saver` skill to the Hermes Skills Hub
3. Add HTS as a custom tap for Hermes users
4. Position HTS for Clawhub.ai discovery

## Hermes Agent Integration

HTS works with Hermes Agent out of the box as a CLI tool. For deeper integration, install the bundled skill:

```bash
# Install HTS globally
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash

# The installer automatically installs the HTS skill to ~/.hermes/skills/development/hts-token-saver
```

The skill provides:

- Agent rules for when to use `hts` vs raw terminal
- Recipes for structured review packets (`git diff`, `hts --review diff`)
- Safe defaults for verbose commands (test runs, build logs)
- Commit/workflow summarization patterns

### Usage in Hermes

When HTS is installed, follow the mental model:

```
observe / inspect / summarize → hts
act / mutate / install / deploy → raw terminal
then summarize again → hts
```

Example prompts Hermes should use:

- "Inspect this repo: `hts -- git status && hts -- git log --oneline -10`"
- "Run tests and summarize: `npm test 2>&1 | hts -- filter npm-test`"
- "Show diff changes: `hts --review diff`"
- "See containers: `hts --detail compact -- docker ps`"

## Publishing to Hermes Skills Hub

To submit the `hts-token-saver` skill to the official Hermes Skills Hub:

1. Ensure your skill metadata is complete in `skills/hts-token-saver/SKILL.md`:
   - `name`, `description`, `version`, `author`, `license`, `platforms`
   - `tags` include hub-friendly keywords
   - `metadata.hermes` block with `homepage`, `source`, `related_skills`

2. Run the publish command from the repo root:

```bash
hermes skills publish skills/hts-token-saver --to github --repo ArkhiMuttaqina/haku-token-saver
```

This prepares the skill for the Hermes Skills Hub. See [Hermes skill creation docs](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills.md).

### Publishing Checklist

- [x] Skill frontmatter complete (`name`, `description`, `version`, `author`, `license`, `platforms`)
- [x] Hub-friendly tags (`hts`, `token-saving`, `shell`, `review-packets`, `hermes`)
- [x] `metadata.hermes` block with `homepage`, `source`, `related_skills`
- [x] MIT license in repo root (LICENSE)
- [x] Practical examples and usage patterns in SKILL.md body
- [ ] Run `hermes skills publish` command
- [ ] Verify skill appears in `hermes skills search` (after hub sync)

## Adding as a Custom Tap

If you want users to discover and install HTS directly from your repo without going through the official hub, add your repo as a custom tap:

```bash
hermes skills tap add ArkhiMuttaqina/haku-token-saver
```

Once added, users can:

```bash
hermes skills search hts          # Should list hts-token-saver
hermes skills install hts-token-saver
```

The skill will be installed at `~/.hermes/skills/development/hts-token-saver` by default.

### Tap Requirements

- Repo must contain a `skills/hts-token-saver/SKILL.md` file
- SKILL.md frontmatter must include `name` and `description`
- The `install.sh` must place the skill at `~/.hermes/skills/development/hts-token-saver` (already done)

## Positioning for Clawhub.ai

Clawhub.ai is a discovery hub for Claw-style tools and agent workflows. To position HTS effectively:

### Key Selling Points

- **Observation layer for shell-capable agents**: reduces noisy CLI output into structured packets
- **Review packet workflows**: `hts --review diff`, `hts --review test` for summarization
- **Safe defaults for verbose commands**: predefined filters for tests, lint, build logs
- **Multi-backend routing**: snip (command-aware), rtk (compression), raw-limited (bounded fallback)
- **Terminal wrapper**: structured output for `docker ps`, `git status`, `ps aux`, etc.

### Metadata for Clawhub

Ensure your repo description and topics highlight these:

```text
Topics: token-saving, shell, hermes, codex, claude-code, opencode, cursor, structured-output, cli-compression
Description: Unified token-saving observation layer for shell-capable agents. Reduces noisy CLI output into structured packets, supports review workflows, and provides safe defaults for verbose commands.
```

Update via gh CLI:

```bash
gh repo edit --add-topic "token-saving,shell,hermes,codex,claude-code,opencode,cursor,structured-output,cli-compression"
gh repo edit --description "Unified token-saving observation layer for shell-capable agents. Reduces noisy CLI output into structured packets, supports review workflows, and provides safe defaults for verbose commands."
```

### Cross-Platform Compatibility

HTS works on Linux, macOS, and Windows (via Git Bash / WSL). Highlight this in listings.

## Installation Flow for Ecosystem Users

When users discover HTS via Hermes Hub or Clawhub, they should be able to install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
```

After installation, they can:

```bash
# Verify installation
hts --doctor
hts --which

# Try it
hts -- git status
hts --detail compact -- docker ps
hts --review diff
```

If using Hermes, the skill is auto-installed to `~/.hermes/skills/development/hts-token-saver`.

## Summary

| Platform | Integration Method |
|----------|-------------------|
| Hermes Agent | CLI tool + bundled skill (`hts-token-saver`) |
| Hermes Skills Hub | Publish via `hermes skills publish` |
| Hermes Custom Tap | `hermes skills tap add ArkhiMuttaqina/haku-token-saver` |
| Clawhub.ai | Repo topics + description positioning |

---

**Next steps:**

1. Run `hermes skills publish` to submit to the official hub
2. Update repo topics and description via `gh repo edit`
3. Ensure LICENSE (MIT) is present and clearly stated
4. Verify skill appears in `hermes skills search` (after hub sync)