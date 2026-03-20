# Engineering Principles (All Projects)

## Security (Non-Negotiable — Always)
- Validate all inputs at system boundaries (type, length, format, range)
- Parameterized queries only; never concatenate user input into SQL
- Encode/escape all output before rendering
- Never log/expose PII, credentials, stack traces, or internal details
- Never hardcode secrets; use encrypted configuration

## New Code Standards (New Files Only)
- **Naming**: Reveal intent; reject vague suffixes (Manager, Utils, Helper) without justification
- **Constants**: Extract all business-rule values (limits, codes, identifiers) to named constants
- **Comments**: Document **why**, not what; code should self-document
- **DRY**: Each piece of knowledge one authoritative place; extract duplication
- **YAGNI**: Prefer simplicity; don't add patterns/abstractions until needed
- **Immutability**: Prefer `record`, `@Value`, final fields over mutable objects
- **Error Handling**: Validate inputs, throw specific exceptions, never swallow errors silently
- **Resource Safety**: Use try-with-resources for I/O, SqlSession, streams

## Legacy Coexistence (Existing Files)
- **Editing existing code**: Keep the existing style/patterns — don't refactor antipatterns
- **Adding new code to old file**: New methods/classes follow new standards; old ones unchanged
- **Line of demarcation**: Comment `// NEW CODE SECTION` when new standards begin in mixed files

## Execution Style
- Responses: code + minimal explanation
- Use AskUserQuestion when clarification needed
- Read unknown files with `limit: 150`; Grep first for patterns

## Git
- Format: `feat|fix|chore(scope): [TICKET] description`
- One logical change per commit; small focused PRs
