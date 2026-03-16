-- gitsigns.nvim: git hunk decorations and buffer-local <leader>g keymaps.

local ok, gs = pcall(require, "gitsigns")
if not ok then return end

gs.setup({
  signs = {
    add          = { text = "▏" },
    change       = { text = "▏" },
    changedelete = { text = "▏" },
    delete       = { text = "⋯" },
    topdelete    = { text = "⋯" },
    untracked    = { text = "┆" },
  },
  signs_staged_enable = true,

  on_attach = function(bufnr)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end

    -- Navigation between hunks
    map("]h", function() gs.nav_hunk("next") end, "Git: next hunk")
    map("[h", function() gs.nav_hunk("prev") end, "Git: prev hunk")

    -- Hunk actions
    map("<leader>gs", gs.stage_hunk,                                  "Git: stage hunk")
    map("<leader>gr", gs.reset_hunk,                                  "Git: reset hunk")
    map("<leader>gS", gs.stage_buffer,                                "Git: stage buffer")
    map("<leader>gR", gs.reset_buffer,                                "Git: reset buffer")
    map("<leader>gp", gs.preview_hunk,                                "Git: preview hunk")
    map("<leader>gd", gs.diffthis,                                    "Git: diff this")
    map("<leader>gD", function() gs.diffthis("~") end,                "Git: diff HEAD~")

    -- Text object: select hunk
    vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>",
      { buffer = bufnr, desc = "Select git hunk" })
  end,
})
