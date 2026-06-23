local M = {}

local function edit_netrw_hiding_list()
  vim.ui.input({
    prompt = "Edit Hiding List: ",
    default = vim.g.netrw_list_hide or "",
    scope = "buffer",
  }, function(value)
    if value == nil then
      return
    end

    vim.g.netrw_list_hide = value
    local keys = vim.api.nvim_replace_termcodes("<Plug>NetrwRefresh", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("avante_no_numbers", { clear = true }),
    pattern = { "Avante", "AvanteInput" },
    callback = function()
      vim.wo.number = false
      vim.wo.relativenumber = false
    end,
  })

  vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    callback = function()
      vim.highlight.on_yank({ timeout = 200 })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("pure_netrw_split_navigation", { clear = true }),
    pattern = "netrw",
    callback = function(args)
      vim.keymap.set("n", "<leader>er", "<Plug>NetrwRefresh", {
        buffer = args.buf,
        remap = true,
        silent = true,
        desc = "Netrw: refresh directory listing",
      })
      vim.keymap.set("n", "<leader>eh", edit_netrw_hiding_list, {
        buffer = args.buf,
        silent = true,
        desc = "Netrw: edit file hiding list",
      })
      vim.keymap.set("n", "<C-l>", function()
        require("pure-ui.split_nav").move("l")
      end, { buffer = args.buf, silent = true, nowait = true, desc = "Move to right window" })
    end,
  })
end

return M
