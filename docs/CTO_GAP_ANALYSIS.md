# CTO Gap Analysis — Haku Token Saver (hts)

Generated: `2025-03-20`
Auditor: Haku (as CTO)
Repo: `arkhi25/Haku-token-saver`

---

## Executive Summary

- **Installer**: hardening completed (eval removed, direct argv)
- **Architecture**: backend priority (snip > rtk > raw-limited) implemented correctly
- **Doc consistency**: mostly aligned, with drift on env variable naming and agent adaptation snippets
- **Operational quality**: skill canonical; installer verified; hts --doctor passes
- **Gaps to close**: 5 high-priority + 3 medium-priority items

---

## Audit Basis

- Installed canonical skill: `~/.hermes/skills/development/hts-token-saver/SKILL.md`
- Staged changes:
  - `README.md` +29
  - `install.sh` 16 changed (hardening patch added)
  - `skills/hts-token-saver/SKILL.md` +315 (new consolidated skill)
- Shell validation: `bash -n install.sh scripts/hts scripts/caveman_wrapper.sh` → OK
- Smoke test: `hts --doctor`, `hts --packs`, `hts --filters '^git-'`, `hts --review diff`, `hts --compress README.md --limit 120` → OK
- Hardcoded user path noted: `SYNC_SNIP_FROM="/home/arkhi25/Repo/references/agentic/snip"` in `scripts/hts`

---

## High-Priority Gaps

| # | Area | Gap | Impact | Action | Owner |
|---|------|-----|--------|--------|-------|
| 1 | Installer hardening | `eval "$@"` used in `run_cmd()`; install calls pass strings instead of argv | Security & robustness | Replaced `eval "$@"` with `"$@"`; array expansions `"${missing[@]}"`; pipeline via `sh -c '... | sh'` | ✅ Done |
| 2 | Hardcoded user path | `SYNC_SNIP_FROM` defaults to `/home/arkhi25/Repo/references/agentic/snip` | Portability; breaks on other machines | Make it optional via env + fallback to repo-relative `../snip` or upstream remote URL | ✅ Done |
| 3 | Env var naming drift | `HAKU_TOKEN_SAVER_*` prefixes still referenced in skill + scripts; but current repo leans `HTS_*` only for runtime caps | Confusion for integrators; inconsistent branding | Choose one prefix, deprecate other with migration note in docs + skill | ✅ Done |
| 4 | Config versioning | No `.hts.json` schema version; future format changes risk breaking init logic | Stability and migrations | Add `"$schemaVersion": 1` to generated `.hts.json`; handle version bump in `init` mode | ✅ Done |
| 5 | Documentation drift in agent snippets | `docs/AGENTIC_SUPPORT.md` may not reflect skill’s canonical operating model and updated command examples (`hts -- git status` vs old `hts git status`) | Agent adoption friction | Audit and unify agent snippets with skill content; mark as source of truth | ✅ Done |

---

## Medium-Priority Gaps

| # | Area | Gap | Impact | Action | Owner |
|---|------|-----|--------|--------|-------|
| 6 | Install verification depth | `verify()` checks binaries and file existence; does not call `hts --filters`/`hts --packs` in post-install | Catch config sync errors late | Add `hts --packs >/dev/null 2>&1` and `hts --filters '^git-' >/dev/null 2>&1` to verify smoke config | ✅ Done |
| 7 | Missing rollback capability | `install.sh` can overwrite existing artifacts but has no uninstall or rollback path | Hard to cleanly revert; tests messy | Add `./install.sh --uninstall` that removes installed files and cleans skill dir | ✅ Done |
| 8 | Skill integration with LightRAG | Memory entry mentions updating LightRAG KB on doc changes; no automation today | Knowledge base drift; agents see stale info | Add CI or repo hook that triggers sync on docs/ + skill/ changes (optional) | — |

---

## Low-Priority / Observations

- `scripts/hts` is ~974 lines; consider splitting into libs (backend, packs, workflows) to aid testing and reuse.
- `config/snip-filters.txt` is synced inventory; no auto-sync on upstream filter updates → OK for now (manual sync via `hts --sync-snip-filters`).
- `caveman_wrapper.sh` provides template workflows; no test coverage for template render logic → acceptable for now; consider integration test later.

---

## Implementation Plan

### Sprint A — Hardening & Portability (next 2 days)

1. Close Gap 2 (hardcoded user path)
   - Edit `scripts/hts`: `SYNC_SNIP_FROM` fallback to `$REPO_DIR/../snip` if not set
   - Document env override in `docs/USAGE.md` and skill

2. Close Gap 3 (env var naming)
   - Choose `HTS_*` as primary runtime prefix
   - Add migration note to `README.md` and skill: `HAKU_TOKEN_SAVER_BACKEND` → `HTS_BACKEND` (keep alias for compatibility)
   - Add alias support in `scripts/hts` for `HAKU_TOKEN_SAVER_*` → `HTS_*`

3. Close Gap 4 (config versioning)
   - Update `.hts.json` template in `hts --init`: add `"schemaVersion": 1`
   - Document schema version in `docs/ADDING_FILTERS.md`

### Sprint B — Documentation & Verification (following 2 days)

4. Close Gap 5 (agent snippet drift)
   - Audit `docs/AGENTIC_SUPPORT.md` against skill content
   - Mark skill as source of truth; generate snippets from skill where possible
   - Update `README.md` “Prompt install for AI agents” section with exact examples from skill

5. Close Gap 6 (deepen install verification)
   - Add smoke config checks to `verify()` in `install.sh`
   - Ensure `hts --doctor` and `hts --packs` run in install verification

### Sprint C — Operations & Hygiene (as needed)

6. Close Gap 7 (uninstall)
   - Design `./install.sh --uninstall` flow:
     - remove `~/bin/hts` + wrappers
     - clean `~/.config/haku-token-saver`
     - remove skill from `~/.hermes/skills/development/hts-token-saver`
     - prompt to clean shell aliases

7. Close Gap 8 (LightRAG sync automation) — optional
   - Decide if CI/CD exists; if not, this can wait
   - If CI present, add workflow that calls user LightRAG sync endpoint after docs/ + skill/ changes

---

## Risks & Decisions

- **Env var naming**: Changing `HAKU_TOKEN_SAVER_*` to `HTS_*` may break existing user setups. Decision: keep aliases, deprecate with warning in next minor release, then remove in major.
- **Hardcoded path**: Current `SYNC_SNIP_FROM` works only for arkhi25; breaking for others. Decision: provide fallback + env, but keep existing default for now to avoid regressions.
- **Config versioning**: Adding version to `.hts.json` is low-risk; ensures forward compatibility. Decision: add immediately.

---

## Verification Checklist

After implementing above:

- [x] `./install.sh --dry-run` passes
- [x] `./install.sh --skip-deps` runs end-to-end and `verify()` succeeds
- [x] `hts --init` creates `.hts.json` with `schemaVersion: 1`
- [x] `hts --doctor` shows config packs and filter-map found
- [x] Agent snippets in `docs/AGENTIC_SUPPORT.md` match skill examples
- [x] Env alias mapping works: `HAKU_TOKEN_SAVER_BACKEND` → `HTS_BACKEND`
- [x] `SYNC_SNIP_FROM` works via env override and repo-relative fallback
- [x] `verify()` runs `hts --packs` and `hts --filters '^git-'`

---

## Change History

| Date | Action |
|------|--------|
| 2025-03-20 | Initial CTO audit; installer hardening patch applied (`eval` → `"$@"`) |
| 2026-06-01 | Sprint A/B/C completed: portable path, env canonicalization, schema version, docs sync, verify hardening, uninstall implemented; verification checklist all pass |
