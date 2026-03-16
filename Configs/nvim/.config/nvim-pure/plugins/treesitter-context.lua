-- nvim-treesitter-context: shows a sticky header at the top of the window
-- displaying the class / function / block the cursor is currently inside.
-- Exactly like VS Code "sticky scroll" / breadcrumb context.

local ok, ctx = pcall(require, "treesitter-context")
if not ok then return end

ctx.setup({
  enable            = true,
  max_lines         = 4,      -- max lines the context window can take
  min_window_height = 20,     -- only show when buffer is tall enough
  line_numbers      = true,
  multiline_threshold = 1,    -- collapse single-line context
  trim_scope        = "outer", -- trim outermost scope when context too long
  mode              = "cursor", -- update on cursor position (not topline)
  separator         = "─",    -- separator between context and content
  zindex            = 20,
  on_attach         = nil,    -- attach to all buffers with a TS parser
})

-- Toggle with <leader>uX (u = UI toggles, X = conteXt)
local ok_s, Snacks = pcall(require, "snacks")
if ok_s and Snacks.toggle then
  Snacks.toggle({
    name = "Treesitter Context",
    get  = function() return require("treesitter-context").enabled() end,
    set  = function(v)
      if v then require("treesitter-context").enable()
      else      require("treesitter-context").disable() end
    end,
  }):map("<leader>uX")
end

-- Jump to current context (go to start of the function/class you're in)
vim.keymap.set("n", "[X", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true, desc = "Jump to context start" })
