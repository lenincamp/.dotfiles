-- mini.indentscope: animated vertical line showing the current indent scope.
-- Activates on cursor move; draws a vertical column from the scope's top to bottom.
--
-- Disabled globally by default; enabled only for normal file buffers (buftype == "").
-- This is opt-in rather than a blocklist — any plugin UI is excluded automatically.

local ok, indentscope = pcall(require, "mini.indentscope")
if not ok then return end

indentscope.setup({
  -- Symbol drawn for the scope indicator
  symbol = "│",

  draw = {
    -- Delay (ms) before the indicator appears after cursor stops
    delay = 100,
    -- Fade-in animation: set to indentscope.gen_animation.none() to disable
    animation = indentscope.gen_animation.linear({ easing = "in", duration = 20, unit = "total" }),
    -- Priority of the extmark — above treesitter highlights (100), below diagnostics (150)
    priority = 101,
  },

  options = {
    -- Use the indent level at the cursor position (not the line start)
    indent_at_cursor = true,
    -- Try to treat scope boundary lines as the border (top/bottom of a block)
    try_as_border = true,
    -- Which borders count: "both" | "top" | "bottom" | "none"
    border = "both",
  },

  -- Filetypes where the indicator is distracting or meaningless
  mappings = {
    -- Text objects for the scope body (excluding border lines)
    object_scope         = "ii",
    object_scope_with_border = "ai",
    -- Jump to scope top/bottom border
    goto_top    = "[i",
    goto_bottom = "]i",
  },
})

-- Disable for any non-file buffer. mini.nvim uses OR logic on the disable flags,
-- so a global true can't be overridden per-buffer — only buffer-local works here.
-- buftype == "" means a normal file; plugin UIs (dashboard, chat, pickers,
-- terminals…) all have a non-empty buftype and are excluded automatically.
-- Link the indicator to a theme highlight group so it always matches the colorscheme.
-- MiniIndentscopeSymbol controls the symbol color; MiniIndentscopeSymbolOff is used
-- when the cursor is outside an indent scope.
local function set_hl()
  vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol",    { link = "Comment" })
  vim.api.nvim_set_hl(0, "MiniIndentscopeSymbolOff", { link = "NonText" })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  callback = function(ev)
    -- Defer so buftype/filetype are fully set before we check.
    -- BufWinEnter fires before some plugin UIs (e.g. snacks dashboard) set
    -- their buftype, so reading it synchronously gives a false "".
    local buf = ev.buf
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.b[buf].miniindentscope_disable = vim.bo[buf].buftype ~= ""
      end
    end)
  end,
})
