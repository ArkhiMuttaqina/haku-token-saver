# Template: git-diff-stat

Command class: `git diff --stat`

Preferred source:

```bash
git diff --stat
git diff --numstat
```

## Compact render

```text
Diff summary
- files changed: <n>
- insertions: <n>
- deletions: <n>

Top changed files
1. <file>
   +<n> -<n>

Signals
- generated/binary files changed
- large churn files

Metadata
- formatter: git/git-diff-stat
- mode: compact
```
