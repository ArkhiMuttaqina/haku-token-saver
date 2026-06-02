# Filter language in `hts`

`hts` does not define a full parser DSL for filters.

It uses a practical mapping layer that decides:

1. which command family a command belongs to
2. which alias/workflow that family maps to
3. which `snip` filter or template should be used

Main file:

```text
config/filter-map.yaml
```

---

## Structure

`config/filter-map.yaml` has two main sections:

```yaml
aliases:
  ...

command_families:
  ...
```

### `aliases`

`aliases` define human-facing workflow names.

Each alias can map to:

- one or more `snip` filters
- optional `template` workflow

Example:

```yaml
aliases:
  status:
    snip: [git-status]
    template: git-status

  test:
    snip: [pytest, vitest, jest]
    template: test-results
```

Meaning:

- alias `status` prefers `git-status` filter
- alias `test` can resolve to multiple possible filters
- alias can also point to a template workflow for structured output

### `command_families`

`command_families` map detected command names to aliases.

Example:

```yaml
command_families:
  git: status
  pytest: test
  vitest: test
  jest: test
  docker-logs: logs
```

Meaning:

- when `hts` sees `git`, it can route through alias `status`
- when `hts` sees `pytest`, it routes through alias `test`

---

## Resolution model

Simplified flow:

```text
command
  -> command family
  -> alias
  -> candidate snip filters / template
  -> backend execution
```

Example:

```bash
hts -- git status
```

Conceptually becomes:

```text
git -> status -> git-status -> snip --filter git-status -- git status
```

Another example:

```bash
hts -- pytest
```

Conceptually becomes:

```text
pytest -> test -> pytest -> snip --filter pytest -- pytest
```

---

## Alias shape

Typical alias entry:

```yaml
lint:
  snip: [eslint, ruff, mypy, shellcheck]
  template: lint
```

Fields:

| Field | Required | Meaning |
|-------|----------|---------|
| `snip` | no | candidate snip filters |
| `template` | no | workflow template name |

Notes:

- `snip` is usually a list
- `template` is optional
- one alias can support many ecosystems

---

## Command family shape

Typical entry:

```yaml
eslint: lint
ruff: lint
mypy: lint
```

Meaning:

- these commands all belong to the `lint` workflow family
- `hts` can share one semantic route across multiple tools

This keeps the mapping small and reusable.

---

## Why this is called filter language

It is not a full language like a compiler grammar.

It is a lightweight routing language for:

- command intent
- filter selection
- workflow naming
- backend normalization

You edit YAML, not code, for most customizations.

---

## Current design rules

### 1. Alias names should be semantic

Good:

- `status`
- `test`
- `lint`
- `logs`
- `build`

Less ideal:

- `pytest-only`
- `docker-logs-prod-k8s`

Use semantic names first. Add tool-specific filters under them.

### 2. Prefer upstream snip filter names unchanged

Good:

```yaml
snip: [git-status]
```

Avoid renaming upstream filter IDs unless there is a real reason.

### 3. Template names should describe workflow, not brand

Good:

- `git-status`
- `test-results`
- `lint`

This keeps `hts` independent from upstream implementation details.

### 4. One command family can map to one alias

Example:

```yaml
pytest: test
vitest: test
jest: test
```

This is intentional. Different tools, same workflow intent.

---

## Ecosystem mapping examples

`hts` groups many commands by workflow intent instead of by language brand.

### Python

```yaml
aliases:
  test:
    snip: [pytest, vitest, jest, go-test]
  lint:
    snip: [eslint, ruff, mypy]
  install:
    snip: [pip-install, poetry-install]
  sync:
    snip: [uv-sync]

command_families:
  python: test
  python3: test
  pytest: test
  ruff: lint
  mypy: lint
  pip: install
  pip3: install
  uv: sync
  poetry: install
```

Use direct commands for observation:

```bash
hts -- pytest
hts -- ruff check .
hts -- mypy .
```

Use raw commands for mutation-heavy package actions, then summarize with `hts`:

```bash
pip install -r requirements.txt
hts -- pytest
```

### Node.js / TypeScript

```yaml
command_families:
  node: install
  npm: install
  pnpm: install
  yarn: install
  bun: install
  vitest: test
  jest: test
  eslint: lint
  tsc: check
```

Common observation commands:

```bash
hts -- npm test
hts -- pnpm test
hts -- bun test
hts -- eslint .
hts -- tsc --noEmit
```

### Go

```yaml
command_families:
  go: build
  go-test: test
  go-vet: check
  golangci-lint: lint
```

Common observation commands:

```bash
hts -- go test ./...
hts -- go vet ./...
hts -- golangci-lint run
```

### Rule of thumb

- tests/lint/typecheck/logs/review -> prefer `hts`
- install/build/run/deploy/migration -> raw terminal first, then summarize with `hts`
- exact stack trace needed -> `hts --no-limit --backend raw -- <command>`
- unknown filter -> keep `hts` in front and let `raw-limited` cap output

Fallback chain:

```text
specific snip filter -> generic snip filter -> rtk -> caveman template -> raw-limited
```

Current implementation guarantee:

```text
snip backend if available -> rtk if available -> raw-limited
```

---

## Common patterns

### Single-filter alias

```yaml
status:
  snip: [git-status]
```

### Multi-filter alias

```yaml
test:
  snip: [pytest, vitest, jest, go-test]
  template: test-results
```

### Template-only workflow

```yaml
summary:
  template: lint
```

### Cross-tool family mapping

```yaml
pytest: test
vitest: test
jest: test
```

---

## What `hts` does not do here

This mapping file is not for:

- shell scripting
- regex transform pipelines
- output rewrite logic
- large parser rules

Those belong upstream to tools like `snip`, `awk`, `sed`, or shell scripts.

`hts` stays at orchestration level.

---

## Relationship to `snip`

`snip` filters are the real output-filter layer.

`hts` only helps select the right one.

Useful commands:

```bash
hts --filters
hts --filters '^git-'
hts --sync-snip-filters
```

Reference inventory:

- `config/snip-filters.txt`
- local snip repo under `filters/*.yaml`

---

## Relationship to packs

Packs are separate from filter language.

- filter language answers: "which filter/workflow fits this command?"
- packs answer: "which tool families are relevant in this project?"

Examples:

- `packs/git.yaml`
- `packs/node.yaml`
- `packs/python.yaml`
- `packs/docker.yaml`

---

## Editing safely

Before editing mapping:

```bash
hts --filters
hts --dry-run -- git status
```

After editing mapping:

```bash
bash -n scripts/hts
hts --dry-run -- git status
hts --dry-run -- pytest
```

If you changed upstream inventory too:

```bash
hts --sync-snip-filters
```

---

## Minimal example

```yaml
aliases:
  logs:
    snip: [docker-logs, kubectl-logs]
    template: test-results

command_families:
  docker-logs: logs
  kubectl-logs: logs
```

Result:

- both docker and kubectl logs can share one logical workflow
- agent can request a single concept: `logs`
- backend still uses tool-appropriate filter IDs
