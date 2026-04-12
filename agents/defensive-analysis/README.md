# defensive-analysis

Run 10 defensive code analysis checks that catch common bugs causing production incidents. Auto-detects the project's stack and adapts checks accordingly. Outputs a PASS/FAIL report with file:line references, actionable fixes, and a summary score.

## The 10 Checks

| # | Check | What it catches |
|---|-------|------------------|
| 1 | Mutation Invalidation | Mutations that don't invalidate/refetch dependent queries |
| 2 | Query Error Handling | Queries that swallow or ignore errors |
| 3 | Type Safety | `as any`, `as { ... }` type assertions on unvalidated input, unexplained `@ts-ignore`, untyped params, non-null assertions |
| 4 | API Path Safety | Hardcoded inline API paths instead of centralized route maps |
| 5 | Runtime Validation (Client + Server) | External data entering the app without schema validation — covers both client-side API responses AND server-side request body/params/query |
| 6 | State Lifecycle Docs | Async hooks/stores missing Error, Cleanup, and Transitions documentation |
| 7 | Memory Leaks | Un-cleaned effects, unsubscribed subscriptions, orphaned timers |
| 8 | Error State Handling | Components with access to errors but not rendering them |
| 9 | Loading State Handling | Buttons that can be double-clicked, data areas with no loading indicator |
| 10 | Uncontrolled State | Stuck boolean flags, state machines without error paths, optimistic updates without rollback |

## Key Improvements (v2)

### Server-Side Input Validation (Check 5b)

The most commonly missed category. The check now systematically audits every server route handler:

- Finds all route/controller/handler files
- For each POST/PUT/PATCH/DELETE endpoint, verifies `request.body` is validated with a schema
- Checks `request.params` and `request.query` for type assertions like `as { id: string }`
- Flags `request.body as { ... }` patterns as type assertions (not runtime validation)
- Reports a coverage ratio (validated routes / total routes)
- Upgrades severity if more than half of routes lack validation

### Type Assertions on Unvalidated Input (Check 3)

Now catches `as { ... }` type assertions on `request.body`, `request.params`, and `request.query` — not just `as any`. These patterns provide TypeScript type information but zero runtime guarantees, making them equivalent to `as any` from a validation perspective.

### Cross-Check Verification (Phase 2.5)

After completing all 10 checks, the analysis verifies overlap consistency:

1. **Check 3 + Check 5**: `request.body/params/query as { ... }` patterns must appear in both checks
2. **Check 1 + Check 10**: Mutations that only invalidate on success may leave stale data on error
3. **Check 7 + Check 10**: Resources only cleaned on success but not error are both leaks and uncontrolled state
4. **Coverage ratio**: If more than half of server routes lack validation, all Check 5 findings are upgraded one severity level

### Per-Instance Enumeration

Every finding must list the specific file:line. Grouping by pattern ("7 routes lack validation") is not acceptable — each instance is listed individually with its fix.

### Verification Checklist

The report includes a verification checklist for re-running the analysis after fixes:

- All Check 3 type assertions on unvalidated input now use schema validation
- All Check 5 server routes now validate request.body/params/query with schemas
- All cross-referenced findings have been addressed in both checks

### Actionable Fixes

Every finding includes a one-sentence fix description, not just in the recommendations section but inline with each finding.

## Supported Agents

| Agent | Format File | Install Target | Invocation |
|-------|------------|----------------|------------|
| Claude Code | `claude-code.md` | `~/.claude/commands/` | `/defensive-analysis [path]` |
| Cursor | `cursor.mdc` | `~/.cursor/rules/` | @-mention or auto-attached by description matching |
| GitHub Copilot | `copilot.instructions.md` | `.github/instructions/` | Auto-applied when editing matching files |

## Installation

Use the install script to set up skills for one or all agents:

```bash
# Install for all agents
./agents/install.sh install

# Install for a specific agent
./agents/install.sh install claude-code
./agents/install.sh install cursor
./agents/install.sh install copilot

# List available and installed skills
./agents/install.sh list

# Uninstall
./agents/install.sh uninstall claude-code
./agents/install.sh uninstall all
```

See the [agents README](../README.md) for more details.

## Usage

### Claude Code

```
/defensive-analysis                    # Analyze the project root
/defensive-analysis src/components     # Analyze a specific directory
```

### Cursor

In Cursor, the rule is available via @-mention (`@defensive-analysis`) or automatically suggested by the agent when the description matches the current task. Set `alwaysApply: true` in the frontmatter to have it always active.

### GitHub Copilot

Once installed (copied to `.github/instructions/`), the guidelines are automatically applied when you're editing files matching the `applyTo` glob patterns. No explicit invocation needed.

## Format Differences

The three format files contain the same core analysis logic but are adapted for each agent's interaction model:

- **Claude Code** (`claude-code.md`): Invoked as a slash command with an optional path argument (`$ARGUMENTS`). Uses Claude Code's tool permissions (`Read`, `Glob`, `Grep`, `Bash`).
- **Cursor** (`cursor.mdc`): Activated by description matching or @-mention. No argument passing; uses "current project or specified path" instead of `$ARGUMENTS`. Uses Cursor's frontmatter schema (`description`, `globs`, `alwaysApply`).
- **GitHub Copilot** (`copilot.instructions.md`): Always-on context applied during code review and suggestion generation. No interactive invocation; framed as coding guidelines rather than a command. Uses Copilot's `applyTo` frontmatter for file matching.

## Canonical Source

`claude-code.md` is the canonical source for this skill. When updating the analysis logic or checks, edit it first, then propagate changes to `cursor.mdc` and `copilot.instructions.md`.

## License

GPL-3.0 — See the [LICENSE](../../LICENSE) file for details.