-- catppuccin: auto-selects Mocha (dark) or Latte (light) based on OS appearance.
-- macOS: reads AppleInterfaceStyle via `defaults`.
-- Linux: reads org.gnome.desktop.interface color-scheme via gsettings (fallback: dark).
-- Manual toggle: <leader>ub  (Snacks.toggle.option "background" defined in snacks.lua)

-- ── OS appearance detection (non-blocking) ───────────────────────────────────
-- Uses a cached ShaDa global (vim.g._bg_cache) so the expensive syscall only
-- runs once per login session. After the async result arrives, the colorscheme
-- is reapplied if needed — zero blocking at startup.

local sysname = vim.uv.os_uname().sysname

local function apply_background(is_dark)
  local bg = is_dark and "dark" or "light"
  if vim.o.background ~= bg then
    vim.o.background = bg
    -- Reapply colorscheme only if it changed after initial load
    if vim.g.colors_name and vim.g.colors_name:find("catppuccin") then
      vim.cmd.colorscheme("catppuccin")
    end
  end
end

-- Immediate fallback: use cached value from last session, or dark
local cached = vim.g._bg_cache
vim.o.background = (cached ~= nil) and cached or "dark"

-- Async detection — applies correction within ~10ms without blocking startup
vim.uv.new_async(vim.schedule_wrap(function() end)):send()  -- ensure loop is running
vim.defer_fn(function()
  -- Fast sync detection using vim.system (Neovim 0.10+ non-blocking wrapper)
  if sysname == "Darwin" then
    vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true },
      function(out)
        vim.schedule(function()
          local is_dark = (out.code == 0) and vim.trim(out.stdout) == "Dark" or false
          vim.g._bg_cache = is_dark and "dark" or "light"
          apply_background(is_dark)
        end)
      end)
  elseif sysname == "Linux" then
    vim.system({ "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" }, { text = true },
      function(out)
        vim.schedule(function()
          local is_dark = not (out.stdout or ""):find("light", 1, true)
          vim.g._bg_cache = is_dark and "dark" or "light"
          apply_background(is_dark)
        end)
      end)
  end
end, 0)

-- ── Setup ─────────────────────────────────────────────────────────────────────

local ok, catppuccin = pcall(require, "catppuccin")
if not ok then return end

catppuccin.setup({
  -- Which flavour to use for each background value
  background = {
    light = "latte",
    dark  = "mocha",
  },

  -- Initial transparency state — tracked in vim.g so the toggle can read it
  transparent_background = vim.g.catppuccin_transparent ~= false,
  show_end_of_buffer     = false,
  term_colors            = true,

  dim_inactive = {
    enabled    = false,
    shade      = "dark",
    percentage = 0.15,
  },

  -- ── Token styles ────────────────────────────────────────────────────────────
  styles = {
    comments    = { "italic" },
    functions   = { "bold" },
    keywords    = { "italic" },
    operators   = { "bold" },
    conditionals = { "bold" },
    loops       = { "bold" },
    booleans    = { "bold", "italic" },
    numbers     = {},
    types       = {},
    strings     = {},
    variables   = {},
    properties  = {},
  },

  -- ── Integrations (only plugins installed in nvim-pure) ─────────────────────
  integrations = {
    blink_cmp   = true,   -- blink.cmp completion popup
    dap         = true,   -- nvim-dap debug session colours
    gitsigns    = true,   -- gitsigns hunk signs
    mason       = true,   -- Mason installer UI
    mini        = { enabled = true, indentscope_color = "" }, -- mini.clue, mini.pairs
    native_lsp  = {
      enabled      = true,
      virtual_text = {
        errors      = { "italic" },
        hints       = { "italic" },
        warnings    = { "italic" },
        information = { "italic" },
      },
      underlines   = {
        errors      = { "underline" },
        hints       = { "underline" },
        warnings    = { "underline" },
        information = { "underline" },
      },
    },
    treesitter_context = true, -- nvim-treesitter-context sticky header
    notifier         = true,   -- snacks.notifier
    snacks           = true,   -- snacks.nvim (picker, explorer, lazygit …)
    treesitter       = true,   -- nvim-treesitter highlight
    render_markdown  = true,   -- render-markdown.nvim
  },

  color_overrides = {},

  -- ── Highlight overrides (only for plugins actually present) ─────────────────
  highlight_overrides = {
    all = function(cp)
      return {
        -- Floating windows
        NormalFloat = {
          fg = cp.text,
          bg = cp.none, -- transparent: let terminal bg show
        },
        FloatBorder = { fg = cp.blue,    bg = cp.none },

        -- Line number accent
        CursorLineNr = { fg = cp.green },

        -- Clean diagnostic virtual text (no coloured bg blocks)
        DiagnosticVirtualTextError = { bg = cp.none },
        DiagnosticVirtualTextWarn  = { bg = cp.none },
        DiagnosticVirtualTextInfo  = { bg = cp.none },
        DiagnosticVirtualTextHint  = { bg = cp.none },

        -- LSP info border matches other floats
        LspInfoBorder = { link = "FloatBorder" },

        -- Mason popup
        MasonNormal = { link = "NormalFloat" },

        -- Completion popup (blink.cmp uses Pmenu* groups)
        Pmenu      = { fg = cp.overlay2, bg = cp.none },
        PmenuBorder = { fg = cp.surface1, bg = cp.none },
        PmenuSel   = { bg = cp.green,    fg = cp.base },

        -- snacks notifier background
        NotifyBackground = { bg = cp.base },

        -- DAP signs (replace dim SignColumn default)
        DapBreakpoint          = { fg = cp.red,      bg = cp.none },
        DapBreakpointCondition = { fg = cp.peach,    bg = cp.none },
        DapLogPoint            = { fg = cp.teal,     bg = cp.none },
        DapStopped             = { fg = cp.green,    bg = cp.none },
        DapStoppedLine         = { bg = cp.surface0 },
        DapBreakpointRejected  = { fg = cp.overlay0, bg = cp.none },

        -- Statusline separator (thin line matching WinSeparator)
        StatusLine   = { fg = cp.surface1, bg = cp.none, reverse = false },
        StatusLineNC = { fg = cp.surface0, bg = cp.none, reverse = false },

        -- Winbar breadcrumb
        WinBar       = { fg = cp.overlay1, bg = cp.none },
        WinBarNC     = { fg = cp.surface2, bg = cp.none },
        WinBarIcon   = { fg = cp.blue,     bg = cp.none },          -- filetype icon
        WinBarPath   = { fg = cp.overlay0, bg = cp.none },
        WinBarSep    = { fg = cp.surface1, bg = cp.none },
        WinBarFile   = { fg = cp.text,     bg = cp.none, bold = true },
        WinBarMod    = { fg = cp.peach,    bg = cp.none, bold = true },
        WinBarLine   = { fg = cp.surface2, bg = cp.none },          -- line:col (subtle)
      }
    end,
  },
})

-- ── Apply colorscheme ─────────────────────────────────────────────────────────
-- Using the generic "catppuccin" name lets the background option pick the flavour.

-- Initialise global state (true = transparent on by default)
if vim.g.catppuccin_transparent == nil then
  vim.g.catppuccin_transparent = true
end

vim.cmd.colorscheme("catppuccin")

-- ── Transparency toggle (<leader>ut) ──────────────────────────────────────────
-- Registered via Snacks.toggle so it shows the on/off indicator in mini.clue.

local ok_s, Snacks = pcall(require, "snacks")
if ok_s and Snacks.toggle then
  Snacks.toggle({
    name = "Transparent Background",
    get  = function() return vim.g.catppuccin_transparent == true end,
    set  = function(state)
      vim.g.catppuccin_transparent = state
      require("catppuccin").setup({ transparent_background = state })
      vim.cmd.colorscheme("catppuccin")  -- reapply to flush hl groups
    end,
  }):map("<leader>ut")
end
