#!/usr/bin/env bash
set -euo pipefail

printf 'Token saver demo\n\n'

WORKDIR=/tmp/token_saver_demo_repo
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

git init -q
git config user.email demo@example.com
git config user.name demo
echo 'line1' > file1.txt
echo 'line2' > file2.txt
git add .
git commit -q -m 'initial'
echo 'modified' >> file1.txt
echo 'new' > file3.txt

RAW_OUTPUT="$(git status 2>&1)"
RAW_SIZE=$(printf '%s' "$RAW_OUTPUT" | wc -c | tr -d ' ')

COMPACT_OUTPUT="$($HOME/bin/caveman_wrapper.sh git-status 2>&1)"
COMPACT_SIZE=$(printf '%s' "$COMPACT_OUTPUT" | wc -c | tr -d ' ')

if [ "$RAW_SIZE" -gt 0 ]; then
  SAVINGS=$((100 - (COMPACT_SIZE * 100 / RAW_SIZE)))
else
  SAVINGS=0
fi

printf 'Raw git status size: %s chars\n' "$RAW_SIZE"
printf 'Compact summary size: %s chars\n' "$COMPACT_SIZE"
printf 'Approx savings: %s%%\n\n' "$SAVINGS"

printf '%s\n' 'Compact output:'
printf '%s\n' "$COMPACT_OUTPUT"
