local status, gitsigns = pcall(require, "gitsigns")
if (not status) then return end

gitsigns.setup {
  numhl = true,
  on_attach = function(bufnr)
    -- local gs = package.loaded.gitsigns
    -- require("gitsigns.defaults").setup_keymaps()

    local function map(mode, l, r, opts)
      opts = opts or {}
      -- opts.buffer = bufnr
      vim.api.nvim_buf_set_keymap(bufnr, mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
    map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })

    -- Actions
    map("n", "<leader>sb", '<cmd>lua require"gitsigns".stage_buffer()<CR>', { noremap = true, silent = true })
    map("n", "<leader>us", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', { noremap = true, silent = true })
    map("n", "<leader>rs", '<cmd>lua require"gitsigns".reset_buffer()<CR>', { noremap = true, silent = true })
    map("n", "<leader>ph", '<cmd>lua require"gitsigns".preview_hunk()<CR>', { noremap = true, silent = true })

    map(
      "n",
      "<leader>bl",
      '<cmd>lua require"gitsigns".blame_line({full = true})<CR>',
      { noremap = true, silent = true }
    )
    map("n", "<leader>tb", '<cmd>lua require"gitsigns".toggle_current_line_blame()<CR>',
      { noremap = true, silent = true })


    -- Text object
    map("o", "ih", ":<C-U>Gitsigns select_hunk<CR>")
    map("x", "ih", ":<C-U>Gitsigns select_hunk<CR>")
  end,
}
