-- mini.clue: lightweight keymap hints popup (replaces which-key.nvim).
-- Groups are defined here centrally; individual keymap descs come from the keymap registration.

local ok, clue = pcall(require, "mini.clue")
if not ok then return end

clue.setup({
  triggers = {
    -- Leader (Space) — all <leader>* combos
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },
    -- Salesforce group trigger (capital S)
    { mode = "n", keys = "<Leader>S" },
    -- Local leader
    { mode = "n", keys = "<LocalLeader>" },
    { mode = "x", keys = "<LocalLeader>" },
    -- Built-in navigation / text objects
    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },
    { mode = "n", keys = "<C-w>" },
    -- Comment (built-in Neovim 0.10+)
    { mode = "n", keys = "gc" },
    { mode = "x", keys = "gc" },
    -- Peek preview stack
    { mode = "n", keys = "gp" },
    -- s-prefix motions (surround + flash)
    { mode = "n", keys = "s" },
    { mode = "x", keys = "s" },
    { mode = "o", keys = "s" },
  },

  clues = {
    -- Built-in submode generators
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),

    -- ── <leader> groups ────────────────────────────────────────────────────────

    -- AI (Avante + Copilot)
    { mode = "n", keys = "<Leader>a",      desc = "+AI" },
    { mode = "x", keys = "<Leader>a",      desc = "+AI" },
    { mode = "n", keys = "<Leader>a?",     desc = "Avante: models" },
    { mode = "n", keys = "<Leader>aa",     desc = "Avante: ask" },
    { mode = "x", keys = "<Leader>aa",     desc = "Avante: ask selection" },
    { mode = "n", keys = "<Leader>aB",     desc = "Avante: add open buffers" },
    { mode = "n", keys = "<Leader>aC",     desc = "Avante: clear" },
    { mode = "n", keys = "<Leader>ac",     desc = "Avante: add current file" },
    { mode = "n", keys = "<Leader>ae",     desc = "Avante: edit" },
    { mode = "x", keys = "<Leader>ae",     desc = "Avante: edit selection" },
    { mode = "n", keys = "<Leader>af",     desc = "Avante: focus" },
    { mode = "n", keys = "<Leader>ah",     desc = "Avante: history" },
    { mode = "n", keys = "<Leader>an",     desc = "Avante: new chat" },
    { mode = "n", keys = "<Leader>aP",     desc = "Avante: provider" },
    { mode = "n", keys = "<Leader>aR",     desc = "Avante: repo map" },
    { mode = "n", keys = "<Leader>ar",     desc = "Avante: refresh" },
    { mode = "n", keys = "<Leader>aS",     desc = "Avante: stop" },
    { mode = "n", keys = "<Leader>at",     desc = "Avante: toggle" },
    { mode = "n", keys = "<Leader>az",     desc = "Avante: zen mode" },

    -- Buffers
    { mode = "n", keys = "<Leader>b",      desc = "+Buffers" },

    -- Code / LSP
    { mode = "n", keys = "<Leader>c",      desc = "+Code" },
    { mode = "x", keys = "<Leader>c",      desc = "+Code" },

    -- Debug (DAP)
    { mode = "n", keys = "<Leader>d",      desc = "+Debug" },
    { mode = "x", keys = "<Leader>d",      desc = "+Debug" },
    { mode = "n", keys = "<Leader>db",     desc = "+Breakpoints" },
    { mode = "n", keys = "<Leader>dbs",    desc = "Breakpoints: Save" },
    { mode = "n", keys = "<Leader>dbL",    desc = "Breakpoints: Load" },
    { mode = "n", keys = "<Leader>dbg",    desc = "Breakpoints: Assign group" },
    { mode = "n", keys = "<Leader>dbp",    desc = "Breakpoints: Browse by group" },
    { mode = "n", keys = "<Leader>dL",     desc = "Debug: Logpoint" },
    { mode = "n", keys = "<Leader>dW",     desc = "Debug: Add Watch" },
    { mode = "x", keys = "<Leader>dW",     desc = "Debug: Add Watch from selection" },

    -- Explorer (separate from Files)
    { mode = "n", keys = "<Leader>e",      desc = "File Explorer (cwd)" },
    { mode = "n", keys = "<Leader>E",      desc = "File Explorer (root)" },

    -- Files + Terminal
    { mode = "n", keys = "<Leader>f",      desc = "+Files/Terminal" },
    { mode = "n", keys = "<Leader>fJ",     desc = "Find Java files (root)" },
    { mode = "n", keys = "<Leader>fj",     desc = "Find JS/TS files (cwd)" },
    { mode = "n", keys = "<Leader>fx",     desc = "Find React files (JSX/TSX, cwd)" },

    -- Git
    { mode = "n", keys = "<Leader>g",      desc = "+Git" },
    { mode = "x", keys = "<Leader>g",      desc = "+Git" },

    -- Java
    { mode = "n", keys = "<Leader>J",      desc = "+Java" },
    { mode = "n", keys = "<Leader>JI",     desc = "Java: Invert condition" },
    { mode = "n", keys = "<Leader>Je",     desc = "+Escape/Extract" },
    { mode = "x", keys = "<Leader>Je",     desc = "+Escape/Extract" },
    { mode = "n", keys = "<Leader>Jt",     desc = "+Tools/Spring" },
    { mode = "n", keys = "<Leader>Jtr",    desc = "Spring: Run project" },
    { mode = "n", keys = "<Leader>Jtc",    desc = "Spring: Create class" },
    { mode = "n", keys = "<Leader>Jtn",    desc = "Spring: Create interface" },
    { mode = "n", keys = "<Leader>Jte",    desc = "Spring: Create enum" },
    { mode = "n", keys = "<Leader>Jti",    desc = "JDTLS: Organize imports" },
    { mode = "n", keys = "<Leader>Jtv",    desc = "JDTLS: Extract variable" },
    { mode = "n", keys = "<Leader>Jtm",    desc = "JDTLS: Extract method" },
    { mode = "n", keys = "<Leader>Jtu",    desc = "JDTLS: Update config" },
    { mode = "n", keys = "<Leader>Jtw",    desc = "JDTLS: Clean workspace" },
    { mode = "x", keys = "<Leader>J",      desc = "+Java" },

    -- Project / Sessions
    { mode = "n", keys = "<Leader>p",      desc = "+Project/Sessions" },
    { mode = "n", keys = "<Leader>ps",     desc = "Session: Save" },
    { mode = "n", keys = "<Leader>pl",     desc = "Session: Load (cwd)" },
    { mode = "n", keys = "<Leader>pS",     desc = "Session: Select" },
    { mode = "n", keys = "<Leader>pd",     desc = "Session: Stop recording" },
    { mode = "n", keys = "<Leader>pH",     desc = "Open Quickfix Playbook" },

    -- Quit
    { mode = "n", keys = "<Leader>q",      desc = "+Quit" },
    { mode = "n", keys = "<Leader>qq",     desc = "Quit all" },

    -- Utility (redraw, diff mode)
    { mode = "n", keys = "<Leader>ur",     desc = "Redraw / clear search" },
    { mode = "n", keys = "<Leader>ue",     desc = "Toggle diff mode" },
    { mode = "n", keys = "<Leader>gC",     desc = "Git Compare-Load (branch -> worktree)" },

    -- Replace / Refactor
    { mode = "n", keys = "<Leader>r",      desc = "+Refactor" },
    { mode = "x", keys = "<Leader>r",      desc = "+Refactor" },

    -- Search
    { mode = "n", keys = "<Leader>s",      desc = "+Search" },
    { mode = "x", keys = "<Leader>s",      desc = "+Search" },
    { mode = "n", keys = "<Leader>/",      desc = "Fast search in current file (rg)" },
    { mode = "n", keys = "<Leader>sg",     desc = "Grep literal (cwd)" },
    { mode = "n", keys = "<Leader>sG",     desc = "Grep literal (root)" },
    { mode = "n", keys = "<Leader>s/",     desc = "Grep regex (root)" },
    { mode = "n", keys = "<Leader>sj",     desc = "Search JS/TS text" },
    { mode = "n", keys = "<Leader>sx",     desc = "Search JSX/TSX text (cwd)" },
    { mode = "n", keys = "<Leader>sJ",     desc = "Search Java text" },
    { mode = "n", keys = "<Leader>sS",     desc = "LSP Symbols (workspace)" },
    { mode = "n", keys = "<Leader>sX",     desc = "Search React components (JSX/TSX)" },

    -- Tests (all languages)
    { mode = "n", keys = "<Leader>t",      desc = "+Tests" },
    { mode = "n", keys = "<Leader>tn",     desc = "Test: nearest (auto)" },
    { mode = "n", keys = "<Leader>tf",     desc = "Test: file (auto)" },
    { mode = "n", keys = "<Leader>tw",     desc = "Test: watch (JS)" },
    { mode = "n", keys = "<Leader>tl",     desc = "Test: run last" },
    { mode = "n", keys = "<Leader>ta",     desc = "Test: Apex method" },
    { mode = "n", keys = "<Leader>tA",     desc = "Test: Apex class" },
    { mode = "n", keys = "<Leader>tt",     desc = "+Java/Maven tests" },
    { mode = "n", keys = "<Leader>td",     desc = "+Java/Maven debug" },

    -- Salesforce (S = Salesforce, like J = Java)
    { mode = "n", keys = "<Leader>S",      desc = "+Salesforce options" },
    { mode = "n", keys = "<Leader>Sx",     desc = "SF: Execute anonymous Apex" },
    { mode = "n", keys = "<Leader>Sp",     desc = "SF: Push to org" },
    { mode = "n", keys = "<Leader>Sr",     desc = "SF: Retrieve from org" },
    { mode = "n", keys = "<Leader>Sd",     desc = "SF: Diff with org" },
    { mode = "n", keys = "<Leader>So",     desc = "SF: Set default org" },
    { mode = "n", keys = "<Leader>Si",     desc = "SF: Refresh org info" },
    { mode = "n", keys = "<Leader>Sl",     desc = "SF: Tail debug log" },
    { mode = "n", keys = "<Leader>SL",     desc = "SF: Toggle log file debug" },
    { mode = "n", keys = "<Leader>Sc",     desc = "SF: Create LWC component" },
    { mode = "n", keys = "<Leader>Sa",     desc = "SF: Create Apex class" },

    -- UI toggles
    { mode = "n", keys = "<Leader>u",      desc = "+UI" },
    { mode = "n", keys = "<Leader>uh",     desc = "Toggle Inlay Hints" },
    { mode = "n", keys = "<Leader>uz",     desc = "Toggle Zen Mode" },
    { mode = "n", keys = "<Leader>uzn",    desc = "Cycle Zen Width (110/120/130)" },
    { mode = "n", keys = "<Leader>uZ",     desc = "Toggle Zoom Mode" },
    { mode = "n", keys = "<Leader>uX",     desc = "Toggle Treesitter Context" },
    { mode = "n", keys = "<Leader>um",     desc = "Cycle Tabline Mode" },
    { mode = "n", keys = "<Leader>uM",     desc = "Toggle Render Markdown" },
    { mode = "n", keys = "<Leader>us",     desc = "Toggle Statusline" },
    { mode = "n", keys = "<Leader>ut",     desc = "Toggle Tabline" },
    { mode = "n", keys = "<Leader>uW",     desc = "Toggle Winbar" },
    { mode = "n", keys = "<Leader>uC",     desc = "Colorscheme Picker" },
    { mode = "n", keys = "<Leader>uS",     desc = "Toggle SonarLint" },
    { mode = "n", keys = "<Leader>uA",     desc = "Toggle Transparent Background" },
    { mode = "n", keys = "<Leader>ub",     desc = "Toggle Dark Background" },
    { mode = "n", keys = "<Leader>ud",     desc = "Toggle Diagnostics" },
    { mode = "n", keys = "<Leader>uD",     desc = "Toggle Dim" },
    { mode = "n", keys = "<Leader>uF",     desc = "Toggle Format on Save (global)" },
    { mode = "n", keys = "<Leader>uf",     desc = "Toggle Format on Save (buffer)" },
    { mode = "n", keys = "<Leader>uo",     desc = "Toggle Spelling" },
    { mode = "n", keys = "<Leader>ug",     desc = "Toggle Grep Layout (IntelliJ)" },
    { mode = "n", keys = "<Leader>ui",     desc = "Toggle Cmdline Info (ruler/showcmd)" },
    { mode = "n", keys = "<Leader>uI",     desc = "Toggle IndentScope" },
    { mode = "n", keys = "<Leader>ul",     desc = "Toggle Line Number" },
    { mode = "n", keys = "<Leader>uL",     desc = "Toggle Relative Number" },
    { mode = "n", keys = "<Leader>uR",     desc = "Toggle Diff Profile" },
    { mode = "n", keys = "<Leader>uT",     desc = "Toggle Treesitter" },
    { mode = "n", keys = "<Leader>uq",     desc = "Toggle LSP in diff buffer" },
    { mode = "n", keys = "<Leader>uw",     desc = "Toggle Wrap" },

    -- Windows
    { mode = "n", keys = "<Leader>w",      desc = "+Windows" },

    -- Lists (quickfix / loclist)
    { mode = "n", keys = "<Leader>x",      desc = "+Lists" },

    -- Tabs
    { mode = "n", keys = "<Leader><Tab>",  desc = "+Tabs" },

    -- Comment subgroup (gc is the group prefix for comment keymaps)
    { mode = "n", keys = "gc",             desc = "+Comment" },
    { mode = "n", keys = "gcc",            desc = "Toggle line comment" },
    { mode = "x", keys = "gc",             desc = "Toggle selection comment" },
    { mode = "n", keys = "gco",            desc = "Add comment below" },
    { mode = "n", keys = "gcO",            desc = "Add comment above" },

    -- [ / ] navigation clues
    { mode = "n", keys = "[X",             desc = "Jump to context start" },
    { mode = "n", keys = "[h",             desc = "Prev git hunk" },
    { mode = "n", keys = "]h",             desc = "Next git hunk" },
    { mode = "n", keys = "[t",             desc = "Prev TODO" },
    { mode = "n", keys = "]t",             desc = "Next TODO" },
    { mode = "n", keys = "[d",             desc = "Prev diagnostic" },
    { mode = "n", keys = "]d",             desc = "Next diagnostic" },
    { mode = "n", keys = "[b",             desc = "Prev buffer" },
    { mode = "n", keys = "]b",             desc = "Next buffer" },
    { mode = "n", keys = "[q",             desc = "Prev quickfix" },
    { mode = "n", keys = "]q",             desc = "Next quickfix" },
    -- treesitter-textobjects navigation
    { mode = "n", keys = "[f",             desc = "Prev function start" },
    { mode = "n", keys = "]f",             desc = "Next function start" },
    { mode = "n", keys = "[F",             desc = "Prev function end" },
    { mode = "n", keys = "]F",             desc = "Next function end" },
    { mode = "n", keys = "[c",             desc = "Prev class start" },
    { mode = "n", keys = "]c",             desc = "Next class start" },
    { mode = "n", keys = "[a",             desc = "Prev parameter" },
    { mode = "n", keys = "]a",             desc = "Next parameter" },

    -- gp Quick Preview subgroup
    { mode = "n", keys = "gp",             desc = "+Quick Preview" },
    { mode = "n", keys = "gpd",            desc = "Quick Preview: definition" },
    { mode = "n", keys = "gpt",            desc = "Quick Preview: type definition" },
    { mode = "n", keys = "gpi",            desc = "Quick Preview: implementation" },
    { mode = "n", keys = "gpD",            desc = "Quick Preview: declaration" },
    { mode = "n", keys = "gpr",            desc = "Quick Preview: references (picker)" },
    { mode = "n", keys = "gpc",            desc = "Quick Preview: close all" },

    -- g LSP navigation/actions (standard)
    { mode = "n", keys = "gd",             desc = "Go to definition" },
    { mode = "n", keys = "gD",             desc = "Go to declaration" },
    { mode = "n", keys = "gy",             desc = "Go to type definition" },
    { mode = "n", keys = "gV",             desc = "Vsplit and go to definition" },
    { mode = "n", keys = "gr",             desc = "+LSP actions" },
    { mode = "x", keys = "gr",             desc = "+LSP actions" },
    { mode = "n", keys = "gra",            desc = "Code action" },
    { mode = "x", keys = "gra",            desc = "Code action" },
    { mode = "n", keys = "grn",            desc = "Rename symbol" },
    { mode = "n", keys = "grr",            desc = "References (picker)" },
    { mode = "n", keys = "gri",            desc = "Go to implementation" },
    { mode = "n", keys = "gO",             desc = "Document symbols" },
    { mode = "n", keys = "gW",             desc = "Workspace symbols" },
    { mode = "n", keys = "gK",             desc = "Signature help" },

    -- s Surround (standard) + Flash
    { mode = "n", keys = "s",              desc = "+Surround/Flash" },
    { mode = "x", keys = "s",              desc = "+Surround/Flash" },
    { mode = "o", keys = "s",              desc = "+Surround/Flash" },
    { mode = "n", keys = "sa",             desc = "Surround: add" },
    { mode = "x", keys = "sa",             desc = "Surround: add (selection)" },
    { mode = "n", keys = "sd",             desc = "Surround: delete" },
    { mode = "n", keys = "sr",             desc = "Surround: replace" },
    { mode = "n", keys = "sf",             desc = "Surround: find →" },
    { mode = "n", keys = "sF",             desc = "Surround: find ←" },
    { mode = "n", keys = "sh",             desc = "Surround: highlight" },
    { mode = "n", keys = "sn",             desc = "Surround: update n_lines" },
    { mode = "n", keys = "ss",             desc = "Flash jump" },
    { mode = "x", keys = "ss",             desc = "Flash jump" },
    { mode = "o", keys = "ss",             desc = "Flash jump" },
    { mode = "n", keys = "sS",             desc = "Flash Treesitter" },
    { mode = "o", keys = "sS",             desc = "Flash Treesitter" },

    -- [ / ] reference navigation (Snacks.words)
    { mode = "n", keys = "]]",             desc = "Next reference" },
    { mode = "n", keys = "[[",             desc = "Prev reference" },

    -- <leader>c additions
    { mode = "n", keys = "<Leader>cN",     desc = "Rename file" },
  },

  window = {
    delay       = 300,        -- ms before popup appears
    config      = { border = "rounded", width = "auto" },
    scroll_down = "<C-d>",
    scroll_up   = "<C-u>",
  },
})

-- Toggle mini.indentscope globally. When re-enabled the per-buffer autocmd
-- (in mini-indentscope.lua) will re-evaluate on the next BufWinEnter/FileType.
vim.keymap.set("n", "<Leader>uI", function()
  vim.g.miniindentscope_disable = not vim.g.miniindentscope_disable
  local state = vim.g.miniindentscope_disable and "disabled" or "enabled"
  vim.notify("IndentScope " .. state, vim.log.levels.INFO)
end, { desc = "Toggle IndentScope" })
