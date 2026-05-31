---
name: context-optimization
description: Keep terminal usage lean. Prefer compact flags, structured output, hts backend routing, and stable template summaries. Use when output is noisy or token usage is climbing.
category: software-development
---

# Context Optimization

Use this skill to reduce terminal noise and token spend without hiding critical failures.

## Goals

- Reduce verbose command output.
- Prefer source-level compaction before post-processing.
- Use generic backend routing for noisy commands.
- Reuse stable summary wrappers for repeated workflows.
- Preserve full evidence when needed.

## Backend Model

Primary wrapper:

```bash
hts -- <command>
```

Backend priority:

```text
manual override > cached backend > auto detect > raw
snip > rtk > raw-limited
```

Rules:

1. Never chain `snip -> rtk`.
2. Preserve command exit code.
3. Use direct argv execution; avoid shell eval.
4. Fallback to raw unless strict mode is explicitly enabled.
5. Keep raw mode available for debugging.

## Rules

1. Prefer narrow flags first.
   - `git status --porcelain`
   - JSON reporters for lint and tests
   - limit counts, files, and log depth
2. Use `hts` for noisy direct commands.
3. Use template mode for repeated summaries.
4. Keep summaries short, stable, and comparable between runs.
5. Do not dump full logs unless the user asks or failure analysis requires it.
6. Use normal detail for security, irreversible actions, migrations, and architecture tradeoffs.

## Common Substitutions

```bash
git status
# becomes
hts -- git status
# or stable summary
hts --template git-status
```

```bash
git log --oneline -50
# becomes
hts --template git-log 20
```

```bash
npx eslint src/
# becomes
hts --template lint src/
```

```bash
npx vitest run
# becomes
hts --template test-results 'npx vitest run'
```

```bash
npm test
# becomes
hts -- npm test
```

## Caveman Adaptation

Official Caveman is treated as:

- response brevity policy
- summary/template inspiration
- memory/config compression pattern

It is not part of the automatic backend fallback chain.

### Terse Response Policy

Use Caveman-style brevity for agent-facing reports:

- drop filler and greetings
- lead with result/status
- keep commands, code, errors, paths, URLs, and identifiers exact
- prefer bullets over paragraphs for status reports
- show only failing/changed/important lines by default
- mention omitted detail only when it affects debugging

Use normal detail for:

- security warnings
- irreversible actions
- multi-step migrations
- architecture tradeoffs
- ambiguous failure analysis
- user explicitly asking for full explanation/logs

### Memory / Config Compression Guide

For `CLAUDE.md`, `AGENTS.md`, skills, and docs:

1. Remove duplicate prose and motivational wording.
2. Keep trigger conditions, commands, file paths, and verification steps.
3. Convert narrative guidance into ordered rules/checklists.
4. Preserve caveats that prevent unsafe behavior.
5. Keep one canonical source; link instead of repeating.

## Checklist

```bash
hts --which
hts --dry-run -- git status
hts --template git-status
```

Optional:

```bash
rtk gain || true
~/bin/verify_caveman_setup.sh
```

## When Not to Filter

Use raw output for:

- full logs requested by user
- full stack traces needed for diagnosis
- flaky CI or installer failures
- security-sensitive reviews
- interactive commands
- exact byte-for-byte output

## Success Criteria

- Repeated workflows use templates.
- Generic noisy commands use backend routing.
- Output is human-readable in a few lines.
- Full command output is avoided by default.
- Critical failures remain visible.
