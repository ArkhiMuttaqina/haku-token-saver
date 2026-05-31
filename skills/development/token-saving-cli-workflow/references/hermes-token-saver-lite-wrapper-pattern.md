# Haku Token Saver Wrapper Pattern

Session-derived implementation notes for adapting a noisy token-saver starter into a lean class-level workflow.

## Architecture decision

Separate two concerns:

1. Generic backend routing
   - priority: `snip > rtk > raw-limited`
   - one backend per invocation
   - direct argv execution only

2. Curated template workflows
   - `git-status`
   - `git-log`
   - `lint`
   - `test-results`
   - `npm-scripts`

Do not describe template workflows as generic backend fallback.

## Installer pattern

Recommended `install.sh` behavior:
- detect optional backends but do not auto-install them
- print manual install guidance for `snip`
- write backend cache under `~/.config/haku-token-saver/backend`
- avoid modifying shell profile unless user opted in (`--with-shell-profile`)
- install scripts/templates/config/skills deterministically
- expose `--dry-run`

## Wrapper pattern

Recommended wrapper behaviors:
- `--which` prints effective backend
- `--dry-run` prints selected backend and exact command
- `--backend auto|snip|rtk|raw` with raw bounded by default unless `--no-limit` is explicit
- `--template <workflow>` routes to template wrapper
- `HAKU_TOKEN_SAVER_BACKEND` env override
- `HAKU_TOKEN_SAVER_STRICT=true` turns missing selected backend into hard failure

## Reliability lesson

If template wrapper depends on optional tools (`rtk`, `caveman`), add graceful fallback:
- create template directory automatically
- if formatter exists, render normally
- else output compact JSON/text via `jq -c` or `cat`

This avoids smoke tests failing just because optional formatter tools are absent.

## Documentation lesson

README/docs/config/skill text should state clearly:
- `snip` is preferred generic backend
- `rtk` is fallback generic backend
- Caveman is used here as terse/template inspiration, not generic CLI fallback
- raw mode remains available for debugging and exact-output cases
