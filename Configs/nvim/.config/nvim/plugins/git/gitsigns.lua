-- gitsigns.nvim: git hunk decorations and buffer-local <leader>g keymaps.

local ok, gs = pcall(require, "gitsigns")
if not ok then return end

gs.setup({
  signs = {
    add          = { text = "│" },
    change       = { text = "│" },
    changedelete = { text = "│" },
    delete       = { text = "│" },
    topdelete    = { text = "│" },
    untracked    = { text = "│" },
  },
  signs_staged_enable = true,
  current_line_blame = false,
  linehl = false,
  numhl = false,

  on_attach = function(bufnr)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    end

    local function restart_treesitter_later(target_buf)
      vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(target_buf) or not vim.api.nvim_buf_is_loaded(target_buf) then
          return
        end
        if vim.bo[target_buf].buftype ~= "" or vim.bo[target_buf].filetype == "" then
          return
        end
        for _, win in ipairs(vim.fn.win_findbuf(target_buf)) do
          if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
            return
          end
        end
        pcall(vim.treesitter.start, target_buf)
      end, 80)
    end

    local function with_treesitter_paused(fn)
      return function(...)
        local current_buf = vim.api.nvim_get_current_buf()
        pcall(vim.treesitter.stop, current_buf)
        local ok_action, err = pcall(fn, ...)
        restart_treesitter_later(current_buf)
        if not ok_action then
          vim.notify(tostring(err), vim.log.levels.ERROR)
        end
      end
    end

    local function stop_treesitter_in_diff_windows()
      vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
            pcall(vim.treesitter.stop, vim.api.nvim_win_get_buf(win))
          end
        end
      end)
    end

    -- Navigation between hunks
    map("]h", function() gs.nav_hunk("next") end, "Git: next hunk")
    map("[h", function() gs.nav_hunk("prev") end, "Git: prev hunk")

    -- Hunk actions
    map("<leader>gs", with_treesitter_paused(gs.stage_hunk),           "Git: stage hunk")
    map("<leader>gr", with_treesitter_paused(gs.reset_hunk),           "Git: reset hunk")
    map("<leader>gS", with_treesitter_paused(gs.stage_buffer),         "Git: stage buffer")
    map("<leader>gR", with_treesitter_paused(gs.reset_buffer),         "Git: reset buffer")
    map("<leader>gp", with_treesitter_paused(gs.preview_hunk),         "Git: preview hunk")
    map("<leader>gb", function() gs.blame_line({ full = true }) end,     "Git: blame line")
    map("<leader>gt", function() gs.toggle_current_line_blame() end,    "Git: toggle line blame")
    map("<leader>gd", with_treesitter_paused(function()
      gs.diffthis()
      stop_treesitter_in_diff_windows()
    end),                                                             "Git: diff this")
    map("<leader>gD", with_treesitter_paused(function()
      gs.diffthis("~")
      stop_treesitter_in_diff_windows()
    end),                                                             "Git: diff HEAD~")

    -- Text object: select hunk
    vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>",
      { buffer = bufnr, desc = "Select git hunk" })
  end,
})

-- Global fallback keeps hunk navigation available before buffer-local on_attach maps exist.
vim.keymap.set("n", "]h", function() gs.nav_hunk("next") end, { desc = "Git: next hunk" })
vim.keymap.set("n", "[h", function() gs.nav_hunk("prev") end, { desc = "Git: prev hunk" })
