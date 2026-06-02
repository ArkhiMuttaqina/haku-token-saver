# Template: git-status

Command class: `git status`

Preferred source:

```bash
git status --short --branch
```

## Compact render

```text
Git summary
- branch: <branch>
- ahead/behind: <state>
- staged: <n>
- modified: <n>
- untracked: <n>

Staged
- <file>

Modified
- <file>

Untracked
- <file>

Metadata
- formatter: git/git-status
- mode: compact
```

## Key signals
- merge conflict
- detached HEAD
- dirty working tree
