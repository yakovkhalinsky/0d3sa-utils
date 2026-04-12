# Agents

Skills and prompts for coding agents (Claude Code, Cursor, GitHub Copilot, etc.). Each skill provides a structured analysis workflow that can be installed as a slash command, contextual rule, or always-on instruction.

## Available Skills

| Skill | Description | Formats |
|-------|-------------|---------|
| [defensive-analysis](defensive-analysis/) | Run 10 defensive code analysis checks (mutation invalidation, query error handling, type safety, API path safety, runtime validation, state lifecycle, memory leaks, error state handling, loading state handling, uncontrolled state). Auto-detects the project stack and adapts checks. Outputs a PASS/FAIL report. | Claude Code, Cursor, Copilot |

## Quick Start

Install all skills for all agents:

```bash
./agents/install.sh install
```

Install for a specific agent:

```bash
./agents/install.sh install claude-code    # Symlink to ~/.claude/commands/
./agents/install.sh install cursor          # Symlink to ~/.cursor/rules/
./agents/install.sh install copilot        # Copy to .github/instructions/
```

Check what's installed:

```bash
./agents/install.sh list
```

Uninstall:

```bash
./agents/install.sh uninstall all          # Remove all installed skills
./agents/install.sh uninstall claude-code  # Remove Claude Code skills only
```

## Adding a New Skill

1. Create a new directory under `agents/` with the skill name (e.g., `agents/my-skill/`)
2. Add at least `claude-code.md` (the canonical format with YAML frontmatter)
3. Optionally add `cursor.mdc` and `copilot.instructions.md` for multi-agent support
4. Add a `README.md` documenting the skill, its checks, and usage per agent
5. The install script auto-discovers skills by scanning `agents/*/` directories — no changes needed to `install.sh`

## Multi-Agent Formats

Each skill is provided in three formats, adapted for each agent's interaction model:

| Format | File | Invocation | Install Method |
|--------|------|-----------|---------------|
| Claude Code | `claude-code.md` | `/skill-name [args]` slash command | Symlink to `~/.claude/commands/` |
| Cursor | `cursor.mdc` | @-mention or auto-attached by description | Symlink to `~/.cursor/rules/` |
| GitHub Copilot | `copilot.instructions.md` | Always-on context when editing matching files | Copy to `.github/instructions/` |

### Canonical Source

`claude-code.md` is the canonical source for each skill. When updating the prompt logic, edit it first, then propagate changes to the other formats. This is documented in each skill's README.

## License

GPL-3.0 — See the [LICENSE](../LICENSE) file for details.