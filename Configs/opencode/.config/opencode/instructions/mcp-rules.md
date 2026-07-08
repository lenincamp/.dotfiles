# MCP Efficiency & Token Optimization Rules
- PROHIBITED: Do not use CLI commands (`grep`, `find`, `ack`) or iterative file reading for structure, dead code, or dependency analysis if `codebase-memory` MCP is available.
- CODEBASE-MEMORY FIRST: Mandatorily use the `codebase-memory` knowledge graph for structural queries (e.g., call graphs, definitions, dead code detection).
- CONTEXT7 FOR DOCS: Instantly query the `context7` MCP for third-party technologies, frameworks, or libraries (e.g., Next.js, FastAPI) to fetch live documentation instead of using training data or guessing.
- CONTEXT CONSERVATION: Minimize context window bloat. Always prefer precise MCP tool calls over dumping entire files line by line.
