local M = {}

local lsp_core = require("modules.core.lsp")
local runtime = require("modules.core.runtime")

local DIFF_KEYMAPS = { "]c", "[c", "do", "dp", "dO", "dP" }

local function disable_lsp_for_diff_buffer(bufnr)
  lsp_core.detach_all(bufnr)
  lsp_core.set_diagnostics(bufnr, false)
  vim.b[bufnr].diff_lsp_disabled = true
end

local function is_merge_diff_mode()
  if not vim.wo.diff then return false end
  local labels = { LOCAL = false, REMOTE = false, BASE = false, MERGED = false }

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
      if labels[name] ~= nil then
        labels[name] = true
      end
    end
  end

  return labels.LOCAL and labels.REMOTE
end

local function setup_diff_mappings()
  if not vim.wo.diff then return end
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].diff_keymaps_active then return end

  local helpers = require("modules.editor")
  local bmap = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  bmap("]c", helpers.diff_jump_next, "Next change")
  bmap("[c", helpers.diff_jump_prev, "Prev change")
  bmap("do", function()
    if is_merge_diff_mode() then
      local ok = pcall(vim.cmd, "DiffGetLocal")
      if not ok then vim.cmd("diffget") end
    else
      vim.cmd("diffget")
    end
    vim.cmd("diffupdate")
  end, "Obtain change (diffget)")
  bmap("dp", function()
    if is_merge_diff_mode() then
      local ok = pcall(vim.cmd, "DiffGetRemote")
      if not ok then vim.cmd("diffput") end
    else
      vim.cmd("diffput")
    end
    vim.cmd("diffupdate")
  end, "Put change (diffput)")
  bmap("dO", function()
    if is_merge_diff_mode() then
      local ok = pcall(vim.cmd, "DiffGetLocalAll")
      if not ok then vim.cmd("%diffget") end
    else
      vim.cmd("%diffget")
    end
    vim.cmd("diffupdate")
  end, "Obtain all changes")
  bmap("dP", function()
    if is_merge_diff_mode() then
      local ok = pcall(vim.cmd, "DiffGetRemoteAll")
      if not ok then vim.cmd("%diffput") end
    else
      vim.cmd("%diffput")
    end
    vim.cmd("diffupdate")
  end, "Put all changes")

  vim.b[bufnr].diff_keymaps_active = true
  vim.w.diff_prev_listchars = vim.opt_local.listchars:get()
  vim.wo.wrap = false
  vim.wo.number = true
  vim.wo.relativenumber = true
  vim.wo.signcolumn = "yes"
  vim.opt_local.listchars = { tab = "▸ ", trail = "·", extends = "›", precedes = "‹", nbsp = "␣" }

  pcall(vim.treesitter.stop, bufnr)
  vim.cmd("syntax enable")
end

local function cleanup_diff_mappings(bufnr)
  local target_buf = bufnr or vim.api.nvim_get_current_buf()

  if vim.b[target_buf] and vim.b[target_buf].diff_keymaps_active then
    for _, lhs in ipairs(DIFF_KEYMAPS) do
      pcall(vim.keymap.del, "n", lhs, { buffer = target_buf })
    end
    vim.b[target_buf].diff_keymaps_active = false
  end

  vim.opt.scrollbind = false
  vim.opt.cursorbind = false
  if vim.bo[target_buf].buftype == "" then
    vim.wo.relativenumber = true
  end
  vim.wo.signcolumn = nil
  if vim.w.diff_prev_listchars ~= nil then
    vim.opt_local.listchars = vim.w.diff_prev_listchars
    vim.w.diff_prev_listchars = nil
  end
end

local function setup_current_diff_window()
  if not vim.wo.diff then return end
  vim.wo.scrollbind = true
  vim.wo.cursorbind = true
  runtime.setup_diff_mappings()

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.b[bufnr].diff_lsp_forced then
    disable_lsp_for_diff_buffer(bufnr)
  end
end

local function setup_diff_mode()
  if not vim.opt.diff:get() then return end

  vim.notify("Entering diff mode", vim.log.levels.INFO)

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      lsp_core.detach_all(bufnr)
    end
  end

  pcall(vim.treesitter.stop)
  vim.cmd("set number")
  vim.cmd("set colorcolumn=")

  vim.opt_local.foldmethod = "diff"
  vim.opt_local.foldenable = true
  vim.opt_local.foldlevel = 0
end

local function register_diff_lsp_commands()
  vim.api.nvim_create_user_command("DiffLspEnable", function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr].diff_lsp_forced = true
    vim.b[bufnr].diff_lsp_disabled = false
    lsp_core.set_diagnostics(bufnr, true)

    runtime.enable_lsp_for_buffer(bufnr, { force = true })

    pcall(vim.cmd, "LspStart")
    vim.notify("Diff LSP enabled for current buffer", vim.log.levels.INFO)
  end, { desc = "Enable LSP on demand for current diff buffer" })

  vim.api.nvim_create_user_command("DiffLspDisable", function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr].diff_lsp_forced = false
    disable_lsp_for_diff_buffer(bufnr)
    vim.notify("Diff LSP disabled for current buffer", vim.log.levels.INFO)
  end, { desc = "Disable LSP for current diff buffer" })

  vim.api.nvim_create_user_command("DiffLspToggle", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.b[bufnr].diff_lsp_forced then
      vim.cmd("DiffLspDisable")
    else
      vim.cmd("DiffLspEnable")
    end
  end, { desc = "Toggle LSP for current diff buffer" })
end

local function register_merge_source_commands()
  vim.api.nvim_create_user_command("DiffGetLocal", function()
    vim.cmd("diffget LOCAL")
    vim.cmd("diffupdate")
  end, { desc = "Diff: get LOCAL changes into current buffer" })

  vim.api.nvim_create_user_command("DiffGetRemote", function()
    vim.cmd("diffget REMOTE")
    vim.cmd("diffupdate")
  end, { desc = "Diff: get REMOTE changes into current buffer" })

  vim.api.nvim_create_user_command("DiffGetLocalAll", function()
    vim.cmd("%diffget LOCAL")
    vim.cmd("diffupdate")
  end, { desc = "Diff: get ALL LOCAL changes into current buffer" })

  vim.api.nvim_create_user_command("DiffGetRemoteAll", function()
    vim.cmd("%diffget REMOTE")
    vim.cmd("diffupdate")
  end, { desc = "Diff: get ALL REMOTE changes into current buffer" })
end

local function register_context_commands()
  vim.api.nvim_create_user_command("DiffContextZero", function()
    vim.opt.diffopt:remove("context:999999")
    vim.opt.diffopt:append("context:0")
  end, { desc = "Set diff context to 0 lines" })

  vim.api.nvim_create_user_command("DiffContextAll", function()
    vim.opt.diffopt:remove("context:0")
    vim.opt.diffopt:append("context:999999")
  end, { desc = "Set diff context to all lines" })
end

function M.setup()
  runtime.set_diff_api({
    setup = setup_diff_mappings,
    cleanup = cleanup_diff_mappings,
  })

  vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("diff_window_setup", { clear = true }),
    callback = function()
      if vim.wo.diff then
        setup_current_diff_window()
      else
        runtime.cleanup_diff_mappings()
      end
    end,
  })

  vim.api.nvim_create_autocmd("UIEnter", {
    group = vim.api.nvim_create_augroup("DiffMode", { clear = true }),
    once = true,
    callback = function()
      setup_diff_mode()
    end,
  })

  register_diff_lsp_commands()
  register_merge_source_commands()
  register_context_commands()
end

return M
