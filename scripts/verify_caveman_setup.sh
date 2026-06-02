#!/usr/bin/env bash
set -euo pipefail

ok() { printf '[ok] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1"; }
err() { printf '[err] %s\n' "$1" >&2; exit 1; }

printf 'Haku Token Saver verification\n'

[ -x "$HOME/bin/caveman_wrapper.sh" ] || err "missing ~/bin/caveman_wrapper.sh"
ok "workflow wrapper executable"

if command -v caveman >/dev/null 2>&1 || [ -x "$HOME/bin/caveman" ]; then
  ok "caveman available"
else
  warn "caveman missing; install: npm install -g caveman"
fi

if command -v rtk >/dev/null 2>&1; then
  ok "rtk available"
else
  warn "rtk missing; wrappers run without RTK filtering"
fi

for t in git_status.txt lint_results.txt test_results.txt; do
  [ -f "$HOME/templates/$t" ] || err "missing template: $t"
  ok "template: $t"
done

if [ -d .git ]; then
  "$HOME/bin/caveman_wrapper.sh" git-status >/tmp/token-saver-git-status.out 2>&1 || err "git-status workflow failed"
  ok "git-status workflow runs"
else
  warn "not in git repo; skipped git-status runtime check"
fi

if grep -q 'Haku Token Saver Aliases' "$HOME/.zshrc" 2>/dev/null; then
  ok "aliases present"
else
  warn "aliases not found in ~/.zshrc"
fi

printf 'Done.\n'
