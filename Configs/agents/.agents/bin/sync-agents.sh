#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# sync-agents.sh — Master sync script for multi-AI configuration
#
# Generates tool-specific config files from the unified hub:
#   1. ~/.gemini/GEMINI.md      ← from engineering-base.agent.md
#   2. Project GEMINI.md files  ← from ~/.agents/ (profiles + skills)
#   3. Claude memory files      ← hand-curated, preserved (status check only)
#
# NOTE: ~/.claude/CLAUDE.md is managed by dotfiles (stow).
#       Edit ~/.dotfiles/Configs/claude/.claude/CLAUDE.md directly.
#
# Usage:
#   sync-agents.sh              # Full sync
#   sync-agents.sh --dry-run    # Preview only (no writes)
# ─────────────────────────────────────────────────────────────

AGENTS_DIR="$HOME/.agents"
ENGINEERING_BASE="$AGENTS_DIR/engineering-base.agent.md"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN — no files will be written ==="
fi

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

write_file() {
    local target="$1"
    local content="$2"
    if $DRY_RUN; then
        echo "[dry-run] Would write: $target ($(echo "$content" | wc -l | tr -d ' ') lines)"
    else
        mkdir -p "$(dirname "$target")"
        echo "$content" > "$target"
        echo "[ok] $target ($(wc -l < "$target" | tr -d ' ') lines)"
    fi
}

strip_frontmatter() {
    # Strips YAML frontmatter (---\n...\n---) from stdin
    awk '
        BEGIN { in_front=0; front_done=0 }
        /^---/ && !front_done {
            if (in_front) { front_done=1; next }
            else { in_front=1; next }
        }
        front_done || !in_front { print }
    '
}

extract_engineering_base_content() {
    # Extract content after YAML frontmatter, stripping internal meta-headers
    awk '
        BEGIN { in_front=0; front_done=0 }
        /^---/ && !front_done {
            if (in_front) { front_done=1; next }
            else { in_front=1; next }
        }
        front_done { print }
    ' "$ENGINEERING_BASE" \
    | sed '/^# Engineering Base/d' \
    | sed '/^> \*\*Single source/d' \
    | sed '/^> Derived into/d'
}

# ─────────────────────────────────────────────────────────────
# 1. Generate ~/.gemini/GEMINI.md
# ─────────────────────────────────────────────────────────────

generate_gemini_md() {
    echo "--- Generating ~/.gemini/GEMINI.md ---"
    local content
    content=$(cat <<'HEADER'
# Engineering Principles (All Projects)

> Derived from `~/.agents/engineering-base.agent.md` — edit there, then sync here.
HEADER
    )
    content+=$'\n'
    content+=$(extract_engineering_base_content)

    write_file "$HOME/.gemini/GEMINI.md" "$content"
}

# ─────────────────────────────────────────────────────────────
# 2. Generate project GEMINI.md files from ~/.agents/
# ─────────────────────────────────────────────────────────────

generate_project_gemini() {
    local conf="$AGENTS_DIR/projects/patagonia-cdp/cursor-source.conf"
    if [[ ! -f "$conf" ]]; then
        echo "[skip] No cursor-source.conf found — skipping project GEMINI.md"
        return
    fi

    # shellcheck source=/dev/null
    source "$conf"  # provides: PROJECT_ROOT

    if [[ ! -d "$PROJECT_ROOT" ]]; then
        echo "[skip] Project root not found: $PROJECT_ROOT"
        return
    fi

    echo "--- Generating project GEMINI.md files from ~/.agents ---"

    local base_content
    base_content=$(extract_engineering_base_content)

    local patagonia_skill=""
    if [[ -f "$AGENTS_DIR/skills/patagonia-cdp/SKILL.md" ]]; then
        patagonia_skill=$(cat "$AGENTS_DIR/skills/patagonia-cdp/SKILL.md")
    fi

    # Backend GEMINI.md (project root)
    local backend_gemini
    backend_gemini=$(cat <<'HEADER'
# Engineering Principles (All Projects)

> Derived from `~/.agents/` — edit there, then run sync-agents.sh.
HEADER
    )
    backend_gemini+=$'\n'
    backend_gemini+="$base_content"
    backend_gemini+=$'\n\n'
    backend_gemini+=$(cat "$AGENTS_DIR/profiles/backend.md" | strip_frontmatter)
    if [[ -n "$patagonia_skill" ]]; then
        backend_gemini+=$'\n\n'
        backend_gemini+="$patagonia_skill"
    fi
    write_file "$PROJECT_ROOT/GEMINI.md" "$backend_gemini"

    # Frontend GEMINI.md
    local frontend_gemini
    frontend_gemini=$(cat <<'HEADER'
# Engineering Principles (All Projects)

> Derived from `~/.agents/` — edit there, then run sync-agents.sh.
HEADER
    )
    frontend_gemini+=$'\n'
    frontend_gemini+="$base_content"
    frontend_gemini+=$'\n\n'
    frontend_gemini+=$(cat "$AGENTS_DIR/profiles/frontend.md" | strip_frontmatter)
    if [[ -n "$patagonia_skill" ]]; then
        frontend_gemini+=$'\n\n'
        frontend_gemini+="$patagonia_skill"
    fi
    write_file "$PROJECT_ROOT/frontend/GEMINI.md" "$frontend_gemini"
}

# ─────────────────────────────────────────────────────────────
# 3. Verify Claude memory files (hand-curated, no generation)
# ─────────────────────────────────────────────────────────────

check_claude_memory() {
    local conf="$AGENTS_DIR/projects/patagonia-cdp/cursor-source.conf"
    if [[ ! -f "$conf" ]]; then
        echo "[skip] No cursor-source.conf found"
        return
    fi

    # shellcheck source=/dev/null
    source "$conf"  # provides: CLAUDE_MEMORY_DIR

    echo "--- Claude memory files (hand-curated) ---"
    local memory_dir="$CLAUDE_MEMORY_DIR"
    for f in MEMORY.md backend.md frontend.md architecture.md hooks.md; do
        if [[ -f "$memory_dir/$f" ]]; then
            echo "[ok] $memory_dir/$f"
        else
            echo "[WARN] $memory_dir/$f — missing"
        fi
    done
}

# ─────────────────────────────────────────────────────────────
# 4. Validate symlinks
# ─────────────────────────────────────────────────────────────

validate_symlinks() {
    echo "--- Validating symlinks ---"
    local errors=0

    # Claude agents (profiles)
    for profile in backend frontend fullstack mobile; do
        local link="$HOME/.claude/agents/$profile/$profile.md"
        if [[ -L "$link" ]] && [[ -e "$link" ]]; then
            echo "[ok] $link → $(readlink "$link")"
        else
            echo "[ERR] $link — broken or missing"
            ((errors++))
        fi
    done

    # Claude skills (generic — patagonia-cdp is local-only, not validated here)
    for skill in composition-patterns react-best-practices english-coach; do
        local link="$HOME/.claude/skills/$skill/SKILL.md"
        if [[ -L "$link" ]] && [[ -e "$link" ]]; then
            echo "[ok] $link → $(readlink "$link")"
        else
            echo "[ERR] $link — broken or missing"
            ((errors++))
        fi
    done

    # Copilot agents
    for agent in engineering-base.agent.md react-senior-dev.agent.md; do
        local link="$HOME/.copilot/agents/$agent"
        if [[ -L "$link" ]] && [[ -e "$link" ]]; then
            echo "[ok] $link → $(readlink "$link")"
        else
            echo "[ERR] $link — broken or missing"
            ((errors++))
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo "[WARN] $errors broken symlink(s) found"
        return 1
    fi
    echo "[ok] All symlinks valid"
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────

main() {
    echo "============================================"
    echo "  sync-agents.sh — Multi-AI Config Sync"
    echo "============================================"
    echo ""

    generate_gemini_md
    echo ""
    generate_project_gemini
    echo ""
    check_claude_memory
    echo ""
    validate_symlinks
    echo ""
    echo "============================================"
    echo "  Sync complete!"
    echo "============================================"
}

main "$@"
