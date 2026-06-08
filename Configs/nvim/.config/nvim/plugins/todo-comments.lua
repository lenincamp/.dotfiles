-- todo-comments.nvim: highlight and search TODO/FIXME/HACK/NOTE/WARN/PERF.
-- Navigate: ]t / [t. Search: <leader>st / <leader>sT.

local ok, todo = pcall(require, "todo-comments")
if not ok then return end

todo.setup({
  signs = true,
  keywords = {
    FIX  = { icon = " ", color = "error",   alt = { "FIXME", "BUG", "ISSUE" } },
    TODO = { icon = " ", color = "info" },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
    PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
    NOTE = { icon = " ", color = "hint",    alt = { "INFO" } },
    TEST = { icon = "⏲ ", color = "test",    alt = { "TESTING", "PASSED", "FAILED" } },
  },
})

-- Navigation
vim.keymap.set("n", "]t", function() todo.jump_next() end, { desc = "Next TODO" })
vim.keymap.set("n", "[t", function() todo.jump_prev() end, { desc = "Prev TODO" })

-- Search via snacks picker
local ok_s, Snacks = pcall(require, "snacks")
if ok_s then
  vim.keymap.set("n", "<leader>st", function() Snacks.picker.todo_comments() end,
    { desc = "Search TODO" })
  vim.keymap.set("n", "<leader>sT", function()
    Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
  end, { desc = "Search TODO/FIX/FIXME" })
end
