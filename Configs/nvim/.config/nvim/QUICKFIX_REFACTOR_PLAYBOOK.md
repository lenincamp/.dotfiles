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

## High-Value Flows

### 1) Fast project-wide rename (safe-ish)

```vim
:grep '\<OldName\>' .
:copen
:cfdo %s/\<OldName\>/NewName/ge | update
```

Use `:cdo ...gc` for interactive confirmation.

### 2) Incremental query accumulation before one refactor pass

```vim
:grep '\<legacyFn\>' src
:grepadd '\<legacyUtil\>' src
:grepadd 'TODO.*migrate' src
:copen
:cfdo %s/\<legacyFn\>/newFn/ge | %s/\<legacyUtil\>/newUtil/ge | update
```

### 3) Window-scoped searches for parallel tasks

Window A:

```vim
:lgrep '\<AuthService\>' src/auth
:lopen
```

Window B:

```vim
:lgrep '\<PaymentService\>' src/payments
:lopen
```

Apply only to the current window list:

```vim
:lfdo %s/\<AuthService\>/IdentityService/ge | update
```

### 4) Macro-driven structural refactor from quickfix

1. Record macro in register `q`.
2. Run over each quickfix entry:

```vim
:cdo normal! @q | update
```

Per-file variant:

```vim
:cfdo normal! @q | update
```

### 5) No external dependency mode

```vim
:vimgrep /OldName/j **/*.lua
:copen
:cfdo %s/\<OldName\>/NewName/ge | update
```

Window-local:

```vim
:lvimgrep /OldName/j **/*.lua
:lopen
:lfdo %s/\<OldName\>/NewName/ge | update
```

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
