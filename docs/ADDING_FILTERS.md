# Add or customize filters in `hts`

This is a practical guide for adding new mappings or new pack presets.

---

## Before you start

Check what exists:

```bash
hts --filters
hts --filters '^pattern'
hts --packs
```

Dry-run with a command:

```bash
hts --dry-run -- your-command
```

---

## Quick decision tree

| Want to add | Go here |
|-------------|---------|
| New alias / workflow name | `config/filter-map.yaml` → `aliases` |
| New command family | `config/filter-map.yaml` → `command_families` |
| New project pack | `packs/*.yaml` |
| More upstream filters | `hts --sync-snip-filters` |
| Template workflow | `scripts/caveman_wrapper.sh` |

---

## Add a new alias

Edit `config/filter-map.yaml`:

```yaml
aliases:
  your-alias:
    snip: [filter-name]
    template: optional-template-name
```

Example:

```yaml
aliases:
  db-migrate:
    snip: [rails-migrate, prisma-migrate]
```

Then check:

```bash
hts --dry-run -- rails db:migrate
```

---

## Add a new command family

Edit `config/filter-map.yaml`:

```yaml
command_families:
  your-command: existing-or-new-alias
```

Example:

```yaml
command_families:
  db-migrate: db-migrate
```

Then check:

```bash
hts --dry-run -- db-migrate
```

---

## Add a pack preset

Create or edit a file in `packs/*.yaml`:

Example `packs/go.yaml`:

```yaml
name: go
filters:
  - go-test
  - go-build
  - go-vet
```

Then re-init:

```bash
hts --init
```

Check:

```bash
cat .hts.json
hts --packs
```

---

## Refresh upstream snip filters

Run:

```bash
hts --sync-snip-filters
```

This writes to `config/snip-filters.txt`.

Custom source:

```bash
hts --sync-snip-filters --from /path/to/snip
```

Check result:

```bash
wc -l config/snip-filters.txt
```

---

## Work with synced inventory

When a new snip filter exists upstream but not in mapping:

1. Sync inventory:

   ```bash
   hts --sync-snip-filters
   ```

2. Find the filter:

   ```bash
   hts --filters 'terraform'
   ```

3. Add mapping in `config/filter-map.yaml`:

   ```yaml
   aliases:
     terraform:
       snip: [terraform]
   ```

---

## Use multiple candidate filters

Sometimes one command can map to several possible tools.

Example:

```yaml
aliases:
  test:
    snip: [pytest, vitest, jest]
    template: test-results
```

`hts` will try the best match based on command family detection.

---

## Add template workflow

Edit `scripts/caveman_wrapper.sh`.

Add a template for your workflow.

Example:

```bash
git-status-template() {
  # your logic
}
```

Then wire alias:

```yaml
aliases:
  status:
    template: git-status
```

Use:

```bash
hts --template status
```

---

## Common editing mistakes

### Missing colon after key

Bad:

```yaml
aliases
  status:
    snip: [git-status]
```

Good:

```yaml
aliases:
  status:
    snip: [git-status]
```

### Incorrect list formatting

Bad:

```yaml
snip: git-status
```

Good:

```yaml
snip: [git-status]
```

### Forgetting to run `--dry-run` after edits

Always check:

```bash
hts --dry-run -- your-command
```

---

## Verify before committing

Syntax check:

```bash
bash -n scripts/hts
```

Filter sync:

```bash
hts --sync-snip-filters
```

Pack check:

```bash
hts --packs
```

Dry-run a sample command:

```bash
hts --dry-run -- git status
```

---

## Quick recipe examples

### Add a custom docker command filter

Step 1: Check upstream filter exists:

```bash
hts --filters docker
```

Step 2: If exists, add mapping:

```yaml
aliases:
  my-docker:
    snip: [docker-custom]
```

Step 3: Verify:

```bash
hts --dry-run -- docker-custom-cmd
```

### Add a new project type for a custom stack

Step 1: Create pack file:

```bash
touch packs/custom-stack.yaml
```

Step 2: Edit content:

```yaml
name: custom-stack
filters:
  - custom-tool-command1
  - custom-tool-command2
```

Step 3: Re-init in project:

```bash
cd my-custom-project
hts --init
```

### Map a new CI command family

```yaml
command_families:
  ci-build: build

aliases:
  build:
    snip: [ci-build-filter]
```

Then use:

```bash
hts -- ci-build
```

---

## When to prefer snip filters vs custom scripts

Rule of thumb:

- Use `snip` filters for stable, declarative, declaratively-maintained rules
- Use custom scripts or templates for domain-specific workflows

`hts` focuses on orchestration, not implementing new filter logic.

For deep custom filtering, consider:

- editing upstream snip filter
- adding a custom template script
- using a dedicated tersifier tool

---

## Sync after snip update

If upstream snip adds new filters:

```bash
hts --sync-snip-filters
hts --filters 'new-tool'
```

Then map if needed as shown above.