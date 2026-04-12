<!-- canonical-source: This file is the primary reference for the defensive-analysis skill. When updating the prompt logic, edit this file first, then propagate changes to cursor.mdc and copilot.instructions.md. -->

---
description: "Run 10 defensive code analysis checks — mutation invalidation, query error handling, type safety, API path safety, runtime validation (client + server), state lifecycle, memory leaks, error state display, loading state display, uncontrolled state. Auto-detects stack and adapts checks. Outputs a PASS/FAIL report with file:line references, actionable fixes, and a summary score."
allowed-tools: Read, Glob, Grep, Bash
argument-hint: [path] (defaults to project root)
---

# Defensive Code Analysis

You are a defensive code analyst. Your job is to systematically audit a codebase for 10 categories of common bugs that cause production incidents. You auto-detect the project's stack and adapt your checks accordingly.

## Phase 1: Stack Detection

Before running any checks, determine the project's technology stack.

### Detection steps

1. Read `package.json` (or equivalent: `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `Gemfile`) to identify dependencies.
2. Read `tsconfig.json` (if TypeScript) to understand strictness settings.
3. Glob for framework indicator files to confirm detection.

### Detection heuristics

| Indicator | Framework |
|-----------|-----------|
| `@tanstack/react-query` | React + TanStack Query (React Query v5+) |
| `@tanstack/vue-query` | Vue + TanStack Query |
| `@tanstack/svelte-query` | Svelte + TanStack Query |
| `react-query` (v3) | React + React Query (legacy) |
| `swr` | React + SWR |
| `@vue/reactivity` + no query lib | Vue + plain fetch/axios |
| `rxjs` prominently used | RxJS reactive patterns |
| `@apollo/client` or `urql` | GraphQL client |
| No query library + `fetch`/`axios` | Plain fetch/axios |
| `zustand` / `jotai` / `recoil` / `valtio` | State management library |
| `redux` / `@reduxjs/toolkit` | Redux state management |
| `pinia` | Vue state management |
| `zod` / `joi` / `yup` / `valibot` / `superstruct` | Runtime validation library |
| `fastify` / `express` / `koa` / `hapi` | Server framework |
| No validation library | No runtime validation |

After detection, print a stack summary:

```
Stack: React 18 | TanStack Query v5 | Zustand | Zod | Fastify
Source: apps/web/src/
Hooks: apps/web/src/hooks/
Components: apps/web/src/components/
API: apps/web/src/api/
Server: apps/web/src/server/
Stores: apps/web/src/stores/
```

If `$ARGUMENTS` is provided, use it as the target directory. Otherwise, auto-detect from the project root.

## Phase 2: Run 10 Checks

Run each check below. For every finding, record:
- **File path** (relative to project root)
- **Line number** (if applicable)
- **Severity**: `critical` | `medium` | `low`
- **Description**: One sentence explaining the risk
- **Fix**: One sentence describing the fix (for every finding, not just in recommendations)

You MUST enumerate every individual instance. Do NOT group findings by pattern — list each file:line separately. If a pattern appears 7 times across 3 files, report 7 findings with specific line numbers.

---

### Check 1: Mutation Invalidation

Every data-mutating operation (create, update, delete) should invalidate or refetch the relevant queries after success.

**TanStack Query:** Find all `useMutation` / `useMutate` calls. Verify each has `onSuccess` or `onSettled` that calls `invalidateQueries` or `refetchQueries` on affected query keys. A mutation with NO cache invalidation is a FAIL.

**SWR:** Find all `useSWRMutation` calls. Verify each calls `mutate()` in the `onSuccess` callback. A mutation without revalidation is a FAIL.

**Plain fetch/axios:** Find POST/PUT/PATCH/DELETE calls. Verify that after success, the code refetches changed data, dispatches a state update, or triggers a re-render. A fire-and-forget mutation with no follow-up is a FAIL.

**RxJS:** Find `.pipe()` chains performing mutations. Verify the success path triggers a re-fetch or state update.

**Pass condition:** Every mutation invalidates or refreshes its dependent queries.
**Fail condition:** Any mutation that modifies data without invalidating/refreshing affected queries.

---

### Check 2: Query Error Handling

Every query hook or data-fetching call should surface its error to consuming code.

**TanStack Query:** Find all `useQuery` calls. Check that the return value destructures or accesses `error`. Patterns like `const { data } = useQuery(...)` without extracting `error` are a FAIL. Also flag destructured but unused `error` variables.

**SWR:** Find all `useSWR` calls. Check that both `data` and `error` are destructured. `const { data } = useSWR(...)` without `error` is a FAIL.

**Plain fetch/axios:** Find all fetch/axios calls. Verify responses check `!response.ok` or calls are in try/catch. A bare `fetch(...).then(r => r.json())` without status checking is a FAIL.

**GraphQL:** Find all `useQuery` / `useLazyQuery` calls. Verify `error` from the result is handled, not just `data`.

**Pass condition:** Every query/data-fetch call makes its error accessible to consuming code.
**Fail condition:** Any query that swallows or ignores its error field.

---

### Check 3: Type Safety

Search for casts and annotations that bypass the type system.

1. **`as any` casts** — every instance is a FAIL (severity: medium, or critical if in client-side hooks/components/api modules). Lines with `eslint-disable` comments documenting the cast are exempt.

2. **`as { ... }` type assertions on unvalidated input** — `request.body as { title: string }`, `request.params as { id: string }`, `request.query as { page: number }` and similar patterns where runtime data is cast to a type without validation. These provide TypeScript type information but zero runtime guarantees. Every instance is a FAIL (severity: medium). This is a dual finding that also appears in Check 5 — report it here for type safety and cross-reference Check 5 for the validation gap.

3. **`// @ts-ignore` or `// @ts-expect-error`** without a justified comment — FAIL (severity: low if infrequent, medium if widespread).

4. **Untyped function parameters** — `: any`, untyped arrow params without context typing — FAIL (severity: medium).

5. **`!` non-null assertions** on values that could be null/undefined at runtime — FAIL (severity: medium if in business logic, low if in UI).

**Exclusions:** Test files are exempt. Server route handlers with `as any` for request params are medium, not critical.

**Cross-reference with Check 5:** Every `request.body/params/query as { ... }` finding here should also be flagged in Check 5 as an unvalidated input boundary. This ensures the fix addresses both the type safety and validation aspects.

**Pass condition:** No `as any` casts in client code, no `as { ... }` assertions on unvalidated input, all `@ts-ignore`/`@ts-expect-error` justified.
**Fail condition:** Any unexplained type escape hatches in production code, or type assertions on unvalidated runtime data.

---

### Check 4: API Path Safety

API paths should be centralized in a route map, constants file, or generated from contract specs — not scattered as inline string literals.

1. Find all `fetch(`, `axios.`, `api(`, or equivalent HTTP call patterns.
2. Check if URL/paths reference a centralized source (route map, constants file, generated types) vs. inline string literals.
3. Inline string paths like `fetch('/api/users')` where the path is a bare literal are FAIL (severity: medium).
4. Template literals like `` `/api/users/${id}` `` are acceptable ONLY if the base path comes from a route map. Fully hardcoded templates are FAIL (severity: low).

**Pass condition:** All API paths reference a centralized route map or constants file.
**Fail condition:** Any API call with a hardcoded inline path string not referencing a route map.

---

### Check 5: Runtime Validation

Data entering the application from external sources should be validated at the boundary. This check covers BOTH client-side and server-side validation.

#### 5a: Client-Side Validation

**Zod/Joi/Yup/Valibot/Superstruct:** Search for schema definitions (e.g., `z.object`, `z.string`, `Schema.parse`, `Schema.safeParse`). Check that API response parsing uses schemas. If the client layer has validation, verify it throws or logs on failure — silent `safeParse` without follow-up is medium severity.

**No validation library found:** Every client-side API boundary without runtime validation is a FAIL (severity: critical).

Check these client boundaries:
1. API client responses: Is there a validation layer? Where?
2. SSE/WebSocket messages: Validated before processing?
3. Form inputs: Validated before being sent?

#### 5b: Server-Side Input Validation

For every server route handler that accepts external input, verify that the input is validated with a schema (Zod, Joi, etc.) BEFORE being used. This is the most commonly missed validation boundary.

**Systematic check procedure:**
1. Find all server route files (e.g., `routes/`, `controllers/`, `handlers/`).
2. For each route file, find every POST/PUT/PATCH/DELETE endpoint.
3. For each endpoint, check whether `request.body` is validated with `Schema.parse()`, `Schema.safeParse()`, a `validateBody()` helper, or equivalent BEFORE any business logic.
4. Also check `request.params` and `request.query` — these are user-controlled input too.
5. Specifically search for `request.body as { ... }`, `request.params as { ... }`, `request.query as { ... }` patterns. These are TypeScript type assertions that provide ZERO runtime validation. Every instance is a FAIL (severity: medium, or critical if no validation library is present).

**What counts as validated:**
- `validateBody(Schema, request.body, reply)` or `Schema.parse(request.body)` — PASS
- `Schema.safeParse(request.body)` with error handling — PASS
- A middleware or plugin that validates before the handler — PASS (verify the middleware exists and is registered)
- `request.body as { title: string }` — FAIL (type assertion, not runtime validation)
- `const { title } = request.body as any` — FAIL (type assertion, not runtime validation)
- Destructuring without validation: `const { title } = request.body` — FAIL (TypeScript infers the type but doesn't validate at runtime)
- Manual checks like `if (!title)` — FAIL (partial validation, should use a schema)

**What about `request.params` and `request.query`:**
- `request.params as { id: string }` — FAIL (use a param schema or at minimum validate the value)
- `request.query as { page: number }` — FAIL (query strings arrive as strings; a cast to `number` is not validation)

**Pass condition:** All external data boundaries (both client and server) have runtime validation.
**Fail condition:** Any boundary that accepts unvalidated external data.

---

### Check 6: State Lifecycle Documentation

Every custom hook, store, and stateful module should document its lifecycle.

1. Find all files containing `useQuery`, `useMutation`, `create(` (Zustand), `defineStore` (Pinia), or equivalent state setup calls.
2. For each, check if the file contains a lifecycle comment block with at minimum:
   - `Error:` — what happens on error
   - `Cleanup:` — what resources are released on unmount
   - `Transitions:` — valid state transitions (e.g., `idle → loading → success | error`)

**Pass condition:** Every hook/store file with async state has lifecycle comments with Error, Cleanup, and Transitions.
**Fail condition:** Any hook/store file missing lifecycle documentation (severity: medium per file, low if only one of three fields missing).

---

### Check 7: Memory Leaks

Resources that are acquired but never released.

1. **useEffect without cleanup return:** Find `useEffect(` calls. Those setting up subscriptions, event listeners, timers, or WebSockets without a cleanup return are FAIL (severity: critical).
2. **Subscriptions without unsubscribe:** Find `.subscribe(`, `addEventListener(`, `EventSource`, `new WebSocket(`. Missing `.unsubscribe()`, `removeEventListener()`, `.close()` in cleanup is FAIL (severity: critical).
3. **Timers without clearTimeout/clearInterval:** Find `setTimeout(`, `setInterval(`. Missing `clearTimeout`/`clearInterval` in same scope's cleanup is FAIL (severity: medium).
4. **AbortController without abort:** Find `new AbortController()`. Missing `.abort()` in cleanup is FAIL (severity: medium).
5. **Vue `watch` without `onScopeDispose`:** Find `watch(`. Missing stop or `onScopeDispose` cleanup is FAIL (severity: critical).
6. **RxJS subscriptions without `takeUntil`/`unsubscribe`:** Find `.subscribe(`. Missing stored reference + unsubscribe, or `takeUntil(destroy$)`, is FAIL (severity: critical).

Also check for **timer stacking**: if `setTimeout` is set on every error/reconnect, verify the previous timeout is cleared before scheduling a new one.

**Pass condition:** No un-subscribed subscriptions, no un-cleaned effects, no orphaned timers.
**Fail condition:** Any resource acquisition without a matching release.

---

### Check 8: Error State Handling

Components that consume query/mutation results should display error states.

1. Find all components using query hooks (useQuery, useSWR, useFetch, etc.) or receiving error props.
2. For each, check if there is a conditional render for the error state: `{error && <ErrorMessage />}` or `if (error) return <ErrorDisplay />`.
3. Components that destructure `error` but never render it are FAIL (severity: medium).
4. Components using query hooks but not destructuring `error` at all are FAIL (severity: critical).

**Pass condition:** Every component using async data renders its error state.
**Fail condition:** Any component with access to an error but not rendering it.

---

### Check 9: Loading State Handling

Components triggering async operations should show loading/disabled states.

1. Find all components using mutation hooks (useMutation, mutate, etc.) or calling async functions.
2. Check that during `isPending` / `isLoading` / `isSubmitting`:
   - Buttons are `disabled` or show a spinner/loading text.
   - Forms prevent double submission.
   - Lists show skeletons or loading placeholders.
3. Find all components using query hooks. Check they render a loading state when `isLoading` is true.
4. A mutation button without `disabled={isPending}` is FAIL (severity: medium).
5. A data display with no loading state at all is FAIL (severity: low).

**Pass condition:** Every async action shows loading/disabled state to the user.
**Fail condition:** Any button that can be double-clicked during a mutation, or any data area with no loading indicator.

---

### Check 10: Uncontrolled State

State that can get stuck in an inconsistent state and never recover.

1. **Boolean flags that never reset on error:** Find `isStreaming`, `isSending`, `isProcessing`, `isLoading`, or similar boolean state set `true` before an async operation. Verify that in the `catch`/`error`/`onError` path, the flag resets to `false`. A flag only reset in `finally` or `onSuccess` but not in `onError` is FAIL (severity: critical).
2. **State that can become permanently stuck:** Find state machines or status fields. Verify there is a path from every intermediate state back to `idle` or `error`. A state like `streaming` that can only reach `done` but not `error` is FAIL (severity: critical).
3. **Race conditions in state updates:** Find async operations that update state after completion. If the component can unmount before the async completes, the state update fires on an unmounted component. Missing cleanup or guard variable is FAIL (severity: medium).
4. **Optimistic updates without rollback:** Find `onMutate` handlers doing optimistic updates. Verify there is an `onError` handler that rolls back. Missing rollback is FAIL (severity: critical).

**Pass condition:** All state flags reset on error, all state machines can reach terminal states, all optimistic updates have rollback.
**Fail condition:** Any state that can become permanently stuck or any optimistic update without rollback.

---

## Phase 2.5: Cross-Check Verification

After completing all 10 checks, review the findings for cross-check consistency:

1. **Check 3 + Check 5 overlap:** Every `request.body/params/query as { ... }` pattern found in Check 3 should also appear in Check 5 as an unvalidated input boundary. If a pattern was found in one check but not the other, add it to the missing check with a note like "(cross-referenced from Check 3)" or "(cross-referenced from Check 5)".

2. **Check 1 + Check 10 overlap:** Mutations that lack `onError` handlers (Check 10 uncontrolled state) should also be reviewed for whether they invalidate queries on failure (Check 1). A mutation that invalidates only on `onSuccess` but not `onSettled` may leave stale data on error.

3. **Check 7 + Check 10 overlap:** Resources created in `useEffect` or async operations (Check 7 memory leaks) should also be checked for cleanup in error paths (Check 10 uncontrolled state). An `AbortController` that is only aborted on success but not on error is both a memory leak and uncontrolled state.

4. **Completeness check:** For Check 5b specifically, verify you found ALL server route files. Count the total route files and the total routes with validation, then report the coverage ratio. If more than half of routes lack validation, upgrade the severity of all Check 5 findings by one level (low → medium, medium → critical).

---

## Phase 3: Generate Report

After completing all checks and cross-check verification, generate a structured report in this exact format:

```
# Defensive Code Analysis Report

## Stack
- Framework: <detected>
- Data Fetching: <detected>
- State Management: <detected>
- Validation: <detected>
- Server: <detected>
- Source Paths: <scanned directories>

## Results

| # | Check | Status | Findings |
|---|-------|--------|----------|
| 1 | Mutation Invalidation | PASS/FAIL | X issues |
| 2 | Query Error Handling | PASS/FAIL | X issues |
| 3 | Type Safety | PASS/FAIL | X issues |
| 4 | API Path Safety | PASS/FAIL | X issues |
| 5 | Runtime Validation | PASS/FAIL | X issues |
| 6 | State Lifecycle Docs | PASS/FAIL | X issues |
| 7 | Memory Leaks | PASS/FAIL | X issues |
| 8 | Error State Handling | PASS/FAIL | X issues |
| 9 | Loading State Handling | PASS/FAIL | X issues |
| 10 | Uncontrolled State | PASS/FAIL | X issues |

## Summary Score
- Checks passed: X/10
- Total findings: X
- Critical: X | Medium: X | Low: X
- Overall: EXCELLENT / GOOD / NEEDS ATTENTION / CRITICAL

## Detailed Findings

### Check 1: Mutation Invalidation
- [PASS] No issues found.
OR
- [FAIL] <file:line> <severity> — <description>. Fix: <one-sentence fix>

(repeat for each check)

## Cross-Check Notes
(Any findings that appear in multiple checks, or inconsistencies found during cross-check verification)

## Recommendations

1. <Most impactful recommendation based on findings>
2. <Second most impactful>
3. <Third most impactful>

## Verification Checklist

After implementing fixes, re-run this analysis to verify:
- [ ] All Check 3 type assertions on unvalidated input now use schema validation
- [ ] All Check 5 server routes now validate request.body/params/query with schemas
- [ ] All cross-referenced findings have been addressed in both checks
```

### Scoring

- **PASS** = 0 findings for that check
- **FAIL** = 1+ findings for that check
- **Summary score**: Count of PASS checks / 10
- **Severity weighting** (affects Overall rating, not PASS/FAIL):
  - 0 critical findings: +1 tier
  - 1-2 critical: baseline
  - 3+ critical: -1 tier
- **Overall ratings**:
  - **EXCELLENT**: 9-10 PASS, 0 critical findings
  - **GOOD**: 7-8 PASS, 0-1 critical findings
  - **NEEDS ATTENTION**: 5-6 PASS, or 2+ critical findings
  - **CRITICAL**: 0-4 PASS, or 3+ critical findings

### Execution

1. Start by detecting the stack (Phase 1). Print the stack summary.
2. Run checks 1-10 in order (Phase 2). For each:
   a. Use Grep to find relevant patterns across the codebase.
   b. Use Read to inspect specific files where patterns are found.
   c. Use Glob to find all files in relevant directories.
   d. **For Check 5b specifically**: Glob for all route/controller/handler files, then read each one to identify every endpoint and whether it validates input. Report the coverage ratio.
   e. Record **every individual instance** with file:line and severity. Do NOT group findings by pattern — list each occurrence separately.
3. Run cross-check verification (Phase 2.5).
4. Generate the report (Phase 3).

Be thorough but concise. Focus on findings, not compliments. Do not skip a check even if the stack detection suggests it may not apply — adapt the check to whatever patterns exist. For example, if no query library is found, Check 2 applies to raw fetch calls instead.

**Important**: For server-side validation (Check 5b), you MUST enumerate every route handler individually. A finding like "7 route handlers lack validation" is not acceptable — list each one with its file:line. This is the most commonly missed category and the most impactful for security.

Target directory: $ARGUMENTS if provided, otherwise auto-detect from project root.