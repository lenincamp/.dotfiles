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
    -- Surround (mini.surround, gz prefix)
    { mode = "n", keys = "gz" },
    { mode = "x", keys = "gz" },
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

    -- AI (Sidekick + CopilotChat)
    { mode = "n", keys = "<Leader>a",      desc = "+AI" },
    { mode = "x", keys = "<Leader>a",      desc = "+AI" },

    -- Buffers
    { mode = "n", keys = "<Leader>b",      desc = "+Buffers" },

    -- Code / LSP
    { mode = "n", keys = "<Leader>c",      desc = "+Code" },
    { mode = "x", keys = "<Leader>c",      desc = "+Code" },

    -- Debug (DAP)  —  description changes to "+Diff" in diff buffers via buffer clue
    { mode = "n", keys = "<Leader>d",      desc = "+Debug" },
    { mode = "n", keys = "<Leader>db",     desc = "+Breakpoints" },
    { mode = "n", keys = "<Leader>dbs",    desc = "Breakpoints: Save" },
    { mode = "n", keys = "<Leader>dbL",    desc = "Breakpoints: Load" },
    { mode = "n", keys = "<Leader>dbg",    desc = "Breakpoints: Assign group" },
    { mode = "n", keys = "<Leader>dbp",    desc = "Breakpoints: Browse by group" },
    { mode = "n", keys = "<Leader>dL",     desc = "Debug: Logpoint" },

    -- Explorer (separate from Files)
    { mode = "n", keys = "<Leader>e",      desc = "File Explorer (root)" },
    { mode = "n", keys = "<Leader>E",      desc = "File Explorer (cwd)" },

    -- Files + Terminal
    { mode = "n", keys = "<Leader>f",      desc = "+Files/Terminal" },
    { mode = "n", keys = "<Leader>fj",     desc = "Find Java files" },
    { mode = "n", keys = "<Leader>fx",     desc = "Find React files (JSX/TSX)" },

    -- Git
    { mode = "n", keys = "<Leader>g",      desc = "+Git" },
    { mode = "x", keys = "<Leader>g",      desc = "+Git" },

    -- Java
    { mode = "n", keys = "<Leader>J",      desc = "+Java" },
    { mode = "n", keys = "<Leader>Ji",     desc = "Java: Organize imports" },
    { mode = "n", keys = "<Leader>Jv",     desc = "Java: Extract variable" },
    { mode = "n", keys = "<Leader>Jm",     desc = "Java: Extract method" },
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

    -- Quit
    { mode = "n", keys = "<Leader>q",      desc = "+Quit" },
    { mode = "n", keys = "<Leader>qq",     desc = "Quit all" },

    -- Utility (redraw, diff mode)
    { mode = "n", keys = "<Leader>ur",     desc = "Redraw / clear search" },
    { mode = "n", keys = "<Leader>ue",     desc = "Enable diff mode" },
    { mode = "n", keys = "<Leader>uE",     desc = "Disable diff mode" },

    -- Replace / Refactor
    { mode = "n", keys = "<Leader>r",      desc = "+Refactor" },
    { mode = "x", keys = "<Leader>r",      desc = "+Refactor" },

    -- Search
    { mode = "n", keys = "<Leader>s",      desc = "+Search" },
    { mode = "x", keys = "<Leader>s",      desc = "+Search" },
    { mode = "n", keys = "<Leader>sJ",     desc = "Search Java classes/interfaces" },
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
    { mode = "n", keys = "<Leader>S",      desc = "+Salesforce" },
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
    { mode = "n", keys = "<Leader>uZ",     desc = "Toggle Zoom Mode" },
    { mode = "n", keys = "<Leader>uX",     desc = "Toggle Treesitter Context" },
    { mode = "n", keys = "<Leader>um",     desc = "Toggle Render Markdown" },
    { mode = "n", keys = "<Leader>uC",     desc = "Colorscheme Picker" },
    { mode = "n", keys = "<Leader>uS",     desc = "Toggle SonarLint" },
    { mode = "n", keys = "<Leader>ut",     desc = "Toggle Transparent Background" },
    { mode = "n", keys = "<Leader>ug",     desc = "Toggle Grep Layout (IntelliJ)" },
    { mode = "n", keys = "<Leader>ui",     desc = "Toggle Cmdline Info (ruler/showcmd)" },

    -- Windows
    { mode = "n", keys = "<Leader>w",      desc = "+Windows" },

    -- Lists (quickfix / loclist)
    { mode = "n", keys = "<Leader>x",      desc = "+Lists" },

    -- Tabs
    { mode = "n", keys = "<Leader><Tab>",  desc = "+Tabs" },

    -- Comment subgroup
    { mode = "n", keys = "gc",             desc = "+Comment" },
    { mode = "x", keys = "gc",             desc = "+Comment" },

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

    -- gp Peek preview
    { mode = "n", keys = "gp",             desc = "+Peek" },
    { mode = "n", keys = "gpd",            desc = "Peek definition" },
    { mode = "n", keys = "gpt",            desc = "Peek type definition" },
    { mode = "n", keys = "gpi",            desc = "Peek implementation" },
    { mode = "n", keys = "gpD",            desc = "Peek declaration" },
    { mode = "n", keys = "gpr",            desc = "Peek references (picker)" },
    { mode = "n", keys = "gpc",            desc = "Peek: close all" },

    -- gK — signature help (companion to K=hover)
    { mode = "n", keys = "gK",             desc = "Signature help" },

    -- gz Surround (mini.surround, gz prefix avoids clash with flash s/S)
    { mode = "n", keys = "gz",             desc = "+Surround" },
    { mode = "x", keys = "gz",             desc = "+Surround" },
    { mode = "n", keys = "gza",            desc = "Surround: add" },
    { mode = "x", keys = "gza",            desc = "Surround: add (selection)" },
    { mode = "n", keys = "gzd",            desc = "Surround: delete" },
    { mode = "n", keys = "gzr",            desc = "Surround: replace" },
    { mode = "n", keys = "gzf",            desc = "Surround: find →" },
    { mode = "n", keys = "gzF",            desc = "Surround: find ←" },
    { mode = "n", keys = "gzh",            desc = "Surround: highlight" },
    { mode = "n", keys = "gzn",            desc = "Surround: update n_lines" },

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
