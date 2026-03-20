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
- Use AskUserQuestion when clarification needed
- Read unknown files with `limit: 150`; Grep first for patterns

## Git
- Format: `feat|fix|chore(scope): [TICKET] description`
- One logical change per commit; small focused PRs
