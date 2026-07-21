# Context and Token Discipline
- Use the smallest amount of context necessary to complete the task correctly.
- Inspect only files, symbols, and documentation relevant to the requested change.
- Prefer targeted searches over broad repository exploration.
- Do not load or invoke specialized skills unless they are necessary for the task.
- Do not perform speculative analysis or investigate unrelated hypothetical issues.
- Do not refactor code unrelated to the requested change.
- Prefer incremental, focused changes over large autonomous workflows.
- Verify relevant assumptions against the codebase before acting; do not guess repository conventions.
- Ask for clarification when the requested scope, behavior, or acceptance criteria are ambiguous.

# Engineering Principles

## Security
- Validate inputs at system boundaries (type, length, format, range)
- Parameterized queries only; never concatenate user input into SQL
- Encode/escape all output before rendering
- Never log/expose PII, credentials, stack traces, or internal details
- Never hardcode secrets; use encrypted configuration

## New Code Standards
- **Naming**: reveal intent; no vague suffixes (Manager, Utils, Helper)
- **Constants**: business-rule values to named constants
- **Comments**: why not what
- **DRY**: one authoritative place per concept
- **YAGNI**: no abstractions until needed
- **Immutability**: `record`, `@Value`, final fields
- **Error Handling**: specific exceptions; never swallow
- **Resource Safety**: try-with-resources for I/O, SqlSession, streams

## Legacy Coexistence
- **Existing files**: keep style/patterns; don't refactor antipatterns
- **New code in old files**: follow new standards; old code unchanged
- **Mixed files**: mark `// NEW CODE SECTION`

## Execution Style
- Responses: code + minimal explanation
- For unknown files, search for relevant symbols or patterns first; read only the necessary surrounding context
- Each changed line traces to the request; remove only orphans your change created
- Non-trivial tasks: define verifiable goal (test/cmd) first; stop once met
- Background work: never `sleep >4m`; use `sleep 220` + cheap status poll to preserve prompt cache

## Git
- Format: `feat|fix|chore(scope): [TICKET] description`
- One logical change per commit; small focused PRs
- Never add `Co-Authored-By: Claude` (or any AI co-author trailer) to commit messages or PR bodies — applies to all workflows (SDD, normal agents, direct commits)
