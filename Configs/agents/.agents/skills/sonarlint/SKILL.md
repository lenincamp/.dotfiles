---
name: sonarlint
description: Run SonarLint analysis on Java files. Detects security bugs, code smells and quality issues using the local SonarLint LSP. Invoke with /sonarlint — auto-detects modified files from git, or accepts a file/folder path as argument.
---

# SonarLint Analysis

Run a SonarLint scan on Java files using the local Mason-installed SonarLint language server.

## Workflow

### Step 1 — Resolve target files

Run the following to detect modified Java files (staged + unstaged):

```bash
git diff --name-only HEAD -- '*.java' 2>/dev/null
git diff --cached --name-only --diff-filter=ACM -- '*.java' 2>/dev/null
```

Deduplicate and convert to absolute paths using the project root:
```bash
git rev-parse --show-toplevel
```

**If modified Java files are found** → use them as the scan target.

**If no modified files are found** → ask the user:
> No modified Java files found. Enter a file path or folder to scan (e.g. `src/main/java/com/example/` or a specific `.java` file):

For a folder input, find all `.java` files under it:
```bash
rg --files --type java "<folder>"
```

### Step 2 — Verify SonarLint is available

```bash
SONARLINT_JAR="$HOME/.local/share/nvim/mason/packages/sonarlint-language-server/extension/server/sonarlint-ls.jar"
ANALYZERS_DIR="$HOME/.local/share/nvim/mason/packages/sonarlint-language-server/extension/analyzers"
test -f "$SONARLINT_JAR" && test -f "$ANALYZERS_DIR/sonarjava.jar"
```

If not available, inform the user:
> SonarLint is not installed. Install it via Mason in Neovim: `:MasonInstall sonarlint-language-server`

### Step 3 — Build file list and run scan

Build a pipe-separated absolute path list from the resolved files, then run:

```bash
node "$CLAUDE_PROJECT_DIR/.claude/hooks/sonarlint-scan.js" \
  "$SONARLINT_JAR" \
  "$ANALYZERS_DIR" \
  "$(git rev-parse --show-toplevel)" \
  "<pipe-separated-absolute-file-paths>"
```

Timeout: 60 seconds. The scan outputs JSON — parse it to display results.

### Step 4 — Report results

Parse the JSON output and display a structured report:

**Security issues** (`.security == true`) — shown first, highlighted as critical:
```
🔴 SECURITY — L{line} [{rule}]: {message}
   File: {file}
```

**Other issues** (`.security == false`) — grouped by severity:
```
🟡 {severity} — L{line} [{rule}]: {message}
   File: {file}
```

**If no issues found:**
```
✅ SonarLint: no issues found in {N} file(s) scanned.
```

**Summary line always shown:**
```
Scanned {N} file(s) — {sec} security issue(s), {other} other issue(s).
```

## Notes
- Security issues (CWE/OWASP-tagged rules) are always shown first and treated as critical
- The scan runs in an isolated `SONARLINT_USER_HOME` per-run — does not touch `~/.sonarlint/storage/h2/`
- Rule IDs like `S2095` (resource leak), `S2077` (SQL injection), `S2612` (file permissions) are common security rules
