-- Default theme: Catppuccin Mocha, tuned for transparent dark terminals.

local colorschemes = require("colorschemes")
colorschemes.setup_autocmd()

local flavour = vim.g.pure_catppuccin_flavour or "mocha"
vim.o.background = (flavour == "latte") and "light" or "dark"

local ok, catppuccin = pcall(require, "catppuccin")
if not ok then return end

catppuccin.setup({
  flavour = flavour,
  background = {
    light = "latte",
    dark = "mocha",
  },

  transparent_background = colorschemes.is_transparent(),
  show_end_of_buffer = false,
  term_colors = true,

  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },

  styles = {
    comments = { "italic" },
    functions = { "bold" },
    keywords = { "italic" },
    operators = { "bold" },
    conditionals = { "bold" },
    loops = { "bold" },
    booleans = { "bold", "italic" },
    numbers = {},
    types = {},
    strings = {},
    variables = {},
    properties = {},
  },

  integrations = {
    blink_cmp = true,
    dap = true,
    gitsigns = true,
    mason = true,
    mini = { enabled = true, indentscope_color = "" },
    native_lsp = {
      enabled = true,
      virtual_text = {
        errors = { "italic" },
        hints = { "italic" },
        warnings = { "italic" },
        information = { "italic" },
      },
      underlines = {
        errors = { "underline" },
        hints = { "underline" },
        warnings = { "underline" },
        information = { "underline" },
      },
    },
    treesitter_context = true,
    notifier = true,
    snacks = true,
    treesitter = true,
    render_markdown = true,
  },

  highlight_overrides = {
    all = function(cp)
      return {
        NormalFloat = { fg = cp.text, bg = cp.none },
        FloatBorder = { fg = cp.blue, bg = cp.none },
        CursorLineNr = { fg = cp.green },
        DiagnosticVirtualTextError = { bg = cp.none },
        DiagnosticVirtualTextWarn = { bg = cp.none },
        DiagnosticVirtualTextInfo = { bg = cp.none },
        DiagnosticVirtualTextHint = { bg = cp.none },
        LspInfoBorder = { link = "FloatBorder" },
        MasonNormal = { link = "NormalFloat" },
        Pmenu = { fg = cp.overlay2, bg = cp.none },
        PmenuBorder = { fg = cp.surface1, bg = cp.none },
        PmenuSel = { bg = cp.green, fg = cp.base },
        NotifyBackground = { bg = cp.none },
        DapBreakpoint = { fg = cp.red, bg = cp.none },
        DapBreakpointCondition = { fg = cp.peach, bg = cp.none },
        DapLogPoint = { fg = cp.teal, bg = cp.none },
        DapStopped = { fg = cp.green, bg = cp.none },
        DapStoppedLine = { bg = cp.surface0 },
        DapBreakpointRejected = { fg = cp.overlay0, bg = cp.none },
        StatusLine = { fg = cp.surface1, bg = cp.none, reverse = false },
        StatusLineNC = { fg = cp.surface0, bg = cp.none, reverse = false },
        WinBar = { fg = cp.overlay1, bg = cp.none },
        WinBarNC = { fg = cp.surface2, bg = cp.none },
        WinBarIcon = { fg = cp.blue, bg = cp.none },
        WinBarPath = { fg = cp.overlay0, bg = cp.none },
        WinBarSep = { fg = cp.surface1, bg = cp.none },
        WinBarFile = { fg = cp.text, bg = cp.none, bold = true },
        WinBarMod = { fg = cp.peach, bg = cp.none, bold = true },
        WinBarLine = { fg = cp.surface2, bg = cp.none },
      }
    end,
  },
})

local ok_s, Snacks = pcall(require, "snacks")
if ok_s and Snacks.toggle and not vim.g._pure_transparency_toggle_registered then
  vim.g._pure_transparency_toggle_registered = true
  Snacks.toggle({
    name = "Transparent Background",
    get = function() return colorschemes.is_transparent() end,
    set = function(state) colorschemes.set_transparency(state) end,
  }):map("<leader>uA")
end

if not vim.g._pure_applying_colorscheme then
  colorschemes.apply(vim.g.pure_colorscheme or colorschemes.default, { notify = false })
end