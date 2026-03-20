---
name: Engineering Base
description: "Universal engineering principles for all projects and all AI tools. SOLID, GRASP, Architecture, Security, Readability, TDD, Performance, Java EO+EJ, React, Git. Single source of truth."
---

# Engineering Base — Universal Principles

> **Single source of truth.** Edit here first, then sync to tools.
> Derived into: `~/.claude/CLAUDE.md` | `~/.gemini/GEMINI.md` | `~/.copilot/agents/`

## SOLID (Java + React)
- **S — Single Responsibility**: one reason to change per class/component/hook. If two concerns evolve independently, split them
- **O — Open/Closed**: extend behavior by adding new code, not by modifying existing. Java: strategy/template method. React: composition, slots, render props over growing if-chains
- **L — Liskov Substitution**: subtypes must honor their base's behavioral contract. Variants and overrides must not break callers expecting the base behavior
- **I — Interface Segregation**: prefer narrow focused interfaces over fat ones. Java: split large interfaces. React: split large prop types; reject "kitchen-sink" components
- **D — Dependency Inversion**: depend on abstractions, not concretions. Java: inject via interfaces. React: inject via props/context; never import concrete services directly into components

## GRASP (Java — React analogies where applicable)
- **Information Expert**: assign responsibility to the class/module that already holds the required data to fulfill it
- **Low Coupling / High Cohesion**: minimize cross-module dependencies; keep related behavior together; unrelated behavior gets its own unit
- **Controller**: one coordinator per use case — Java: Activity or Handler; React: saga or feature hook
- **Polymorphism**: replace conditional type-dispatching with polymorphic behavior — strategy, template method, discriminated union components
- **Protected Variations**: shield code from unstable or external integration points with a stable abstraction (interface, adapter, facade, port)

## Architecture — Clean + Layered
- **Dependency rule**: inner layers (domain/business) must never depend on outer layers (UI, DB, framework). Dependencies always point inward
- **Layered contracts**: presentation → business logic → data access, with explicit contracts between each layer
- **Java**: separate business logic, entry points, and persistence into distinct layers — no business logic in persistence mappings or entry points
- **React**: sagas/hooks = orchestration; selectors = derivations; components = compose and render only. No logic in JSX
- **Stateless by default**: prefer stateless functions and components; keep state as close to where it's used as possible; lift only when multiple components need it
- **Decouple integration points**: wrap external APIs, DB and 3rd-party services behind interfaces/adapters — enables substitution, mocking and testability

## Security — Mandatory
- **Validate and sanitize all inputs**: never trust data from any source — validate type, length, format and range at every system boundary. Explicitly define what is valid and reject everything else by default
- **Prevent SQL injection**: parameterized queries always — named/positional params only. Never concatenate user input into SQL strings
- **Prevent XSS**: encode/escape all output before rendering. Never reflect unescaped user input in responses or templates
- **No secrets in code**: credentials, API keys, tokens and passwords must never appear in source code or version control. Use encrypted configuration
- **Protect sensitive data in logs**: never log PII, financial data, credentials or tokens. Mask or omit card numbers, account numbers and passwords in all log output
- **Block path traversal**: validate and sanitize all file paths. Reject `..` sequences. Use absolute paths from trusted roots only
- **Safe error responses**: never expose stack traces, internal system details or error specifics to external callers. Log internally, return generic messages externally
- **Enforce auth at every gate**: verify identity and permissions before every sensitive operation. Never assume authorization without explicit validation
- **Scan dependencies**: no known-CVE dependencies. Run SCA tools regularly. Update promptly when vulnerabilities are discovered
- **Secure external communication**: HTTPS/TLS only. Verify certificates. Never disable hostname verification or use trust-all certificates
- **Validate tokens and sessions**: check signature, expiry and scope before processing. Single-use tokens must never be reused
- **Encrypt sensitive data at rest**: persisted sensitive data must be encrypted. Keys managed via secure configuration, never hardcoded

## Readability & Maintainability
- **Names reveal intent**: classes, functions, variables and modules named after their purpose, not their implementation. Reject vague suffixes (Manager, Helper, Utils) unless justified by an established project convention
- **No magic values**: extract constants, enums or named configs for all business-rule values (limits, codes, identifiers) — not loop counters or trivial indices
- **Self-documenting first**: comments only where intent is non-obvious. Never comment what the code says — comment why
- **DRY**: every piece of knowledge has a single authoritative representation. Duplication of logic is a maintenance liability — extract when the same intent appears in 2+ places
- **Simplicity first (YAGNI)**: prefer the simplest solution that solves the task. Don't add patterns, abstractions, or indirection the scenario doesn't require. Future readers matter more than cleverness

## TDD
- **Red → Green → Refactor**: write the failing test first, implement the minimum to pass, then clean up — in that order
- **Test behavior, not internals**: test public contracts and observable outcomes, not private state or implementation details
- **F.I.R.S.T**: tests must be Fast, Isolated, Repeatable, Self-validating, Timely (written before or alongside production code — never retrofitted after the fact)
- **Java**: JUnit + Mockito; mock at layer boundaries (persistence, external services). React: Jest + React Testing Library; test from the user's perspective
- **Coverage target**: >75% overall; reach 100% on domain/business logic. Declare residual risk explicitly when below target
- **All equivalence classes** (EJ-49): test happy path + null/empty/boundary inputs + each documented exception — never only the success scenario
- **Descriptive names**: `method_condition_expectedOutcome` — the test name is the spec; reader should not need to read the body to understand intent
- **Verify exception contracts** (EJ-70/72): assert type, message, and cause — not just that the exception was thrown
- **Fakes > Stubs > Mocks**: prefer real in-memory implementations (fakes) or fixed-value returns (stubs) over mocks. Mocks couple tests to invocation details — they break on refactoring even when behavior is correct, and can give false confidence. Use Mockito only at boundaries you cannot control (external APIs, DB, filesystem)

## Performance
- **Measure first, optimize second**: profiling precedes any performance change; never optimize by intuition alone
- **Java**: avoid N+1 queries; prefer async (`CompletableFuture`) for I/O-bound work; use connection pooling; lazy-load costly resources (large datasets, slow queries, infrequently-needed dependencies)
- **React**: avoid unnecessary re-renders — profile with React DevTools Profiler before applying any optimization
- **React**: code-split by route/feature with lazy imports; never load all bundles upfront
- **Both**: O(n²) algorithms and synchronous blocking calls in frequently-executed paths (loops, request handlers, event processors) are always worth reviewing; favor O(n log n) or better

## Java — EO + EJ + Clean Code
- **Immutability** (EJ-17/EO): `private final` fields by default; prefer immutable classes — `final` unless explicitly designed for extension; no setters on domain objects; immutability is the default, mutability requires justification. `record` for value types, `Collections.unmodifiable*` for collections
- **Zero null** (EJ-55): `Optional<T>` for absence — never return null from domain or API methods
- **Defensive copies** (EJ-50): when accepting or returning mutable objects (arrays, `Date`, `List`) at class boundaries, always copy — never store or expose a reference to an object you don't control
- **Tell, Don't Ask**: expose behavior not state. Getters only on Records/DTOs. Max ~5 fields/deps per class
- **Constructors**: primary constructor enforces invariants, secondary constructors delegate to primary. Complex init → static factory `of()`/`from()` or Builder (EJ-1,2)
- **Types**: `List<T>` not `ArrayList<T>` (EJ-64). No raw generics. Type-safe public APIs
- **Concurrency**: `CompletableFuture`/`ExecutorService`. Never `new Thread()`. Document thread-safety
- **@Override** (EJ-40): annotate every intended override — compiler catches accidental mismatches and refactoring breaks
- **Resources** (EJ-9): always use try-with-resources for AutoCloseable (streams, connections, sessions). Never rely on finalizers
- **Exceptions**: no empty catch, preserve cause, no `catch(Exception e)`, checked for recoverable
- **Lombok**: `@Slf4j` for logging, `@Builder` for 4+ fields, `@Getter/@Setter` on mutable DTOs, `@UtilityClass` on static-only utility classes. Never `@Data` on entities, never `@SneakyThrows`. Records over `@Value` for immutable types
- **Logging**: SLF4J only (`@Slf4j`). Log errors, business-significant events, and branching with 3+ conditions affecting correctness — not routine operations. Evaluate necessity before adding; self-documenting code needs fewer logs. `System.out.println` forbidden

## React / Frontend
- **Functional components** only. No class components
- **No hooks in conditionals** — hooks must run unconditionally on every render
- **Avoid `any`**: use `unknown` when type is uncertain. Type props, hooks return, action payloads explicitly
- **`useMemo`/`useCallback`**: only after measuring with React DevTools Profiler — never by intuition
- **Derived state**: compute values during render — don't store in state what can be derived from existing state or props, and never sync derived values via effects
- **Effects scope**: use effects only to sync with external systems (APIs, DOM, browser) — data transforms, notifications, and user interactions belong in event handlers, not effects
- **UI states**: always handle loading, error and empty states in user-visible flows
- **Component size**: extract logic to custom hooks when JSX exceeds 100 lines (flows from SRP)
- **useEffect cleanup**: always return cleanup function when effects register subscriptions, timers, or listeners — prevents memory leaks on unmount
- **Accessibility**: semantic HTML for structure, ARIA labels on interactive elements, keyboard navigability on all interactive targets
- **Zero lint warnings** before closing a PR

## Git (All Projects)
- Conventional commits: `feat|fix|chore|refactor|docs|test(scope): [PROJECT_CODE-NUMERIC_ID] description`
- Focused commits: one logical change per commit
- Small PRs: one feature or fix per PR — easier to review, easier to revert
