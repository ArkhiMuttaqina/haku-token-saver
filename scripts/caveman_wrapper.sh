#!/usr/bin/env bash
# Caveman + RTK Wrapper - Automated token-efficient output formatting
# Usage: caveman_wrapper.sh <workflow> [options]

set -e

WORKFLOW="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CAVEMAN="${CAVEMAN_BIN:-$HOME/bin/caveman}"
TEMPLATES_DIR="${CAVEMAN_TEMPLATES_DIR:-$REPO_DIR/templates}"
DATA_DIR="${CAVEMAN_DATA_DIR:-${TMPDIR:-/tmp}/caveman_data}"

mkdir -p "$DATA_DIR" "$TEMPLATES_DIR"

render_template() {
  local template="$1"
  local data="$2"
  local workflow="${3:-raw}"

  if command -v rtk >/dev/null 2>&1 && [ -x "$CAVEMAN" ]; then
    rtk "$CAVEMAN" "$template" "$data"
  elif [ -x "$CAVEMAN" ]; then
    "$CAVEMAN" "$template" "$data"
  elif command -v jq >/dev/null 2>&1; then
    case "$workflow" in
      git-status)
        jq -r '
          def section(name; prefix; xs):
            if (xs|length) > 0 then
              "\(name) (\(xs|length)):",
              (xs[] | "  \(prefix) \(. )")
            else
              empty
            end;
          section("Staged"; "+"; .staged),
          section("Modified"; "~"; .modified),
          section("Untracked"; "?"; .untracked),
          section("Deleted"; "-"; .deleted)
        ' "$data"
        ;;
      git-log)
        jq -r '"Recent commits:", (.commits[]? | "  \(.hash) \(.date) \(.message)")' "$data"
        ;;
      lint)
        jq -r 'if (.files|length) == 0 then "✓ No lint errors" else "Lint results:", (.files[] | "  \(.file)", (.errors[]? | "    \(.line):\(.col) [\(.severity)] \(.message)")) end' "$data"
        ;;
      test-results)
        jq -r 'if (.failed // 0) > 0 then "❌ Tests: \(.passed // 0)/\(.total // 0) passed (\(.failed) failed)", (.suites[]? | select(.status == "failed") | "  ✗ \(.name) (\(.duration // 0)ms)") else "✅ All \(.total // 0) tests passed" end' "$data"
        ;;
      *)
        jq -c . "$data"
        ;;
    esac
  else
    cat "$data"
  fi
}

case "$WORKFLOW" in
  git-status)
    # Extract git status data to JSON
    git status --porcelain | awk '
    BEGIN { staged=0; modified=0; untracked=0; deleted=0 }
    /^[MARC]./ { staged_arr[staged++] = substr($0, 4) }
    /^.[MARC]/ { modified_arr[modified++] = substr($0, 4) }
    /^\?\?/ { untracked_arr[untracked++] = substr($0, 4) }
    /^D/ || /^.D/ { deleted_arr[deleted++] = substr($0, 4) }
    END {
      printf "{"
      printf "\"staged\":["
      for(i=0;i<staged;i++) printf "%s\"%s\"", (i>0?",":""), staged_arr[i]
      printf "],\"modified\":["
      for(i=0;i<modified;i++) printf "%s\"%s\"", (i>0?",":""), modified_arr[i]
      printf "],\"untracked\":["
      for(i=0;i<untracked;i++) printf "%s\"%s\"", (i>0?",":""), untracked_arr[i]
      printf "],\"deleted\":["
      for(i=0;i<deleted;i++) printf "%s\"%s\"", (i>0?",":""), deleted_arr[i]
      printf "]}"
    }' > "$DATA_DIR/git_status.json"
    
    # Create template if not exists
    if [ ! -f "$TEMPLATES_DIR/git_status.txt" ]; then
      cat > "$TEMPLATES_DIR/git_status.txt" << 'EOF'
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
{{- if d.untracked }}
Untracked ({{ d.untracked | length }}):
{{- for d.untracked as file }}
  ? {{file}}
{{- end }}
{{- end }}
{{- if d.deleted }}
Deleted ({{ d.deleted | length }}):
{{- for d.deleted as file }}
  - {{file}}
{{- end }}
{{- end }}
EOF
    fi

    render_template "$TEMPLATES_DIR/git_status.txt" "$DATA_DIR/git_status.json" "git-status"
    ;;
    
  git-log)
    # Extract recent git log
    LIMIT="${1:-10}"
    git log --oneline -"$LIMIT" --format='{"hash":"%h","author":"%an","date":"%ad","message":"%s"}' --date=short | \
      jq -s '.' > "$DATA_DIR/git_log.json"
    
    if [ ! -f "$TEMPLATES_DIR/git_log.txt" ]; then
      cat > "$TEMPLATES_DIR/git_log.txt" << 'EOF'
Recent Commits:
{{- for d.commits as commit }}
  {{commit.hash}} {{commit.date}} {{commit.message}}
{{- end }}
EOF
    fi
    
    jq '{commits: .}' "$DATA_DIR/git_log.json" > "$DATA_DIR/git_log_final.json"
    render_template "$TEMPLATES_DIR/git_log.txt" "$DATA_DIR/git_log_final.json" "git-log"
    ;;
    
  lint)
    # Run linter and format results
    TARGET="${1:-.}"
    npx eslint "$TARGET" --format json 2>/dev/null | \
      jq '[.[] | {file: .filePath, errors: [.messages[] | {line: .line, col: .column, severity: .severity, message: .message}]}]' > "$DATA_DIR/lint_results.json" || true
    
    if [ ! -f "$TEMPLATES_DIR/lint_results.txt" ]; then
      cat > "$TEMPLATES_DIR/lint_results.txt" << 'EOF'
{{- if d.files }}
Lint Results:
{{- for d.files as file }}
{{file.file}}:
{{- for file.errors as err }}
  {{err.line}}:{{err.col}} [{{err.severity}}] {{err.message}}
{{- end }}
{{- end }}
{{- else }}
✓ No lint errors
{{- end }}
EOF
    fi
    
    if [ ! -s "$DATA_DIR/lint_results.json" ]; then
      printf '[]\n' > "$DATA_DIR/lint_results.json"
    fi
    jq '{files: .}' "$DATA_DIR/lint_results.json" > "$DATA_DIR/lint_final.json"
    render_template "$TEMPLATES_DIR/lint_results.txt" "$DATA_DIR/lint_final.json" "lint"
    ;;
    
  test-results)
    # Parse test output (works with vitest, jest, playwright)
    TEST_CMD="${1:-npx vitest run}"
    $TEST_CMD --reporter json 2>/dev/null | \
      jq '{total: .numTotalTests, passed: .numPassedTests, failed: .numFailedTests, suites: [.testResults[] | {name: .name, status: .status, duration: .duration}]}' > "$DATA_DIR/test_results.json" || true
    
    if [ ! -f "$TEMPLATES_DIR/test_results.txt" ]; then
      cat > "$TEMPLATES_DIR/test_results.txt" << 'EOF'
{{- if d.failed }}
❌ Tests: {{d.passed}}/{{d.total}} passed ({{d.failed}} failed)
{{- for d.suites as suite }}
{{- if suite.status == "failed" }}
  ✗ {{suite.name}} ({{suite.duration}}ms)
{{- end }}
{{- end }}
{{- else }}
✅ All {{d.total}} tests passed
{{- end }}
EOF
    fi

    render_template "$TEMPLATES_DIR/test_results.txt" "$DATA_DIR/test_results.json"
    ;;
    
  npm-scripts)
    # List npm scripts in compact format
    if [ -f package.json ]; then
      jq -r '.scripts | to_entries[] | "\(.key): \(.value)"' package.json | \
        awk 'BEGIN {print "Available scripts:"} {print "  " $0}' > "$DATA_DIR/npm_scripts.txt"
      cat "$DATA_DIR/npm_scripts.txt"
    else
      echo "[warn] no package.json found"
    fi
    ;;
    
  *)
    echo "Usage: caveman_wrapper.sh <workflow> [options]"
    echo ""
    echo "Available workflows:"
    echo "  git-status [dir]              - Git status with staged/modified/untracked"
    echo "  git-log [limit]               - Recent git commits (default: 10)"
    echo "  lint [target]                 - ESLint results formatted"
    echo "  test-results [cmd]            - Test results (vitest/jest/playwright)"
    echo "  npm-scripts                   - List npm scripts"
    echo ""
    echo "Examples:"
    echo "  caveman_wrapper.sh git-status"
    echo "  caveman_wrapper.sh git-log 20"
    echo "  caveman_wrapper.sh lint src/"
    echo "  caveman_wrapper.sh test-results 'npx vitest run'"
    exit 1
    ;;
esac
