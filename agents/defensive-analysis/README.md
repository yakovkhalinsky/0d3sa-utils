# defensive-analysis

Run 10 defensive code analysis checks that catch common bugs causing production incidents. Auto-detects the project's stack and adapts checks accordingly. Outputs a PASS/FAIL report with file:line references, actionable fixes, and a summary score.

## The 10 Checks

| # | Check | What it catches |
|---|-------|------------------|
| 1 | Mutation Invalidation | Mutations that don't invalidate/refetch dependent queries |
| 2 | Query Error Handling | Queries that swallow or ignore errors |
| 3 | Type Safety | `as any`, `as { ... }` type assertions on unvalidated input, `: any` type annotations, `as unknown as` double-cast chains, unexplained `@ts-ignore`, non-null assertions |
| 4 | API Path Safety | Hardcoded inline API paths instead of centralized route maps |
| 5 | Runtime Validation (Client + Server) | External data entering the app without schema validation — covers both client-side API responses AND server-side request body/params/query. Distinguishes "not validated at all" (medium/critical) from "validated but type-widened" (low). |
| 6 | State Lifecycle Docs | Async hooks/stores missing Error, Cleanup, and Transitions documentation |
| 7 | Memory Leaks | Un-cleaned effects, unsubscribed subscriptions, orphaned timers |
| 8 | Error State Handling | Components with access to errors but not rendering them |
| 9 | Loading State Handling | Buttons that can be double-clicked, data areas with no loading indicator |
| 10 | Uncontrolled State | Stuck boolean flags, state machines without error paths, optimistic updates without rollback |

## Key Improvements (v3)

### `: any` Type Annotations (Check 3, item 4)

Now catches `: any` type annotations on variables, returns, and callbacks — not just `as any` casts. Patterns like `(m: any) =>`, `let result: any`, `function foo(): any`, and `(request: any, reply: any)` are flagged as type safety issues. In server route files, these also serve as signals for missing validation (cross-referenced to Check 5).

### `as unknown as` Double-Cast Chains (Check 3, item 6)

Catches `(obj as unknown as { prop: Type }).prop` patterns that use `unknown` as an intermediary to bypass encapsulation. These indicate a missing getter method or a need to widen the source type.

### Severity Distinction for Check 5b (Runtime Validation)

Findings are now distinguished by severity:
- **Not validated at all** (no schema, just type assertions or raw destructuring): **medium** in server code, **critical** if no validation library exists
- **Validated but type-widened** (a validation helper exists, but `as any` or `: any` widens the type afterward): **low** — the runtime validation is present, just the type annotation is unnecessary

### Expanded Cross-Check Verification (Phase 2.5)

Cross-check now includes:
1. **Check 3 + Check 5 overlap** — includes `: any` annotations in server routes (not just `as { ... }` assertions)
2. **Severity consistency check** — verifies Check 5b severity assignments match the "validated vs not validated" distinction
3. Original overlaps (Check 1+10, Check 7+10, coverage ratio) remain

### Fix Mode (Phase 4)

When invoked with `--fix` or after analysis, systematically implements fixes in priority order:

1. **Check 5** (Runtime Validation) — Add schemas and validation helpers first
2. **Check 3** (Type Safety) — Replace type assertions with validation helper return types
3. **Check 7** (Memory Leaks) — Add cleanup returns, unsubscribe, clear timers
4. **Check 10** (Uncontrolled State) — Add error-path resets, rollback handlers
5. Remaining checks in priority order

This eliminates the need for a separate "implement fixes" pass — the analysis can now diagnose and fix in a single invocation.

### Actionable Fixes

Every finding includes a one-sentence fix description, not just in the recommendations section but inline with each finding.

## Previous Improvements (v2)

### Server-Side Input Validation (Check 5b)

The most commonly missed category. The check now systematically audits every server route handler:

- Finds all route/controller/handler files
- For each POST/PUT/PATCH/DELETE endpoint, verifies `request.body` is validated with a schema
- Checks `request.params` and `request.query` for type assertions like `as { id: string }`
- Flags `request.body as { ... }` patterns as type assertions (not runtime validation)
- Reports a coverage ratio (validated routes / total routes)
- Upgrades severity if more than half of routes lack validation

### Type Assertions on Unvalidated Input (Check 3)

Catches `as { ... }` type assertions on `request.body`, `request.params`, and `request.query` — not just `as any`. These patterns provide TypeScript type information but zero runtime guarantees, making them equivalent to `as any` from a validation perspective.

### Per-Instance Enumeration

Every finding must list the specific file:line. Grouping by pattern ("7 routes lack validation") is not acceptable — each instance is listed individually with its fix.

### Verification Checklist

The report includes a verification checklist for re-running the analysis after fixes:

- All Check 3 type assertions on unvalidated input now use schema validation
- All Check 3 `: any` annotations in server code have been replaced with proper types
- All Check 3 `as unknown as` double-cast chains have been replaced with proper accessors
- All Check 5 server routes now validate request.body/params/query with schemas
- All cross-referenced findings have been addressed in both checks

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