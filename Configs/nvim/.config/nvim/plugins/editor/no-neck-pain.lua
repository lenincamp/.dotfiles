-- no-neck-pain: stable centered editor layout (IntelliJ-like Zen with splits).
-- Keymaps are defined in lua/keymaps.lua to avoid duplicates.

local ok, nnp = pcall(require, "no-neck-pain")
if not ok then return end

nnp.setup({
  -- Keep side buffers narrow and non-intrusive.
  buffers = {
    left = {
      enabled = true,
      scratchPad = {
        enabled = false,
      },
    },
    right = {
      enabled = true,
      scratchPad = {
        enabled = false,
      },
    },
    bo = {
      filetype = "no-neck-pain",
      buftype = "nofile",
      bufhidden = "wipe",
      swapfile = false,
      buflisted = false,
    },
    wo = {
      winfixwidth = true,
      number = false,
      relativenumber = false,
      signcolumn = "no",
      foldcolumn = "0",
      cursorline = false,
      cursorcolumn = false,
      colorcolumn = "",
      list = false,
      wrap = false,
    },
  },

  -- Main behavior: keep coding area centered and predictable while splitting.
  mappings = {
    enabled = false,
  },
  width = tonumber(vim.g.pure_zen_width) or 120,
  minSideBufferWidth = 10,
  autocmds = {
    enableOnVimEnter = false,
    enableOnTabEnter = false,
    reloadOnColorSchemeChange = true,
  },
})
