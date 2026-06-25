-- Keymaps: pure keymap bindings

local keymap_specs = require("modules.editor.keymap_specs")

require("modules.editor.todos")

-- ── Spec-driven motion/search/editing ───────────────────────────────────────

keymap_specs.apply(keymap_specs.motion_edit_specs())

-- ── Spec-driven LSP/peek/refactor/clipboard ─────────────────────────────────

keymap_specs.apply(keymap_specs.code_lsp_specs())

-- ── Spec-driven windows/lists/tabs ───────────────────────────────────────────

keymap_specs.apply(keymap_specs.window_list_tab_specs())

-- ── Spec-driven UI/project/window utilities ──────────────────────────────────

keymap_specs.apply(keymap_specs.global_specs())

-- ── Explorer / personal git / buffer shortcuts (picker keymaps in picker.setup) ──

keymap_specs.apply(keymap_specs.search_specs())
