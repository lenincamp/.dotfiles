# Global Agents Hub

## Purpose
Single source of truth for engineering principles, project rules, agent profiles, and skills across all AI tools (Claude Code, Gemini CLI, Copilot CLI, Cursor).

## Architecture

```
~/.agents/                                      # UNIFIED HUB
├── AGENTS.md                                   # This file — master index
├── engineering-base.agent.md                   # Universal principles (ALL projects)
├── react-senior-dev.agent.md                   # Generic React patterns
├── profiles/                                   # Generic role agents (no project references)
│   ├── backend.md                              # Java/Spring Boot specialist
│   ├── frontend.md                             # React/Redux specialist
│   ├── fullstack.md                            # End-to-end specialist
│   └── mobile.md                               # Cordova specialist
├── projects/
│   └── patagonia-cdp/
│       ├── README.md                           # How .cursor rules flow to tools
│       └── cursor-source.conf                  # Path mappings for sync
├── skills/                                     # Shared skills
│   ├── composition-patterns/                   # React composition
│   ├── react-best-practices/                   # React performance
│   ├── patagonia-cdp/                          # Patagonia conventions
│   └── english-coach/                          # English training
├── mcp/                                        # MCP servers
│   └── jira-worklog-mcp/
└── bin/
    └── sync-agents.sh                          # Master sync script
```

## Data Flow

```
GLOBAL RULES:
  engineering-base.agent.md
      ├──[generate]──> ~/.claude/CLAUDE.md
      ├──[generate]──> ~/.gemini/GEMINI.md
      └──[symlink]───> ~/.copilot/agents/engineering-base.agent.md

PROJECT RULES (Patagonia CDP):
  .cursor/rules/*.mdc  (TEAM SOURCE)
      ├──[sync]──> ~/.claude/projects/.../memory/{MEMORY,backend,frontend}.md
      ├──[sync]──> ar-patagonia-cdp/GEMINI.md
      ├──[sync]──> ar-patagonia-cdp/frontend/GEMINI.md
      └──[direct]> Copilot/Cursor read .cursor/ in-project

PROFILES (generic — project context loaded from memory files at runtime):
  profiles/{backend,frontend,fullstack,mobile}.md
      └──[symlink]──> ~/.claude/agents/{name}/{name}.md

SKILLS:
  skills/{name}/
      └──[symlink]──> ~/.claude/skills/{name}/SKILL.md
```

## Agents Inventory

| Agent | Role | Location |
|-------|------|----------|
| `engineering-base` | Universal principles for ALL projects | `engineering-base.agent.md` |
| `react-senior-dev` | Generic React senior dev | `react-senior-dev.agent.md` |

## Profiles Inventory

| Profile | Role | Skills |
|---------|------|--------|
| `backend` | Java 17 - 21 / Spring Boot specialist (generic) | — |
| `frontend` | React / Redux / Saga specialist (generic) | composition-patterns, react-best-practices |
| `fullstack` | End-to-end specialist (generic) | composition-patterns, react-best-practices |
| `mobile` | Cordova Android/iOS specialist (generic) | composition-patterns |

> Profiles are generic role definitions. Project-specific rules are loaded from memory files (condensed from `.cursor/rules/`). The `patagonia-cdp` skill is invoked on-demand, not embedded in profiles.

## Skills Inventory

| Skill | Source | Used By |
|-------|--------|---------|
| `composition-patterns` | `skills/composition-patterns/` | frontend, fullstack, mobile |
| `react-best-practices` | `skills/react-best-practices/` | frontend, fullstack |
| `patagonia-cdp` | `skills/patagonia-cdp/` | on-demand (not auto-loaded) |
| `english-coach` | `skills/english-coach/` | standalone |

## Tool Integration

| Tool | Global config | Project config | Agent profiles | Skills |
|------|--------------|----------------|----------------|--------|
| **Claude Code** | `~/.claude/CLAUDE.md` (generated) | memory files (generated) | symlinks in `~/.claude/agents/` | symlinks in `~/.claude/skills/` |
| **Gemini CLI** | `~/.gemini/GEMINI.md` (generated) | `GEMINI.md` in project (generated) | N/A | N/A |
| **Copilot CLI** | symlinks in `~/.copilot/agents/` | reads `.cursor/rules/` directly | N/A | N/A |
| **Cursor** | N/A | `.cursor/rules/` (TEAM SOURCE) | N/A | N/A |

## Sync

```bash
~/.agents/bin/sync-agents.sh          # Full sync
~/.agents/bin/sync-agents.sh --dry-run  # Preview changes
```

Run after editing any source file or when team updates `.cursor/rules/`.
