---
name: caveman-rtk-integration
description: Integrate Caveman templating with RTK for compact terminal output in repeated workflows. Use wrappers when the same command is run often and raw output is verbose.
version: 1.0.0
---

# Caveman + RTK Integration

Integrate Caveman templating engine with RTK (Rust Token Killer) to minimize token output when formatting CLI results.

## Overview

1. Use RTK to minimize noise from CLI commands.
2. Use Caveman templates to define output structure once.
3. Transmit only variable data between runs.

## Prerequisites

- `npm install -g caveman` (optional: if using `~/bin/caveman`)
- RTK (optional: if available, wrappers respect it)

## Caveman Wrapper

The provided `~/bin/caveman_wrapper.sh` supports:

```bash
~/bin/caveman_wrapper.sh git-status           # git status summary
~/bin/caveman_wrapper.sh git-log 20            # recent commits
~/bin/caveman_wrapper.sh lint src/             # ESLint JSON → short list
~/bin/caveman_wrapper.sh test-results 'npx vitest run'  # test summary
~/bin/caveman_wrapper.sh npm-scripts            # package.json scripts
```

## Caveman Syntax

```text
{{d.variable}}                                    # variable
{{- for d.items as item }}{{item}}{{- end }}     # loop
{{- if d.condition }}yes{{- end }}               # conditional
```

## Example: Git Status Summary

**Template** (`git_status.txt`):

```text
{{- if d.staged }}
Staged ({{ d.staged | length }}):
{{- for d.staged as file }}
  + {{file}}
{{- end }}
{{- end }}
{{- if d.modified }}
Modified ({{ d.modified | length }}):
{{- for d.modified as file }}
  ~ {{file}}
{{- end }}
{{- end }}
```

**Data** (`git_status.json`):

```json
{
  "staged": ["src/app.ts", "src/utils.ts"],
  "modified": ["README.md"]
}
```

**Command**:

```bash
rtk ~/bin/caveman ~/templates/git_status.txt /tmp/git_status.json
```

**Output**:

```
Staged (2):
  + src/app.ts
  + src/utils.ts
Modified (1):
  ~ README.md
```

## Example: Test Results

**Template** (`test_results.txt`):

```text
{{- if d.failed }}
Tests: {{d.passed}}/{{d.total}} passed ({{d.failed}} failed)
{{- for d.suites as suite }}
{{- if suite.status == "failed" }}
  ✗ {{suite.name}} ({{suite.duration}}ms)
{{- end }}
{{- end }}
{{- else }}
All {{d.total}} tests passed
{{- end }}
```

**Data** (`test_results.json`):

```json
{
  "total": 42,
  "passed": 40,
  "failed": 2,
  "suites": [
    {"name": "api", "status": "passed", "duration": 120},
    {"name": "ui", "status": "failed", "duration": 340}
  ]
}
```

## Best Practices

1. Keep templates focused on structure, not logic.
2. Pass only data that changes between runs.
3. Use `rtk` prefix with Caveman wrapper when RTK is available.
4. Keep output short: 1–20 lines is typical.
5. Reuse templates for repeated workflows.

## Debugging

- Test Caveman directly:
  ```bash
  node -e "const c=require('/usr/local/lib/node_modules/caveman/caveman.js');c.register('t','hello {{d.name}}');console.log(c.render('t',{name:'world'}))"
  ```
- Check wrapper logs if data is missing.
- Verify RTK filtering with `rtk proxy` if needed.

## Token Savings Example

| Approach | Output Size | Savings |
|----------|-------------|---------|
| `git status` raw | 500–2000 tokens | — |
| `rtk git status` | 100–400 tokens | ~80% |
| `caveman_wrapper.sh git-status` | 50–200 tokens | ~90% |