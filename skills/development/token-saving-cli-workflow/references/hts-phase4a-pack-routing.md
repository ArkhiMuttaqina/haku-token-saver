# hts Phase 4A: Pack Routing + Doctor/Init

Session-derived implementation notes for adapting `Haku-token-saver` into a ready-to-use `hts` bootstrapper around `snip`.

## Goal

Make install immediately usable:
- `hts` orchestrates backends; it is not the filter library.
- Prefer backend order: `snip > rtk > raw-limited`.
- Use `snip` as main filter engine (127+ filters).
- Add project bootstrap and diagnostics.

## Files Added

```text
packs/git.yaml
packs/node.yaml
packs/python.yaml
packs/docker.yaml
config/filter-map.yaml
```

## hts CLI Additions

### `hts --doctor`

Reports:
- `snip` / `rtk` availability and paths
- backend cache path and cached backend value
- config dir, packs dir, filter-map presence
- available packs with descriptions
- project `.hts.json` status

### `hts --init`

Creates `.hts.json` in current project:

```json
{
  "packs": ["git", "node", "python", "docker"],
  "backend": "auto",
  "created": "2026-05-31T12:00:00+07:00"
}
```

Detection used:
- `.git` or `git` command -> git pack
- `package.json`, npm/pnpm/yarn -> node pack
- `pyproject.toml`, `requirements.txt`, python/pytest -> python pack
- `Dockerfile`, docker-compose files, docker command -> docker pack
- fallback: `git`

## Pack Schema

```yaml
name: git
description: Enable git-focused templates and snip filters
filters:
  - git-status
  - git-log
aliases:
  - status
  - log
detect:
  files:
    - .git
  commands:
    - git
```

## Resolver Pattern

Add `normalize_command_for_snip()` to map command families to snip filters.

Examples:

```text
git status       -> git-status
git log          -> git-log
npm test         -> vitest
npm install      -> npm-install
npx eslint src/  -> eslint
python -m pytest -> pytest
docker ps        -> docker-ps
docker logs x    -> docker-logs
kubectl logs pod -> kubectl-logs
gh pr list       -> gh-pr
pytest           -> pytest
ruff check .     -> ruff
```

Execution pattern:

```bash
SNIP_FILTER="$(normalize_command_for_snip "$@")"
exec snip --filter "$SNIP_FILTER" -- "$@"
```

Dry-run pattern:

```bash
echo "snip ${SNIP_FILTER:-$1} -- $*"
```

## Backward Compatibility

Even after renaming the wrapper to `hts`, keep old cache path unless explicitly migrating:

```bash
BACKEND_CACHE="${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver/backend"
```

This prevents breaking previous installs and preserves stored backend choice.

## Docs Update Checklist

When adding this feature, update:
- `README.md`: architecture, install, `--doctor`, `--init`, packs table, examples
- `docs/README.md`: index pointing to packs/config/router
- `install.sh`: copy new `hts`, keep cache path consistent
- `config/CLAUDE.md`: command usage snippets
- token-saving skill references if this becomes reusable pattern

## Verification

Run:

```bash
bash -n install.sh scripts/hts scripts/caveman_wrapper.sh
./scripts/hts --doctor
./scripts/hts --dry-run --backend snip -- git status
./scripts/hts --dry-run --backend snip -- npm test
./scripts/hts --dry-run --backend snip -- docker ps
./scripts/hts --dry-run --template status
tmp=$(mktemp -d)
(cd "$tmp" && /path/to/scripts/hts --init && python3 -m json.tool .hts.json >/dev/null)
```

Note: If `snip`/`rtk` are missing locally, dry-run may still show final fallback backend as `raw`. To inspect filter routing regardless of installed tools, check the dry-run message before fallback or force a fake snip in PATH during tests.
