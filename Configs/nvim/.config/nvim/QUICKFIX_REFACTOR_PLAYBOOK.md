# Quickfix and Location List Playbook (Neovim 0.12)

Advanced search, refactor, and merge-safe workflows using `grep`, `vimgrep`, quickfix, and location list.

## Search Engines

- `grep` / `lgrep`: external engine from `grepprg` (recommended: `rg --vimgrep`)
- `vimgrep` / `lvimgrep`: builtin Vim regex engine

## Result Destinations

- quickfix (global): `grep`, `grepadd`, `vimgrep`, `vimgrepadd`
- location list (window-local): `lgrep`, `lgrepadd`, `lvimgrep`, `lvimgrepadd`

## Baseline Setup

```vim
:set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --glob\ !.git
:set grepformat=%f:%l:%c:%m
```

## Top 10 Recipes (Priority Order)

Ordered by practical value for day-to-day programming: safest/highest ROI first, riskier or more advanced workflows later.

### 1) Safe symbol rename across project (review first)

```vim
:grep '\<AuthService\>' src/
:copen
:cdo s/\<AuthService\>/IdentityService/gc | update
```

Use when you need human confirmation on each hit.

### 2) Fast batch rename per file (large codebases)

```vim
:grep '\<legacyFn\>' src/
:copen
:cfdo %s/\<legacyFn\>/newFn/ge | update
```

Use when pattern quality is high and you want speed.

### 3) Multi-pattern migration in one pass

```vim
:grep '\<legacyFn\>' src/
:grepadd '\<legacyUtil\>' src/
:grepadd '\<LegacyDTO\>' src/
:copen
:cfdo %s/\<legacyFn\>/newFn/ge | %s/\<legacyUtil\>/newUtil/ge | %s/\<LegacyDTO\>/ModernDTO/ge | update
```

Use for coordinated API migrations.

### 4) Refactor by module with window-local lists

Window A (auth):

```vim
:lgrep '\<AuthService\>' src/auth
:lopen
:lfdo %s/\<AuthService\>/IdentityService/ge | update
```

Window B (payments):

```vim
:lgrep '\<PaymentService\>' src/payments
:lopen
```

Use when handling parallel tracks without polluting global quickfix.

### 5) Remove debug logs safely

```vim
:grep 'console\.log\|print\s*(' src/
:copen
:cdo s/^\s*\(console\.log\|print\s*(\).*$//gc | update
```

Use interactive mode to avoid deleting valid runtime logging.

### 6) Update import paths after package move (TS/JS)

```vim
:grep "from '@old/core'" src/
:copen
:cfdo %s/from '@old\/core'/from '@platform\/core'/ge | update
```

Use when internal package namespaces change.

### 7) Java package/class migration

```vim
:grep '^import com\.legacy\.billing\.' src/
:copen
:cfdo %s/com\.legacy\.billing/com\.platform\.billing/ge | update
```

Use for consistent package-prefix migrations.

### 8) Vim regex precision (`vimgrep` + `\zs`/`\ze`)

```vim
:vimgrep /class\s\+\zs\k\+\ze/j **/*.java
:copen
```

Use when you need precise captures with Vim-native regex atoms.

### 9) Macro-driven structural edits from quickfix

1. Record macro in register `q` for the structural change.
2. Execute over matches:

```vim
:cdo normal! @q | update
```

Per-file variant:

```vim
:cfdo normal! @q | update
```

Use for edits that are hard to express as a substitution.

### 10) Merge-conflict cleanup sweep

```vim
:vimgrep /\v^(<<<<<<<|=======|>>>>>>>)/j **/*
:copen
```

Use before commits to prevent conflict markers from slipping in.

## Quickfix Power Commands

- Open/close list: `:copen`, `:cclose`
- Navigate: `:cnext`, `:cprev`, `:cfirst`, `:clast`
- Show entries: `:clist`
- Per-entry action: `:cdo {cmd}`
- Per-file action: `:cfdo {cmd}`
- Read/manipulate list in Lua: `vim.fn.getqflist()` / `vim.fn.setqflist()`

Location equivalents: `:lopen`, `:lclose`, `:lnext`, `:lprev`, `:llist`, `:ldo`, `:lfdo`.

## Patterns That Prevent Bad Refactors

- Whole-word boundaries for symbol rename: `\<name\>`
- Use `gc` when risk is medium/high
- Use `ge` in batch mode to avoid breaking on no-match files
- Prefer `cfdo`/`lfdo` for large codebases (faster, less buffer churn)

## Suggested Sequence for Large Refactors

1. Build candidate list (`grep`/`vimgrep`)
2. Review list (`:copen`, `:clist`)
3. Narrow/focus with better pattern
4. Execute with `:cfdo` or `:cdo`
5. Save (`update`), then run tests/lint
