#!/usr/bin/env bash
# ----------------------------------------------------------------------
# agents/install.sh
#
#   Install, uninstall, or list agent skills for Claude Code, Cursor,
#   and GitHub Copilot.
#
#   Usage:
#       ./install.sh install [agent]       # Install skills (default: all)
#       ./install.sh uninstall [agent]     # Remove installed skills
#       ./install.sh list                   # Show available and installed skills
#
#   Agents:
#       claude-code    Symlink to ~/.claude/commands/
#       cursor         Symlink to ~/.cursor/rules/
#       copilot        Copy to .github/instructions/ (project-level)
#       all            All agents (default)
#
#   License: GPL-3.0
# ----------------------------------------------------------------------

set -euo pipefail

# ---------- Configuration ----------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${SCRIPT_DIR}"

# Map agent names to their format file suffix and install targets
declare -A AGENT_FILE_SUFFIX=(
    ["claude-code"]="claude-code.md"
    ["cursor"]="cursor.mdc"
    ["copilot"]="copilot.instructions.md"
)

declare -A AGENT_INSTALL_DIR=(
    ["claude-code"]="$HOME/.claude/commands"
    ["cursor"]="$HOME/.cursor/rules"
    ["copilot"]=".github/instructions"
)

declare -A AGENT_METHOD=(
    ["claude-code"]="symlink"
    ["cursor"]="symlink"
    ["copilot"]="copy"
)

ALL_AGENTS=("claude-code" "cursor" "copilot")

# ---------- Helper Functions ----------

usage() {
    cat <<'EOF'
Usage: ./install.sh <command> [agent]

Commands:
  install [agent]     Install skills for specified agent (default: all)
  uninstall [agent]   Remove installed skills for specified agent (default: all)
  list                Show available and installed skills

Agents:
  claude-code    Symlink to ~/.claude/commands/
  cursor         Symlink to ~/.cursor/rules/
  copilot        Copy to .github/instructions/ (project-level)
  all            All agents (default)
EOF
    exit 0
}

log() {
    local prefix="$1"; shift
    printf "  %-12s %s\n" "$prefix" "$*"
}

info()  { log "INFO" "$@"; }
ok()    { log "OK" "$@"; }
warn()  { log "WARN" "$@"; }
err()   { log "ERROR" "$@" >&2; }

# Discover available skills by scanning agents/*/ directories
discover_skills() {
    local skills=()
    for skill_dir in "${AGENTS_DIR}"/*/; do
        # Skip non-directories (e.g., if no skills exist yet)
        [[ -d "$skill_dir" ]] || continue
        # Extract skill name from directory path
        local skill_name
        skill_name="$(basename "$skill_dir")"
        # Skip if no format files exist
        local has_formats=false
        for agent in "${ALL_AGENTS[@]}"; do
            local suffix="${AGENT_FILE_SUFFIX[$agent]}"
            if [[ -f "${skill_dir}${suffix}" ]]; then
                has_formats=true
                break
            fi
        done
        if $has_formats; then
            skills+=("$skill_name")
        fi
    done
    printf '%s\n' "${skills[@]}"
}

# Get the install target name for a skill (derived from directory name)
# claude-code.md -> defensive-analysis.md, cursor.mdc -> defensive-analysis.mdc, etc.
get_install_name() {
    local skill_name="$1"
    local agent="$2"
    local suffix="${AGENT_FILE_SUFFIX[$agent]}"
    local extension="${suffix##*.}"
    printf '%s.%s' "$skill_name" "$extension"
}

# ---------- Install Functions ----------

install_skill() {
    local skill_name="$1"
    local agent="$2"
    local suffix="${AGENT_FILE_SUFFIX[$agent]}"
    local source_file="${AGENTS_DIR}/${skill_name}/${suffix}"

    if [[ ! -f "$source_file" ]]; then
        warn "Skipping ${skill_name} for ${agent}: format file not found (${suffix})"
        return 1
    fi

    local method="${AGENT_METHOD[$agent]}"
    local install_dir="${AGENT_INSTALL_DIR[$agent]}"
    local install_name
    install_name="$(get_install_name "$skill_name" "$agent")"
    local target="${install_dir}/${install_name}"

    # For copilot, resolve relative to current working directory
    if [[ "$agent" == "copilot" ]]; then
        install_dir="$(pwd)/${AGENT_INSTALL_DIR[$agent]}"
        target="${install_dir}/${install_name}"

        # Verify we're in a git repository
        if ! git rev-parse --is-inside-work-tree &>/dev/null; then
            err "Copilot installation requires being inside a git repository (for .github/instructions/)"
            return 1
        fi
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$install_dir"

    case "$method" in
        symlink)
            local abs_source
            abs_source="$(cd "$(dirname "$source_file")" && pwd)/$(basename "$source_file")"

            # Remove existing symlink or file at target
            if [[ -L "$target" ]]; then
                local current_target
                current_target="$(readlink "$target")"
                if [[ "$current_target" == "$abs_source" ]]; then
                    ok "Already installed: ${agent}/${skill_name} -> ${target}"
                    return 0
                else
                    rm "$target"
                fi
            elif [[ -f "$target" ]]; then
                warn "Replacing existing file: ${target}"
                rm "$target"
            fi

            ln -s "$abs_source" "$target"
            ok "Installed: ${agent}/${skill_name} -> ${target}"
            ;;
        copy)
            if [[ -f "$target" ]]; then
                # Check if content is identical
                if diff -q "$source_file" "$target" &>/dev/null; then
                    ok "Already up to date: ${agent}/${skill_name} -> ${target}"
                    return 0
                else
                    warn "Updating existing file: ${target}"
                fi
            fi
            cp "$source_file" "$target"
            ok "Installed: ${agent}/${skill_name} -> ${target}"
            ;;
        *)
            err "Unknown install method: ${method}"
            return 1
            ;;
    esac

    return 0
}

uninstall_skill() {
    local skill_name="$1"
    local agent="$2"
    local install_dir="${AGENT_INSTALL_DIR[$agent]}"
    local install_name
    install_name="$(get_install_name "$skill_name" "$agent")"
    local target="${install_dir}/${install_name}"

    # For copilot, resolve relative to current working directory
    if [[ "$agent" == "copilot" ]]; then
        install_dir="$(pwd)/${AGENT_INSTALL_DIR[$agent]}"
        target="${install_dir}/${install_name}"
    fi

    if [[ -L "$target" ]]; then
        rm "$target"
        ok "Removed symlink: ${target}"
    elif [[ -f "$target" ]]; then
        # Only remove if it's a file we installed (check content matches)
        local suffix="${AGENT_FILE_SUFFIX[$agent]}"
        local source_file="${AGENTS_DIR}/${skill_name}/${suffix}"
        if [[ -f "$source_file" ]] && diff -q "$source_file" "$target" &>/dev/null; then
            rm "$target"
            ok "Removed file: ${target}"
        else
            warn "Skipping ${target}: content differs from source (not installed by this script)"
            return 1
        fi
    else
        info "Not installed: ${agent}/${skill_name}"
        return 0
    fi

    return 0
}

# ---------- Command Handlers ----------

cmd_install() {
    local agent="${1:-all}"

    if [[ "$agent" == "all" ]]; then
        local installed=0
        local failed=0
        for skill_name in $(discover_skills); do
            for a in "${ALL_AGENTS[@]}"; do
                if install_skill "$skill_name" "$a"; then
                    ((installed++)) || true
                else
                    ((failed++)) || true
                fi
            done
        done
        echo ""
        info "Installed: ${installed}, Skipped: ${failed}"
    else
        # Validate agent name
        local found=false
        for a in "${ALL_AGENTS[@]}"; do
            if [[ "$a" == "$agent" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            err "Unknown agent: ${agent}. Choose from: ${ALL_AGENTS[*]} all"
            exit 1
        fi

        local installed=0
        local failed=0
        for skill_name in $(discover_skills); do
            if install_skill "$skill_name" "$agent"; then
                ((installed++)) || true
            else
                ((failed++)) || true
            fi
        done
        echo ""
        info "Installed: ${installed}, Skipped: ${failed}"
    fi
}

cmd_uninstall() {
    local agent="${1:-all}"

    if [[ "$agent" == "all" ]]; then
        for skill_name in $(discover_skills); do
            for a in "${ALL_AGENTS[@]}"; do
                uninstall_skill "$skill_name" "$a"
            done
        done
    else
        # Validate agent name
        local found=false
        for a in "${ALL_AGENTS[@]}"; do
            if [[ "$a" == "$agent" ]]; then
                found=true
                break
            fi
        done
        if ! $found; then
            err "Unknown agent: ${agent}. Choose from: ${ALL_AGENTS[*]} all"
            exit 1
        fi

        for skill_name in $(discover_skills); do
            uninstall_skill "$skill_name" "$agent"
        done
    fi
}

cmd_list() {
    echo "Available skills:"
    echo ""
    for skill_name in $(discover_skills); do
        echo "  ${skill_name}:"
        for agent in "${ALL_AGENTS[@]}"; do
            local suffix="${AGENT_FILE_SUFFIX[$agent]}"
            local source_file="${AGENTS_DIR}/${skill_name}/${suffix}"
            local install_dir="${AGENT_INSTALL_DIR[$agent]}"
            local install_name
            install_name="$(get_install_name "$skill_name" "$agent")"
            local target="${install_dir}/${install_name}"

            if [[ "$agent" == "copilot" ]]; then
                target="$(pwd)/${AGENT_INSTALL_DIR[$agent]}/${install_name}"
            fi

            local status="not available"
            if [[ -f "$source_file" ]]; then
                if [[ -L "$target" ]]; then
                    status="installed (symlink)"
                elif [[ -f "$target" ]]; then
                    status="installed (copy)"
                else
                    status="available"
                fi
            fi

            printf "    %-14s %s\n" "$agent:" "$status"
        done
        echo ""
    done
}

# ---------- Main ----------

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    local command="$1"
    shift

    case "$command" in
        install)
            cmd_install "$@"
            ;;
        uninstall)
            cmd_uninstall "$@"
            ;;
        list)
            cmd_list
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            err "Unknown command: ${command}"
            echo ""
            usage
            ;;
    esac
}

main "$@"