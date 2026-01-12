-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Fix canceallevel for json files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.spell = false
    vim.wo.conceallevel = 0
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
    vim.g.autoformat = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "java", "xml" },
  group = vim.api.nvim_create_augroup("java", { clear = true }),
  callback = function(opts)
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.softtabstop = 4
    vim.g.autoformat = false
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  pattern = { "*.java" },
  callback = function()
    local _, _ = pcall(vim.lsp.codelens.refresh)
  end,
})

vim.filetype.add({
  pattern = {
    [".*/*.cls"] = "apex",
    [".*/*.apex"] = "apex",
  },
})

local diff_buffers = {}
local function setup_diff_mappings()
  local bufnr = vim.api.nvim_get_current_buf()
  diff_buffers[bufnr] = true
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>d", group = "diff", buffer = bufnr },
    })
  end

  vim.keymap.set("n", "]c", "]czz", { buffer = bufnr, desc = "Next change" })
  vim.keymap.set("n", "[c", "[czz", { buffer = bufnr, desc = "Last change" })

  -- Mergetool (3 files): Get specific changes
  vim.keymap.set(
    "n",
    "<leader>dh",
    ":diffget 1<CR>:diffupdate<CR>",
    { buffer = bufnr, desc = "←  Get from LOCAL (left)" }
  )
  vim.keymap.set(
    "n",
    "<leader>dl",
    ":diffget 2<CR>:diffupdate<CR>",
    { buffer = bufnr, desc = "→  Get from REMOTE (right)" }
  )

  -- Normal Diff (2 vías): get/put changes
  vim.keymap.set("n", "<leader>d<", ":diffget<CR>", { buffer = bufnr, desc = "←  Get changes" })
  vim.keymap.set("n", "<leader>d>", ":diffput<CR>", { buffer = bufnr, desc = "→  Put changes" })

  vim.keymap.set("n", "<leader>dr", ":diffupdate<CR>", { buffer = bufnr, desc = "↻  Refresh diff" })
  vim.keymap.set("n", "<leader>dq", ":diffoff!<CR>", { buffer = bufnr, desc = "✕  Quit diff" })

  vim.keymap.set("n", "<leader>d1", ":1wincmd w<CR>", { buffer = bufnr, desc = "❶  Go to LOCAL" })
  vim.keymap.set("n", "<leader>d2", ":2wincmd w<CR>", { buffer = bufnr, desc = "❷  Go to REMOTE" })
  vim.keymap.set("n", "<leader>d3", ":3wincmd w<CR>", { buffer = bufnr, desc = "❸  Go to MERGED" })

  vim.opt.wrap = false
  vim.opt.number = true
  vim.opt.relativenumber = false
  vim.opt.signcolumn = "yes"
  vim.opt.listchars = {
    tab = "▸ ",
    trail = "·",
    extends = "›",
    precedes = "‹",
    nbsp = "␣",
  }
  vim.notify("Diff mappings ready", vim.log.levels.INFO)
end

local function cleanup_diff_mappings()
  local bufnr = vim.api.nvim_get_current_buf()
  diff_buffers[bufnr] = false
  -- Delete diff mappings
  pcall(vim.keymap.del, "n", "]c", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "[c", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>dh", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>dl", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>d<", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>d>", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>dr", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>dq", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>d1", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>d2", { buffer = bufnr })
  pcall(vim.keymap.del, "n", "<leader>d3", { buffer = bufnr })
  vim.opt.scrollbind = false
  vim.opt.cursorbind = false
  vim.opt.relativenumber = true
  vim.opt.signcolumn = nil
  vim.opt.listchars = nil
  -- restore default group "d"
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>d", group = "debug", buffer = bufnr },
    })
  end
end
vim.keymap.set("n", "<leader>ue", function()
  vim.cmd("diffthis")
  setup_diff_mappings()
end, { desc = "Enable diff mode" })
vim.keymap.set("n", "<leader>uE", function()
  vim.cmd("diffoff")
  cleanup_diff_mappings()
end, { desc = "Disable diff mode" })

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.wo.diff and not diff_buffers[bufnr] then
      setup_diff_mappings()
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    diff_buffers[args.buf] = nil
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.opt.diff:get() then
      local windows = vim.api.nvim_list_wins()
      local win_count = #windows
      if win_count == 2 then
        vim.opt.scrollbind = true
        vim.opt.cursorbind = true
      end
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "silent !zellij action switch-mode normal",
})

vim.api.nvim_create_user_command("GitLineHistory", function(opts)
  local s, e = opts.line1, opts.line2
  local spec = string.format("%d,%d:%s", s, e, vim.fn.expand("%:p"))

  local cmd = "git -c core.pager=delta -c delta.paging=never -c delta.line-numbers=true -c delta.side-by-side=false "
    .. "log --color=always -p -L "
    .. vim.fn.shellescape(spec)

  vim.cmd("vsplit")
  vim.cmd("terminal " .. cmd)
end, { range = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.api.nvim_set_hl(0, "WinBar", { link = "StatusLine" })
    vim.api.nvim_set_hl(0, "WinBarNC", { link = "StatusLineNC" })
  end,
})

vim.api.nvim_create_user_command("DiffContextZero", function()
  vim.opt.diffopt:remove("context:999999")
  vim.opt.diffopt:append("context:0")
end, { desc = "Set diff context Zero" })

vim.api.nvim_create_user_command("DiffContextAll", function()
  vim.opt.diffopt:remove("context:0")
  vim.opt.diffopt:append("context:999999")
end, { desc = "Set diff context All" })
