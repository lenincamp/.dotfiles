# Quickfix Refactor Playbook

Guía rápida para refactors en proyectos grandes con herramientas **nativas de Neovim** + picker/quickfix de esta config.

Abrir: `<leader>pH` · Command Center → *Open quickfix* / picker lists

---

## Flujo recomendado

1. **Buscar** — grep o picker → lista de matches
2. **Revisar** — quickfix / location list, saltar match a match
3. **Cambiar** — `:s`, LSP rename, o `:cdo`/`:cfdo` en lote
4. **Validar** — tests (`<leader>tn` / `tf`), `:make`, `:grep` de nuevo

Regla: prefiere **cambios pequeños y revisables** antes que un `:cdo` masivo sin preview.

---

## 1. Sustitución en buffer (`:s`)

| Comando | Uso |
|---------|-----|
| `:s/old/new/` | Primera ocurrencia en la línea |
| `:s/old/new/g` | Todas en la línea |
| `:%s/old/new/g` | Todo el buffer |
| `:%s/old/new/gc` | Con confirmación (recomendado en refactors) |
| `:5,20s/old/new/g` | Rango de líneas |
| `:s/\vfoo(bar)/\1/g` | Regex very magic (`\v`) |

Atajos de esta config:

| Key | Acción |
|-----|--------|
| `<leader>rr` (normal) | Sustituir palabra bajo cursor en todo el archivo |
| `<leader>rr` (visual) | Sustituir selección en todo el archivo |

Tips:

- `\V` en patterns = literal (sin regex): `:%s/\Vold.name/new.name/gc`
- Escapar `/` en paths: `:s#com/old#com/new#g`
- Deshacer por buffer: `u` · revisar con `:undolist`

---

## 2. Grep de proyecto → quickfix

### Picker (rg, cwd/root)

| Key | Acción |
|-----|--------|
| `<leader>sg` | Grep regex (cwd) |
| `<leader>sG` | Grep regex (root) |
| `<leader>s/` | Grep regex root (alias) |
| `<leader>sw` | Palabra bajo cursor (cwd) |
| `<leader>sW` | Palabra bajo cursor (root) |
| `<leader>si` / `sI` | Grep ignored literal |
| `<leader>/` | Buscar en buffer actual (rg) |
| `<leader>sr` | Reanudar última búsqueda picker |

### Vim nativo (cuando no quieres picker)

```vim
" Desde el root del repo (ajusta path)
:grep -R --line-number --fixed-strings 'OldClassName' src/

" Solo ciertos tipos
:grep -R --include='*.java' 'import com.old' .

" Regex multilínea (vimgrep + very magic)
:vimgrep /\vclass\s+\zsOldName/ %:p:h/**
```

`grepprg` usa ripgrep si está instalado. Los resultados van al **quickfix**.

---

## 3. Navegar quickfix / location list

| Key / cmd | Acción |
|-----------|--------|
| `<leader>xq` | Toggle quickfix window |
| `<leader>xl` | Toggle location list |
| `<leader>sq` | Picker: quickfix list |
| `<leader>sl` | Picker: location list |
| `:copen` / `:cclose` | Abrir/cerrar quickfix |
| `:cnext` / `:cprev` | Siguiente / anterior |
| `]q` / `[q` | Siguiente / anterior (si mapeado) |
| `<Enter>` en qf | Ir al match |
| `:cdo cmd` | Ejecutar `cmd` en **cada** entrada qf |
| `:cfdo cmd` | Como `:cdo` pero solo en archivos únicos |
| `:cfdo update` | Guardar todos los buffers tocados |

Ejemplos `:cfdo`:

```vim
" Abrir cada match en split y pausar (manual)
:cfdo tab split

" Sustituir en cada archivo del quickfix (¡revisar antes!)
:cfdo %s/\VOldApi/NewApi/ge | update

" Solo ver cuántos archivos
:cfdo echo expand('%:p')
```

**Seguro:** usa `:cfdo` con `:s/.../gc` archivo por archivo, o un script, no `:cdo` a ciegas en 200 archivos.

---

## 4. Palabra / referencias en buffer

| Key | Acción |
|-----|--------|
| `*` / `#` | Buscar palabra (con highlight) |
| `n` / `N` | Siguiente / anterior match |
| `]]` / `[[` | Siguiente / anterior referencia de palabra |
| `<Esc>` / `<leader>ur` | Limpiar highlights |

LSP (nativo + lsp-nav):

| Key | Acción |
|-----|--------|
| `gd` | Definition |
| `grr` | References → picker |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `<leader>ss` / `sS` | Symbols doc / workspace (picker) |
| `grn` | Rename symbol (preferir en refactors semánticos) |

---

## 5. Refactor por archivo / selección

| Key | Acción |
|-----|--------|
| `gra` | LSP code action (menú) |
| `<leader>rx` | Extract variable (visual) |
| `<leader>rf` | Extract function (visual) |
| `<leader>ri` | Inline variable |
| `<leader>ro` | Organize imports |
| `<leader>cf` | Format buffer |
| `<leader>cN` | Rename file (+ LSP willRename si aplica) |

Cuándo usar qué:

- **Rename simbolo** (`grn`) → mismo identificador, mismo tipo, LSP-aware
- **`:s` / `<leader>rr`** → strings, logs, configs, nombres que LSP no ve
- **grep + cfdo** → migraciones masivas de API/texto

---

## 6. Diff y revisión

| Key | Acción |
|-----|--------|
| `<leader>ue` | Toggle diff mode |
| `<leader>uR` | Toggle diff profile |
| `<leader>gC` | Git compare contextual |
| `<leader>cB` | Buffer vs clipboard diff |
| `]c` / `[c` | Siguiente / anterior cambio (en diff) |
| `do` / `dp` | Obtener / poner cambio diff |

Antes de commit grande: `:vert diffsplit` con rama base o `git difftool` vía compare.

---

## 7. Listas y buffers durante refactor

| Key | Acción |
|-----|--------|
| `<leader>ff` / `fF` | Find files cwd/root |
| `<leader>fg` | Git files |
| `<leader>fR` | Recent files |
| `<leader>bd` | Delete buffer (picker) |
| `<leader>bo` | Delete other buffers |
| `<leader>bb` | Alternate buffer |
| `:bufdo` | Comando en todos los buffers cargados |

```vim
" Guardar solo buffers modificados del quickfix
:cfdo update

" Cerrar buffers sin cambios después del refactor
:bufdo silent! bd
```

---

## 8. Recetas frecuentes

### Renombrar string literal en muchos archivos

1. `<leader>sG` → pattern literal
2. Revisar lista en quickfix (`<leader>xq`)
3. `:cfdo %s/\VoldValue/newValue/ge | update`
4. `:grep` de nuevo para verificar cero matches

### Migrar import / package (Java)

1. `<leader>sW` sobre el import viejo
2. Editar manualmente o `grn` si es tipo
3. `<leader>ro` organize imports por archivo
4. `<leader>tf` / Maven test en módulo

### Buscar TODO/FIXME antes de release

1. `<leader>st` o `<leader>sT` (picker todos)
2. Quickfix → resolver uno a uno

### Refactor solo en archivos abiertos

```vim
:bufdo %s/\Vfoo/bar/ge | update
```

---

## 9. Checklist post-refactor

- [ ] `:grep` o picker confirma cero ocurrencias del pattern viejo
- [ ] Tests: `<leader>tn` / `tf` / `tw` (watch)
- [ ] LSP sin diagnostics nuevos (`<leader>ud` si las ocultaste)
- [ ] `:cfdo update` guardó todo lo esperado
- [ ] `git diff --stat` tamaño razonable

---

## Referencia rápida de keys (esta config)

```
Search:  sg sG sw sW s/ si sr    Lists: xq xl sq sl
Replace: rr (n/v)                  LSP:   gra grn gd grr
Files:   ff fF fg fR               Diff:  ue uR gC cB
Open:    pH (este doc)             UI:    <space> (Command Center)
```
