# Agents Hub (Claude Code + Cursor)

| Path | What | Consumed by |
|---|---|---|
| `skills/<name>/` | Shared skills | Claude, only via symlink in `~/.claude/skills/` or a project `.claude/skills/` |
| `mcp/jira-worklog-mcp/` | Tempo worklog MCP server | Claude MCP config |

Global rules: `~/.claude/CLAUDE.md` (stow from `Configs/claude`). Project rules: project `.claude/` (Claude) and `.cursor/rules/` (Cursor, team source).
A skill here that has no symlink is not loaded by any tool.
