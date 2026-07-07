# Quickfix Refactor Playbook

Guía rápida para refactors con herramientas **nativas de Neovim** + quickfix.

Abrir: `<leader>pH` · Command Center (`<leader><space>`)

---

## Flujo recomendado

1. **Buscar** — `:Rg` o grep → quickfix
2. **Revisar** — quickfix / location list, saltar match a match
3. **Cambiar** — `:s`, LSP rename, o `:cdo`/`:cfdo` en lote
4. **Validar** — tests (`<leader>tn` / `tf`), `:make`, `:Rg` de nuevo

Regla: prefiere **cambios pequeños y revisables** antes que un `:cdo` masivo.

---

## 1. Sustitución en buffer (`:s`)

| Comando | Uso |
|---------|-----|
| `:s/old/new/` | Primera ocurrencia en la línea |
| `:s/old/new/g` | Todas en la línea |
| `:%s/old/new/g` | Todo el buffer |
| `:%s/old/new/gc` | Con confirmación (recomendado) |
| `:5,20s/old/new/g` | Rango de líneas |
| `:s/\vfoo(bar)/\1/g` | Regex very magic (`\v`) |

Atajos:

| Key | Acción |
|-----|--------|
| `<leader>rr` (normal) | Sustituir palabra bajo cursor |
| `<leader>rr` (visual) | Sustituir selección |

Tips:
- `\V` = literal: `:%s/\Vold.name/new.name/gc`
- Escapar `/`: `:s#com/old#com/new#g`
- Deshacer: `u` · `:undolist`

---

## 2. Grep → quickfix

| Key | Acción |
|-----|--------|
| `<leader>sg` | Grep (cwd) — input |
| `<leader>sG` | Grep (root) — input |
| `<leader>s/` | Grep literal (root) — input |
| `<leader>sw` | Palabra bajo cursor (cwd) |
| `<leader>sW` | Palabra bajo cursor (root) |
| `<leader>si` / `sI` | Grep ignored (cwd/root) |
| `<leader>/` | Buscar en buffer actual |
| `<leader>sr` | Reanudar última búsqueda |

También disponible: `:Rg` (input → quickfix, ya existía)

### Vim nativo adicional

```vim
:vimgrep /\vclass\s+\zsOldName/ %:p:h/**
:grep -R --include='*.java' 'import com.old' .
```

---

## 3. Navegar quickfix / location list

| Key / cmd | Acción |
|-----------|--------|
| `]q` / `[q` | Siguiente / anterior quickfix |
| `<leader>xq` | Toggle quickfix window |
| `<leader>xl` | Toggle location list |
| `<leader>sq` | Buscar en quickfix (vim.ui.select) |
| `<leader>sl` | Buscar en location list |
| `:copen` / `:cclose` | Abrir/cerrar quickfix |
| `:cnext` / `:cprev` | Siguiente / anterior |
| `<Enter>` en qf | Ir al match |
| `:cdo cmd` | Ejecutar `cmd` en **cada** entrada qf |
| `:cfdo cmd` | Como `:cdo` pero solo archivos únicos |
| `:cfdo update` | Guardar todos los buffers tocados |

Ejemplos `:cfdo`:

```vim
" Sustituir en cada archivo del quickfix
:cfdo %s/\VOldApi/NewApi/ge | update

" Solo ver archivos
:cfdo echo expand('%:p')
```

**Seguro:** usa `:cfdo` con `:s/.../gc` archivo por archivo.

---

## 4. Palabra / referencias en buffer

| Key | Acción |
|-----|--------|
| `*` / `#` | Buscar palabra (con highlight) |
| `n` / `N` | Siguiente / anterior match |
| `]]` / `[[` | Siguiente / anterior referencia |
| `<Esc>` / `<leader>ur` | Limpiar highlights |

LSP:

| Key | Acción |
|-----|--------|
| `gd` | Definition |
| `gra` | Code action |
| `grn` | Rename symbol |
| `<leader>sd` / `sD` | Diagnostics (buffer/workspace) |
| `<leader>sk` | Keymaps |

---

## 5. Refactor por archivo / selección

| Key | Acción |
|-----|--------|
| `gra` | LSP code action |
| `<leader>rx` | Extract variable (visual) |
| `<leader>rf` | Extract function (visual) |
| `<leader>ri` | Inline variable |
| `<leader>ro` | Organize imports |
| `<leader>cf` | Format buffer |
| `<leader>cN` | Rename file (+ LSP willRename) |

Cuándo usar qué:
- **Rename símbolo** (`grn`) → mismo identificador, LSP-aware
- **`:s` / `<leader>rr`** → strings, logs, configs
- **grep + cfdo** → migraciones masivas

---

## 6. Diff y revisión

| Key | Acción |
|-----|--------|
| `<leader>ue` | Toggle diff mode |
| `<leader>uR` | Toggle diff profile |
| `<leader>gC` | Git compare contextual |
| `<leader>cB` | Buffer vs clipboard diff |
| `]c` / `[c` | Siguiente / anterior cambio |
| `do` / `dp` | Obtener / poner cambio |

---

## 7. Git integrations

| Key | Acción |
|-----|--------|
| `<leader>gl` | Git log (cwd) → quickfix |
| `<leader>gL` | Git log (root) → quickfix |
| `<leader>gf` | Git file history → quickfix |
| `<leader>gb` | Git blame line (notification) |
| `<leader>gB` | Git browse (open in browser) |
| `<leader>gY` | Git browse (copy URL) |
| `<leader>gg` / `gG` | Lazygit (cwd/root) |

---

## 8. Files & Buffers

| Key | Acción |
|-----|--------|
| `<leader>ff` / `fF` | Find files (cwd/root) → quickfix |
| `<leader>fg` | Git tracked files → quickfix |
| `<leader>fR` | Recent files → quickfix |
| `<leader>bd` | Delete buffer |
| `<leader>bo` | Delete other buffers |
| `<leader>bb` | Alternate buffer |

---

## 9. Recetas frecuentes

### Renombrar string literal en muchos archivos

1. `<leader>sG` → pattern literal
2. Revisar quickfix (`]q`/`[q`)
3. `:cfdo %s/\VoldValue/newValue/ge | update`
4. `:Rg` de nuevo para verificar

### Migrar import / package (Java)

1. `<leader>sW` sobre el import viejo
2. Editar o `grn`
3. `<leader>ro` organize imports
4. `<leader>tf` / Maven test

### Buscar TODO/FIXME antes de release

1. `:Rg TODO` o `:Rg FIXME`
2. Quickfix → resolver uno a uno

### Refactor solo en archivos abiertos

```vim
:bufdo %s/\Vfoo/bar/ge | update
```

---

## 10. Checklist post-refactor

- [ ] `:Rg` confirma cero ocurrencias del pattern viejo
- [ ] Tests: `<leader>tn` / `tf` / `tw`
- [ ] LSP sin diagnostics nuevos (`<leader>ud`)
- [ ] `:cfdo update` guardó todo
- [ ] `git diff --stat` tamaño razonable

---

## Referencia rápida

```
Search:  sg sG sw sW s/ si / sr     Git:     gl gL gf gb gB gY gg gG
Replace: rr (n/v)                    Lists:   xq xl sq sl
Files:   ff fF fg fR fn fc           Diff:    ue uR gC cB
Buffers: bd bo bb                    UI:      <space> (Command Center)
Open:    pH (este doc)               Nav:     ]q [q
```
