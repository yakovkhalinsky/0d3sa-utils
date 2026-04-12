---
applyTo: "**/*.{ts,tsx,js,jsx,vue,svelte,py,go,rs,java}"
---

# Defensive Code Analysis Guidelines

When writing or reviewing code, apply these 10 defensive analysis checks to catch common bugs that cause production incidents. Adapt the checks to the project's technology stack.

## Stack Awareness

Before applying checks, identify the project's stack from its dependencies:

- **Data fetching**: TanStack Query, SWR, plain fetch/axios, RxJS, GraphQL
- **State management**: Zustand, Redux, Pinia, Jotai, Recoil, Valtio
- **Validation**: Zod, Joi, Yup, Valibot, Superstruct, or none
- **Server framework**: Fastify, Express, Koa, Hapi, or none
- **Framework**: React, Vue, Svelte, or other

Adapt each check to the patterns and libraries the project actually uses.

## The 10 Checks

### 1. Mutation Invalidation

Every data-mutating operation (create, update, delete) must invalidate or refetch the relevant queries after success.

- **TanStack Query**: Every `useMutation` must have `onSuccess` or `onSettled` calling `invalidateQueries`/`refetchQueries` on affected query keys.
- **SWR**: Every `useSWRMutation` must call `mutate()` in `onSuccess`.
- **Plain fetch/axios**: Every POST/PUT/PATCH/DELETE must refetch changed data, dispatch a state update, or trigger a re-render after success.
- **RxJS**: Every mutation `.pipe()` chain must trigger a re-fetch or state update in the success path.

Fire-and-forget mutations with no follow-up are a bug.

### 2. Query Error Handling

Every query or data-fetching call must surface its error to consuming code.

- **TanStack Query**: Every `useQuery` return must destructure or access `error`. Patterns like `const { data } = useQuery(...)` without `error` are a bug.
- **SWR**: Every `useSWR` call must destructure both `data` and `error`.
- **Plain fetch/axios**: Every call must check `!response.ok` or be wrapped in try/catch. Bare `.then(r => r.json())` without status checking is a bug.
- **GraphQL**: Every `useQuery`/`useLazyQuery` result must handle `error`, not just `data`.

### 3. Type Safety

Avoid casts and annotations that bypass the type system.

- `as any` casts are bugs in client-side hooks, components, and API modules. Documented `eslint-disable` exemptions are acceptable.
- `as { ... }` type assertions on unvalidated input (`request.body as { title: string }`, `request.params as { id: string }`, `request.query as { ... }`) are bugs. These provide TypeScript type information but zero runtime guarantees. Flag these as type safety issues here and also as validation gaps in Check 5.
- `@ts-ignore` or `@ts-expect-error` without a justified comment is a bug.
- `: any` type annotations on variables, returns, and callbacks are bugs (severity: medium in server code, low in client code). These include `(m: any) =>`, `let result: any`, `function foo(): any`, `(request: any, reply: any)`. They often signal that surrounding code lacks proper validation.
- `as unknown as { ... }` double-cast chains that bypass private/internal fields are bugs. Fix: add a proper getter method or widen the type.
- `!` non-null assertions on values that could be null/undefined at runtime are bugs.

Test files are exempt.

### 4. API Path Safety

API paths must come from a centralized route map, constants file, or contract-generated types — not inline string literals.

- Bare `fetch('/api/users')` with a hardcoded path string is a bug.
- Template literals like `` `/api/users/${id}` `` are acceptable only if the base path comes from a route map.

### 5. Runtime Validation

Data entering the application from external sources must be validated at the boundary. This check covers BOTH client-side and server-side validation.

**5a: Client-Side Validation**
- If a validation library (Zod, Joi, Yup, Valibot, Superstruct) is present, verify API responses are parsed through schemas. Silent `safeParse` without follow-up is a bug.
- If no validation library exists, every API boundary without runtime validation is a critical bug.
- Check: API client responses, SSE/WebSocket messages, form inputs before submission.

**5b: Server-Side Input Validation**
This is the most commonly missed category and the most impactful for security.

For every server route handler that accepts external input:
- `request.body` must be validated with a schema (Zod, Joi, etc.) BEFORE any business logic.
- `request.params` must be validated (they are user-controlled input).
- `request.query` must be validated (query strings arrive as strings; a cast to `number` is not validation).
- `request.body as { title: string }` is a type assertion, NOT runtime validation — it's a bug.
- `request.params as { id: string }` is a type assertion, NOT runtime validation — it's a bug.
- `request.query as { page: number }` is a type assertion, NOT runtime validation — it's a bug.
- Destructuring without validation (`const { title } = request.body`) provides no runtime guarantees — it's a bug.
- Manual checks like `if (!title)` are partial validation — should use a schema.

What counts as validated: `validateBody(Schema, request.body, reply)`, `Schema.parse(request.body)`, `Schema.safeParse(request.body)` with error handling, or a registered validation middleware/plugin.

**Severity distinction:**
- **Not validated at all** (no schema, just type assertions or raw destructuring): medium bug (critical if no validation library exists).
- **Validated but type-widened** (a validation call exists earlier, but `as any` or `: any` widens the type afterward): low bug. Fix by using the typed return value from the validation helper.

**: any` as a validation gap signal:** When `: any` annotations appear in server route files (handler parameters, callback variables), check whether the surrounding code has proper schema validation. If not, report it as both a type safety issue (Check 3) and a validation gap (Check 5).

### 6. State Lifecycle Documentation

Every custom hook, store, and stateful module with async state must have a lifecycle comment block documenting:

- **Error**: What happens on error
- **Cleanup**: What resources are released on unmount
- **Transitions**: Valid state transitions (e.g., `idle -> loading -> success | error`)

Missing lifecycle documentation is a bug (medium severity per file, low if only one field is missing).

### 7. Memory Leaks

Resources that are acquired must be released.

- `useEffect` setting up subscriptions, listeners, timers, or WebSockets without a cleanup return is a critical bug.
- Subscriptions without `.unsubscribe()`, `removeEventListener()`, or `.close()` in cleanup are critical bugs.
- `setTimeout`/`setInterval` without `clearTimeout`/`clearInterval` in the same scope's cleanup is a medium bug.
- `AbortController` without `.abort()` in cleanup is a medium bug.
- Vue `watch` without `onScopeDispose` cleanup is a critical bug.
- RxJS `.subscribe()` without `takeUntil` or stored unsubscribe is a critical bug.

Also check for **timer stacking**: if `setTimeout` is set on every error/reconnect, the previous timeout must be cleared before scheduling a new one.

### 8. Error State Handling

Components consuming query/mutation results must render error states.

- Components that destructure `error` but never render it are medium bugs.
- Components using query hooks but not destructuring `error` at all are critical bugs.

Every component with access to an error must display it.

### 9. Loading State Handling

Components triggering async operations must show loading/disabled states.

- During `isPending`/`isLoading`/`isSubmitting`: buttons must be disabled, forms must prevent double submission, data displays must show loading indicators.
- A mutation button without `disabled={isPending}` is a medium bug.
- A data display with no loading state at all is a low bug.

### 10. Uncontrolled State

State that can get stuck in an inconsistent state must be prevented.

- **Boolean flags that never reset on error**: `isStreaming`, `isSending`, etc. set `true` before async must reset to `false` in the `catch`/`onError` path, not just `finally` or `onSuccess`. Critical bug if missing.
- **State that can become permanently stuck**: Every state machine must have a path from every intermediate state back to `idle` or `error`. A state like `streaming` that can only reach `done` but not `error` is a critical bug.
- **Race conditions in state updates**: Async operations updating state after component unmount need cleanup or guard variables. Missing guard is a medium bug.
- **Optimistic updates without rollback**: Every `onMutate` doing optimistic updates must have an `onError` handler that rolls back. Missing rollback is a critical bug.

## Cross-Check Verification

After applying all 10 checks, verify cross-check consistency:

1. **Check 3 + Check 5**: Every `request.body/params/query as { ... }` pattern and every `: any` annotation in server routes should appear in both Check 3 (type safety) and Check 5 (validation). If found in only one, add it to the other.
2. **Check 1 + Check 10**: Mutations that invalidate only on `onSuccess` but not `onSettled` may leave stale data on error.
3. **Check 7 + Check 10**: Resources (AbortController, EventSource, etc.) that are only cleaned up on success but not on error paths are both memory leaks and uncontrolled state.
4. **Severity consistency**: For Check 5b, "validated but type-widened" should be low severity; "not validated at all" should be medium (or critical if no validation library exists). Confirm severity before reporting.

## Fix Mode

When asked to fix findings, prioritize in this order:

1. **Check 5 (Runtime Validation)** — Add schemas and validation helpers to all unvalidated endpoints first. This closes security boundaries.
2. **Check 3 (Type Safety)** — Replace type assertions with validation helper return types, fix `: any` annotations, replace `as unknown as` chains.
3. **Check 7 (Memory Leaks)** — Add cleanup returns, unsubscribe, clear timers.
4. **Check 10 (Uncontrolled State)** — Add error-path resets, rollback handlers.
5. **Check 1 (Mutation Invalidation)** — Add `invalidateQueries`/`refetchQueries`.
6. **Check 2 (Query Error Handling)** — Destructure `error` from query hooks.
7. **Check 8/9 (Error/Loading States)** — Add conditional renders.
8. **Check 4 (API Path Safety)** — Extract inline paths to constants.
9. **Check 6 (State Lifecycle Docs)** — Add lifecycle comments.

## Applying These Checks

When reviewing or writing code, systematically evaluate it against each of the 10 checks. Record findings with file path, line number, severity (critical/medium/low), and a one-sentence description of the risk.

For server-side validation (Check 5b), enumerate every route handler individually — do not group findings by pattern. List each unvalidated endpoint with its file:line.

Prioritize findings by severity:
- **Critical**: Bugs that cause data loss, security vulnerabilities, or application crashes
- **Medium**: Bugs that cause poor user experience or degrade reliability
- **Low**: Bugs that are code quality issues or potential future problems