#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DIR="$HOME/.hermes"
TEMPLATES_DIR="$HOME/templates"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="${HTS_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver}"
BACKEND_CACHE="$CONFIG_DIR/backend"

resolve_bin_dir() {
  if [ -n "${PREFIX:-}" ]; then
    printf '%s\n' "$PREFIX"
  elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    printf '%s\n' "/usr/local/bin"
  elif [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    printf '%s\n' "$HOME/.local/bin"
  else
    printf '%s\n' "$HOME/bin"
  fi
}

BIN_DIR="$(resolve_bin_dir)"

REPO_URL="https://github.com/ArkhiMuttaqina/haku-token-saver"
REPO_BRANCH="${HTS_REPO_BRANCH:-main}"

# Bootstrap: if not inside repo, download tarball and run from tmpdir
if [ ! -f "$SCRIPT_DIR/scripts/hts" ]; then
  command -v curl >/dev/null 2>&1 || { echo "[err] missing dependency: curl" >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo "[err] missing dependency: tar" >&2; exit 1; }

  BOOTSTRAP_TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$BOOTSTRAP_TMPDIR"' EXIT

  printf '[i] downloading %s/archive/refs/heads/%s.tar.gz into %s\n' "$REPO_URL" "$REPO_BRANCH" "$BOOTSTRAP_TMPDIR"
  curl -fsSL "$REPO_URL/archive/refs/heads/$REPO_BRANCH.tar.gz" -o "$BOOTSTRAP_TMPDIR/repo.tar.gz" || { echo "[err] download failed" >&2; exit 1; }

  printf '[i] extracting tarball\n'
  tar -xzf "$BOOTSTRAP_TMPDIR/repo.tar.gz" -C "$BOOTSTRAP_TMPDIR" || { echo "[err] extraction failed" >&2; exit 1; }

  EXTRACTED_DIR="$(find "$BOOTSTRAP_TMPDIR" -maxdepth 1 -type d -name "haku-token-saver-*" | head -n 1)"
  [ -d "$EXTRACTED_DIR" ] || { echo "[err] extracted directory not found" >&2; exit 1; }

  SCRIPT_DIR="$EXTRACTED_DIR"
  export SCRIPT_DIR
  printf '[i] bootstrapped to %s\n' "$SCRIPT_DIR"
fi

# Parse flags
WITH_SHELL_PROFILE=false
DRY_RUN=false
BACKEND="auto"
INSTALL_DEPS=true
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      BIN_DIR="$2"
      shift 2
      ;;
    --backend)
      BACKEND="$2"
      shift 2
      ;;
    --with-shell-profile)
      WITH_SHELL_PROFILE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --install-deps)
      INSTALL_DEPS=true
      shift
      ;;
    --skip-deps)
      INSTALL_DEPS=false
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    *)
      echo "[err] Unknown flag: $1" >&2
      exit 1
      ;;
  esac
done

info() { printf '[i] %s\n' "$1"; }
ok() { printf '[ok] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1"; }
fail() { printf '[err] %s\n' "$1" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing dependency: $1"
}

dry_echo() {
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] $*"
  fi
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] $*"
    return 0
  fi
  "$@"
}

remove_path() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[dry-run] rm -rf $path"
    else
      rm -rf "$path"
    fi
    ok "removed $path"
  else
    info "already absent: $path"
  fi
}

detect_backend() {
  local backend="${1:-}"
  if [ -n "$backend" ] && [ "$backend" != "auto" ]; then
    echo "$backend"
    return
  fi

  # Priority: snip > rtk > raw-limited
  if command -v snip >/dev/null 2>&1; then
    echo "snip"
  elif command -v rtk >/dev/null 2>&1; then
    echo "rtk"
  else
    echo "raw"
  fi
}

install_snip() {
  if command -v snip >/dev/null 2>&1; then
    ok "snip already installed: $(command -v snip)"
    return 0
  fi

  info "installing snip"
  if command -v brew >/dev/null 2>&1; then
    run_cmd brew install edouard-claude/tap/snip
  elif command -v go >/dev/null 2>&1; then
    run_cmd go install github.com/edouard-claude/snip/cmd/snip@latest
  elif command -v curl >/dev/null 2>&1; then
    run_cmd sh -c 'curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh'
  else
    fail "cannot install snip automatically; install brew, go, or curl, then rerun"
  fi

  command -v snip >/dev/null 2>&1 || warn "snip install command completed but snip is not on PATH yet"
}

install_node_tools() {
  local missing=()
  local npm_prefix
  local npm_bin
  command -v caveman >/dev/null 2>&1 || missing+=(caveman)
  command -v rtk >/dev/null 2>&1 || missing+=(rtk)

  if [ "${#missing[@]}" -eq 0 ]; then
    if command -v caveman >/dev/null 2>&1; then
      ok "caveman already installed: $(command -v caveman)"
    else
      ok "caveman package already installed"
    fi
    ok "rtk already installed: $(command -v rtk)"
    ensure_caveman_shim
    return 0
  fi

  command -v npm >/dev/null 2>&1 || fail "npm is required to install missing tools: ${missing[*]}"

  npm_prefix="$(npm config get prefix 2>/dev/null || true)"
  npm_bin=""
  if [ -n "$npm_prefix" ] && [ -w "$npm_prefix" ]; then
    info "installing npm tools globally: ${missing[*]}"
    run_cmd npm install -g "${missing[@]}"
  else
    npm_prefix="$HOME/.local"
    npm_bin="$npm_prefix/bin"
    info "npm global prefix is not writable; installing npm tools under $npm_prefix"
    run_cmd mkdir -p "$npm_bin"
    run_cmd npm install -g --prefix "$npm_prefix" "${missing[@]}"
    case ":$PATH:" in
      *":$npm_bin:"*) ;;
      *) warn "$npm_bin is not on PATH; add it to use caveman/rtk directly" ;;
    esac
  fi

  for tool in "${missing[@]}"; do
    local bin_check=""
    if [ -x "$HOME/.local/bin/$tool" ]; then
      bin_check="$HOME/.local/bin/$tool"
    elif [ -f "$HOME/.local/lib/node_modules/$tool/package.json" ]; then
      bin_check="$HOME/.local/lib/node_modules/$tool"
    fi
    if command -v "$tool" >/dev/null 2>&1 || [ -n "$bin_check" ]; then
      true
    else
      warn "$tool install completed but binary is not on PATH yet"
    fi
  done

  ensure_caveman_shim
}

ensure_caveman_shim() {
  local shim="$HOME/.local/bin/caveman"
  if [ -x "$shim" ]; then
    return 0
  fi

  local caveman_dir="$HOME/.local/lib/node_modules/caveman"
  if [ ! -d "$caveman_dir" ]; then
    return 0
  fi

  if [ ! -f "$caveman_dir/caveman.js" ]; then
    return 0
  fi

  info "creating caveman shim at $shim"
  dry_echo "mkdir -p '$HOME/.local/bin'"
  [ "$DRY_RUN" = true ] || mkdir -p "$HOME/.local/bin"

  dry_echo "cat > '$shim' << 'SHIM_EOF'"
  if [ "$DRY_RUN" = false ]; then
    cat > "$shim" << 'SHIM_EOF'
#!/usr/bin/env node
const path = require('path');
const libDir = path.resolve(__dirname, '..', 'lib', 'node_modules', 'caveman');
require(path.join(libDir, 'caveman.js'));
SHIM_EOF
    dry_echo "chmod +x '$shim'"
    [ "$DRY_RUN" = false ] && chmod +x "$shim"
  fi

  ok "caveman shim created"
}

install_deps() {
  if [ "$INSTALL_DEPS" != true ]; then
    warn "dependency auto-install skipped (--skip-deps)"
    return 0
  fi

  install_snip
  install_node_tools
}

preflight() {
  need bash
  need jq
  command -v git >/dev/null 2>&1 || warn "git not found; some workflows like repo inspection and project init may be limited"

  if [ "$INSTALL_DEPS" = true ]; then
    command -v npm >/dev/null 2>&1 || warn "npm not found; caveman/rtk auto-install may fail"
    command -v brew >/dev/null 2>&1 || command -v go >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || warn "brew/go/curl not found; snip auto-install may fail"
  else
    command -v snip >/dev/null 2>&1 || warn "snip not found; install for best results"
    command -v rtk >/dev/null 2>&1 || warn "rtk not found; fallback filtering unavailable"
    command -v caveman >/dev/null 2>&1 || warn "caveman not found; template formatting unavailable"
  fi
}

install_config() {
  dry_echo "mkdir -p \"$CLAUDE_DIR\""
  [ "$DRY_RUN" = true ] || mkdir -p "$CLAUDE_DIR"

  local src="$SCRIPT_DIR/config/CLAUDE.md"
  local dst="$CLAUDE_DIR/CLAUDE.md"
  if [ -L "$dst" ]; then
    local link_target
    link_target="$(readlink -f "$dst" 2>/dev/null || true)"
    if [ -n "$link_target" ] && [ -e "$link_target" ]; then
      if ! [ -w "$link_target" ]; then
        warn "$dst is a symlink to $link_target (not writable); skipping config install"
        ok "config install skipped (existing symlink)"
        return 0
      fi
    fi
  fi

  dry_echo "cp \"$src\" \"$dst\""
  if [ "$DRY_RUN" = false ]; then
    cp "$src" "$dst" 2>/dev/null || warn "failed to copy config; continue anyway"
  fi

  ok "config installed"
}

install_skills() {
  dry_echo "mkdir -p \"$HERMES_DIR/skills/development\""
  [ "$DRY_RUN" = true ] || mkdir -p "$HERMES_DIR/skills/development"

  if [ -d "$SCRIPT_DIR/skills/development" ]; then
    dry_echo "cp -R \"$SCRIPT_DIR/skills/development/\"* \"$HERMES_DIR/skills/development/\""
    [ "$DRY_RUN" = true ] || cp -R "$SCRIPT_DIR/skills/development/"* "$HERMES_DIR/skills/development/"
  fi

  for skill_dir in "$SCRIPT_DIR"/skills/*; do
    [ -d "$skill_dir" ] || continue
    [ "$(basename "$skill_dir")" = "development" ] && continue
    dry_echo "cp -R \"$skill_dir\" \"$HERMES_DIR/skills/development/\""
    [ "$DRY_RUN" = true ] || cp -R "$skill_dir" "$HERMES_DIR/skills/development/"
  done

  ok "development skills installed"
}

install_scripts() {
  dry_echo "mkdir -p \"$BIN_DIR\""
  [ "$DRY_RUN" = true ] || mkdir -p "$BIN_DIR"

  for script in caveman_wrapper.sh verify_caveman_setup.sh demo_token_savings.sh hts; do
    dry_echo "cp \"$SCRIPT_DIR/scripts/$script\" \"$BIN_DIR/$script\""
    [ "$DRY_RUN" = true ] || cp "$SCRIPT_DIR/scripts/$script" "$BIN_DIR/$script"

    dry_echo "chmod +x \"$BIN_DIR/$script\""
    [ "$DRY_RUN" = true ] || chmod +x "$BIN_DIR/$script"
  done

  ok "scripts installed"
}

install_templates() {
  dry_echo "mkdir -p \"$TEMPLATES_DIR\""
  [ "$DRY_RUN" = true ] || mkdir -p "$TEMPLATES_DIR"

  dry_echo "cp \"$SCRIPT_DIR/templates/\"*.txt \"$TEMPLATES_DIR/\""
  [ "$DRY_RUN" = true ] || cp "$SCRIPT_DIR/templates/"*.txt "$TEMPLATES_DIR/"

  ok "templates installed"
}

install_packs_config() {
  dry_echo "mkdir -p \"$CONFIG_DIR/packs\""
  [ "$DRY_RUN" = true ] || mkdir -p "$CONFIG_DIR/packs"

  if [ -d "$SCRIPT_DIR/packs" ]; then
    dry_echo "cp -R \"$SCRIPT_DIR/packs/\"*.yaml \"$CONFIG_DIR/packs/\""
    [ "$DRY_RUN" = true ] || cp -R "$SCRIPT_DIR/packs/"*.yaml "$CONFIG_DIR/packs/"
  fi

  if [ -f "$SCRIPT_DIR/config/filter-map.yaml" ]; then
    dry_echo "cp \"$SCRIPT_DIR/config/filter-map.yaml\" \"$CONFIG_DIR/\""
    [ "$DRY_RUN" = true ] || cp "$SCRIPT_DIR/config/filter-map.yaml" "$CONFIG_DIR/"
  fi

  ok "packs and config installed"
}

install_terminal_wrapper() {
  dry_echo "mkdir -p \"$CONFIG_DIR/terminal_wrapper\""
  [ "$DRY_RUN" = true ] || mkdir -p "$CONFIG_DIR/terminal_wrapper"

  if [ -d "$SCRIPT_DIR/terminal_wrapper" ]; then
    for item in "$SCRIPT_DIR/terminal_wrapper/"*; do
      dry_echo "cp -R \"$item\" \"$CONFIG_DIR/terminal_wrapper/\""
      [ "$DRY_RUN" = true ] || cp -R "$item" "$CONFIG_DIR/terminal_wrapper/"
    done
    ok "terminal wrapper installed"
  else
    info "terminal_wrapper not found; --detail mode will not be available"
  fi
}

write_backend_cache() {
  local backend
  backend=$(detect_backend "$BACKEND")

  dry_echo "mkdir -p \"$CONFIG_DIR\""
  [ "$DRY_RUN" = true ] || mkdir -p "$CONFIG_DIR"

  dry_echo "echo \"$backend\" > \"$BACKEND_CACHE\""
  [ "$DRY_RUN" = true ] || echo "$backend" > "$BACKEND_CACHE"

  ok "backend cache: $backend"
}

install_aliases() {
  local rc="$HOME/.zshrc"
  touch "$rc"

  if grep -q '# Haku Token Saver Aliases' "$rc"; then
    ok "aliases already present"
    return
  fi

  local aliases=$(
    cat <<'EOF'

# Haku Token Saver Aliases
alias cgs='~/bin/caveman_wrapper.sh git-status'
alias cgl='~/bin/caveman_wrapper.sh git-log'
alias clint='~/bin/caveman_wrapper.sh lint'
alias ctest='~/bin/caveman_wrapper.sh test-results'
alias cscripts='~/bin/caveman_wrapper.sh npm-scripts'
alias verify-token-saver='~/bin/verify_caveman_setup.sh'
alias hts='~/bin/hts'
# End Haku Token Saver Aliases
EOF
  )

  dry_echo "cat >> \"$rc\" <<'EOF'"
  dry_echo "$aliases"
  dry_echo "EOF"

  if [ "$DRY_RUN" = false ]; then
    echo "$aliases" >> "$rc"
  fi

  ok "aliases added to ~/.zshrc"
}

verify() {
  if [ "$DRY_RUN" = true ]; then
    [ -f "$SCRIPT_DIR/scripts/hts" ] || fail "missing source hts"
    [ -f "$SCRIPT_DIR/scripts/caveman_wrapper.sh" ] || fail "missing source wrapper"
    [ -f "$SCRIPT_DIR/templates/git_status.txt" ] || fail "missing source templates"
    [ -f "$SCRIPT_DIR/config/CLAUDE.md" ] || fail "missing source CLAUDE.md"
  else
    [ -x "$BIN_DIR/hts" ] || fail "missing hts"
    [ -x "$BIN_DIR/caveman_wrapper.sh" ] || fail "missing wrapper"
    [ -f "$TEMPLATES_DIR/git_status.txt" ] || fail "missing templates"
    [ -f "$CLAUDE_DIR/CLAUDE.md" ] || fail "missing CLAUDE.md"
    "$BIN_DIR/hts" --doctor >/dev/null 2>&1 || fail "hts --doctor failed"
    "$BIN_DIR/hts" --packs >/dev/null 2>&1 || fail "hts --packs failed"
    "$BIN_DIR/hts" --filters '^git-' >/dev/null 2>&1 || fail "hts --filters failed"
  fi
  ok "install verified"
}

uninstall() {
  info "uninstalling Haku Token Saver artifacts"

  remove_path "$BIN_DIR/hts"
  remove_path "$BIN_DIR/caveman_wrapper.sh"
  remove_path "$BIN_DIR/verify_caveman_setup.sh"
  remove_path "$BIN_DIR/demo_token_savings.sh"

  remove_path "$TEMPLATES_DIR/git_status.txt"
  remove_path "$TEMPLATES_DIR/git_log.txt"
  remove_path "$TEMPLATES_DIR/lint_results.txt"
  remove_path "$TEMPLATES_DIR/test_results.txt"

  remove_path "$CONFIG_DIR"

  remove_path "$HERMES_DIR/skills/development/hts-token-saver"
  remove_path "$HERMES_DIR/skills/development/hts-orchestrator"
  remove_path "$HERMES_DIR/skills/development/hts-cli-workflow"
  remove_path "$HERMES_DIR/skills/development/token-saving-cli-workflow"
  remove_path "$HERMES_DIR/skills/development/context-optimization"
  remove_path "$HERMES_DIR/skills/development/caveman-rtk-integration"

  printf '\nManual cleanup note:\n'
  printf '  Remove old shell aliases from ~/.zshrc if you added them with --with-shell-profile.\n'
  printf '  Look for the block between:\n'
  printf '    # Haku Token Saver Aliases\n'
  printf '    # End Haku Token Saver Aliases\n\n'
  ok "uninstall completed"
}

main() {
  if [ "$UNINSTALL" = true ]; then
    uninstall
    return 0
  fi

  info "installing Haku Token Saver"
  [ "$DRY_RUN" = true ] && info "(dry run mode)"

  preflight
  install_deps
  write_backend_cache
  install_config
  install_skills
  install_scripts
  install_templates
  install_packs_config
  install_terminal_wrapper

  if [ "$WITH_SHELL_PROFILE" = true ]; then
    install_aliases
  fi

  verify

  printf '\n'
  ok "Done."
  printf '\nNext steps:\n'
  printf '  1. Ensure %s is on PATH\n' "$BIN_DIR"
  printf '  2. Verify: hts --doctor\n'
  printf '  3. Check backend: hts --which\n'
  printf '  4. Try: hts -- git status\n'
  printf '\nBackend tools installed:\n'
  command -v snip >/dev/null 2>&1 || [ -x "$HOME/.local/bin/snip" ] && printf '  ✓ snip\n' || printf '  ✗ snip (manual install required)\n'
  command -v rtk >/dev/null 2>&1 || [ -x "$HOME/.local/bin/rtk" ] || [ -f "$HOME/.local/lib/node_modules/rtk/package.json" ] && printf '  ✓ rtk\n' || printf '  ✗ rtk (manual install required)\n'
  command -v caveman >/dev/null 2>&1 || [ -x "$HOME/.local/bin/caveman" ] || [ -f "$HOME/.local/lib/node_modules/caveman/package.json" ] && printf '  ✓ caveman\n' || printf '  ✗ caveman (manual install required)\n'
  if ! command -v caveman >/dev/null 2>&1 && [ -f "$HOME/.local/lib/node_modules/caveman/package.json" ]; then
    printf '\nNote: caveman is installed but not on PATH; use:\n'
    printf '  export PATH="$HOME/.local/bin:$PATH"\n'
    printf '  or add ~/.local/bin to your PATH permanently\n'
  fi
  printf '\n'
}

main "$@"