local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ── LSP Helper: Detach all clients safely ────────────────────────────────────

local function detach_all_lsp_clients(bufnr)
  local clients = {}
  if vim.lsp.get_clients then
    clients = vim.lsp.get_clients({ bufnr = bufnr })
  else
    clients = vim.lsp.get_active_clients({ buffer = bufnr })
  end
  for _, client in ipairs(clients) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end
end

local function set_buffer_diagnostics(bufnr, enabled)
  local ok = pcall(vim.diagnostic.enable, enabled, { bufnr = bufnr })
  if ok then return end

  if enabled then
    pcall(vim.diagnostic.enable, bufnr)
  else
    pcall(vim.diagnostic.disable, bufnr)
  end
end

local function set_number_options_for_buf(bufnr, number, relativenumber)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].number = number
      vim.wo[win].relativenumber = relativenumber
    end
  end
end

local function fast_text_search_current_file(bufnr)
  local query = vim.fn.input("Search text > ")
  if query == nil or query == "" then return end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    vim.notify("Buffer has no file on disk", vim.log.levels.WARN)
    return
  end

  local lines = vim.fn.systemlist({
    "rg",
    "--vimgrep",
    "--smart-case",
    "--",
    query,
    file,
  })

  -- If query is not a valid regex, fallback to literal search.
  if vim.v.shell_error == 2 then
    lines = vim.fn.systemlist({
      "rg",
      "--vimgrep",
      "--smart-case",
      "--fixed-strings",
      "--",
      query,
      file,
    })
  end

  if vim.v.shell_error ~= 0 and #lines == 0 then
    vim.notify("No text matches found", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, " ", {
    title = string.format("Search: %s", query),
    lines = lines,
  })
  vim.cmd("copen")
end

-- Fast in-file grep for any filetype.
vim.keymap.set("n", "<leader>/", function()
  fast_text_search_current_file(vim.api.nvim_get_current_buf())
end, { silent = true, desc = "Fast search text in current file (rg)" })

local function disable_lsp_for_diff_buffer(bufnr)
  detach_all_lsp_clients(bufnr)
  set_buffer_diagnostics(bufnr, false)
  vim.b[bufnr].diff_lsp_disabled = true
end

-- Single size control for every huge-file optimization path.
local HUGE_FILE_THRESHOLD = 2500000 -- 2.5MB

-- Highlight yanked text (fires in all modes: normal, visual, command)
local highlight_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  pattern  = "*",
  group    = highlight_group,
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- ── Filetype-specific indent / options ───────────────────────────────────────

vim.api.nvim_create_autocmd("FileType", {
  pattern  = { "json", "jsonc" },
  group    = vim.api.nvim_create_augroup("json_large_file", { clear = true }),
  callback = function(ev)
    local file_size = vim.fn.getfsize(vim.fn.expand("%"))

    vim.wo.spell        = false
    vim.wo.conceallevel = 0
    vim.bo[ev.buf].tabstop     = 2
    vim.bo[ev.buf].shiftwidth  = 2
    vim.bo[ev.buf].softtabstop = 2
    vim.b[ev.buf].autoformat   = false

    -- Para JSON > 2.5MB: desactivar features pesadas
    if file_size > HUGE_FILE_THRESHOLD then
      -- Disable Treesitter (JSON parser es lento con archivos grandes)
      pcall(vim.treesitter.stop, ev.buf)

      -- Disable expensive folds/highlight passes in very large JSON files.
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.foldexpr = "0"
      vim.opt_local.foldenable = false
      vim.opt_local.synmaxcol = 120

      -- Disable LSP (json-lsp puede quedarse colgado)
      detach_all_lsp_clients(ev.buf)
      set_buffer_diagnostics(ev.buf, false)

      -- Keep line numbers consistent with user preference
      set_number_options_for_buf(ev.buf, true, true)

      -- Optimize rendering
      vim.opt.lazyredraw = true
      vim.opt.updatetime = 1500
      vim.opt.redrawtime = 5000  -- Increase timeout for slow redraws

      -- No undo history (guarda memoria)
      vim.bo[ev.buf].undolevels = 0
      vim.bo[ev.buf].undofile = false

      -- No line wrapping
      vim.wo.wrap = false
      vim.wo.list = false
      vim.wo.cursorline = false
      vim.opt_local.wrapscan = false

      vim.notify(
        string.format("JSON grande detectado (%.1fMB) — fast search activo (<leader>/)", file_size / 1000000),
        vim.log.levels.WARN
      )
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern  = { "java", "xml" },
  group    = vim.api.nvim_create_augroup("java_xml_indent", { clear = true }),
  callback = function(ev)
    vim.bo[ev.buf].tabstop     = 4
    vim.bo[ev.buf].shiftwidth  = 4
    vim.bo[ev.buf].softtabstop = 4
    vim.b[ev.buf].autoformat   = false
  end,
})

-- ── Java: refresh codelens on save ───────────────────────────────────────────

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern  = { "*.java" },
  callback = function()
    pcall(vim.lsp.codelens.refresh)
  end,
})

-- ── nvim-jdtls: suppress "Invalid buffer id" errors ─────────────────────────
-- jdtls occasionally fires LSP callbacks (e.g. workspace/executeClientCommand)
-- referencing buffers that were already closed. Patch the global LSP handler
-- to validate buffer ids before dispatching.
vim.api.nvim_create_autocmd("LspAttach", {
  pattern  = { "*.java" },
  once     = true,
  callback = function()
    local orig = vim.lsp.handlers["workspace/executeClientCommand"]
    if orig then
      vim.lsp.handlers["workspace/executeClientCommand"] = function(err, result, ctx, config)
        if ctx and ctx.bufnr and not vim.api.nvim_buf_is_valid(ctx.bufnr) then
          return  -- silently discard stale-buffer callbacks
        end
        return orig(err, result, ctx, config)
      end
    end
  end,
})

-- ── Salesforce / Apex filetype detection ─────────────────────────────────────

vim.filetype.add({
  pattern = {
    [".*%.cls"]  = "apex",
    [".*%.apex"] = "apex",
  },
})

-- ── Diff mode: buffer-local keymaps ──────────────────────────────────────────

local DIFF_KEYMAPS = { "]c", "[c", "<leader>dh", "<leader>dl", "<leader>dr", "<leader>dq", "<leader>d1", "<leader>d2", "<leader>d3" }

function _G.setup_diff_mappings()
  if not vim.wo.diff then return end
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].diff_keymaps_active then return end

  local helpers = require("command_helpers")
  local bmap = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  bmap("]c",           helpers.diff_jump_next,                  "Next change")
  bmap("[c",           helpers.diff_jump_prev,                  "Prev change")
  bmap("<leader>dh",   function() helpers.diffget_from_window(1) end, "Get from window 1")
  bmap("<leader>dl",   function() helpers.diffget_from_window(2) end, "Get from window 2")
  bmap("<leader>dr",   helpers.diff_refresh,                    "Refresh diff")
  bmap("<leader>dq",   helpers.diff_quit,                       "Quit diff")
  bmap("<leader>d1",   function() helpers.diff_goto_window(1) end, "Go to window 1")
  bmap("<leader>d2",   function() helpers.diff_goto_window(2) end, "Go to window 2")
  bmap("<leader>d3",   function() helpers.diff_goto_window(3) end, "Go to window 3")

  vim.b[bufnr].diff_keymaps_active = true
  vim.w.diff_prev_listchars = vim.opt_local.listchars:get()
  vim.wo.wrap            = false
  vim.wo.number          = true
  vim.wo.relativenumber  = true
  vim.wo.signcolumn      = "yes"
  vim.opt_local.listchars = { tab = "▸ ", trail = "·", extends = "›", precedes = "‹", nbsp = "␣" }

  -- Ensure syntax highlighting is enabled in diff mode
  pcall(vim.treesitter.start, bufnr)
  vim.cmd("syntax enable")
end

function _G.cleanup_diff_mappings(bufnr)
  local target_buf = bufnr or vim.api.nvim_get_current_buf()

  if vim.b[target_buf] and vim.b[target_buf].diff_keymaps_active then
    for _, lhs in ipairs(DIFF_KEYMAPS) do
      pcall(vim.keymap.del, "n", lhs, { buffer = target_buf })
    end
    vim.b[target_buf].diff_keymaps_active = false
  end

  vim.opt.scrollbind    = false
  vim.opt.cursorbind    = false
  -- Only restore relativenumber for normal file buffers; skip special buftype
  -- windows (dap-view, terminal, quickfix, etc.) that manage their own options.
  if vim.bo[target_buf].buftype == "" then
    vim.wo.relativenumber = true
  end
  vim.wo.signcolumn     = nil
  if vim.w.diff_prev_listchars ~= nil then
    vim.opt_local.listchars = vim.w.diff_prev_listchars
    vim.w.diff_prev_listchars = nil
  end
end

-- Ensure diff keymaps/options are always applied in diff windows
local function setup_current_diff_window()
  if not vim.wo.diff then return end
  vim.wo.scrollbind = true
  vim.wo.cursorbind = true
  if _G.setup_diff_mappings then _G.setup_diff_mappings() end

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.b[bufnr].diff_lsp_forced then
    disable_lsp_for_diff_buffer(bufnr)
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("diff_window_setup", { clear = true }),
  callback = function()
    if vim.wo.diff then
      setup_current_diff_window()
    else
      if _G.cleanup_diff_mappings then _G.cleanup_diff_mappings() end
    end
  end,
})

vim.api.nvim_create_user_command("DiffLspEnable", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.b[bufnr].diff_lsp_forced = true
  vim.b[bufnr].diff_lsp_disabled = false
  set_buffer_diagnostics(bufnr, true)
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

-- ── Git: line history viewer (uses delta pager if available) ─────────────────

vim.api.nvim_create_user_command("GitLineHistory", function(opts)
  local s, e  = opts.line1, opts.line2
  local spec  = string.format("%d,%d:%s", s, e, vim.fn.expand("%:p"))
  local cmd   = "git -c core.pager=delta"
    .. " -c delta.paging=never"
    .. " -c delta.line-numbers=true"
    .. " -c delta.side-by-side=false"
    .. " log --color=always -p -L "
    .. vim.fn.shellescape(spec)
  vim.cmd("vsplit")
  vim.cmd("terminal " .. cmd)
end, { range = true, desc = "Git line history with delta" })

-- ── Diff context helpers ──────────────────────────────────────────────────────

vim.api.nvim_create_user_command("DiffContextZero", function()
  vim.opt.diffopt:remove("context:999999")
  vim.opt.diffopt:append("context:0")
end, { desc = "Set diff context to 0 lines" })

vim.api.nvim_create_user_command("DiffContextAll", function()
  vim.opt.diffopt:remove("context:0")
  vim.opt.diffopt:append("context:999999")
end, { desc = "Set diff context to all lines" })

-- WinBar highlight groups set by catppuccin (WinBar, WinBarNC,
-- WinBarPath, WinBarSep, WinBarFile, WinBarMod).

-- ── Zellij: return to normal mode on exit ────────────────────────────────────

vim.api.nvim_create_autocmd("VimLeave", {
  pattern  = "*",
  command  = "silent !zellij action switch-mode normal",
})

-- ── Huge non-code file profile (targeted filetypes) ───────────────────────────

local HUGE_TEXT_FILETYPES = {
  text = true,
  txt = true,
  conf = true,
  dosini = true,
  jproperties = true,
  properties = true,
  json = true,
  jsonc = true,
}

local function is_target_huge_text_file(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end

  local ft = vim.bo[bufnr].filetype
  if not HUGE_TEXT_FILETYPES[ft] then return false end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then return false end

  local size = vim.fn.getfsize(path)
  return size > HUGE_FILE_THRESHOLD
end

local function apply_huge_text_profile(bufnr)
  if vim.b[bufnr].huge_text_profile_active then return end

  pcall(vim.treesitter.stop, bufnr)
  set_buffer_diagnostics(bufnr, false)
  detach_all_lsp_clients(bufnr)

  set_number_options_for_buf(bufnr, true, true)
  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldexpr = "0"
  vim.opt_local.foldenable = false
  vim.opt_local.synmaxcol = 120
  vim.opt_local.wrap = false
  vim.opt_local.wrapscan = false
  vim.opt_local.list = false
  vim.opt_local.cursorline = false

  vim.bo[bufnr].undolevels = 100
  vim.bo[bufnr].undofile = false

  vim.opt.lazyredraw = true
  vim.opt.updatetime = 1000

  vim.b[bufnr].huge_text_profile_active = true

  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
  vim.notify(
    string.format("Huge file profile ON for %s (%.1fMB)", vim.bo[bufnr].filetype, size / 1000000),
    vim.log.levels.WARN
  )
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("huge_text_profile_apply", { clear = true }),
  callback = function(args)
    if is_target_huge_text_file(args.buf) then
      apply_huge_text_profile(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("huge_text_profile_restore", { clear = true }),
  callback = function(args)
    if not vim.b[args.buf].huge_text_profile_active then return end

    vim.opt.lazyredraw = false
    vim.opt.updatetime = 100
    set_number_options_for_buf(args.buf, true, true)
    vim.b[args.buf].huge_text_profile_active = false
  end,
})

-- ── Huge code file profile (keep LSP, reduce heavy rendering) ─────────────────

local HUGE_CODE_FILETYPES = {
  java = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  xml = true,
  yaml = true,
  yml = true,
  sh = true,
  bash = true,
  zsh = true,
  apex = true,
  html = true, -- LWC templates
  sql = true,
  soql = true,
}

local function is_target_huge_code_file(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end

  local ft = vim.bo[bufnr].filetype
  if not HUGE_CODE_FILETYPES[ft] then return false end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then return false end

  local size = vim.fn.getfsize(path)
  return size > HUGE_FILE_THRESHOLD
end

local function apply_huge_code_profile(bufnr)
  if vim.b[bufnr].huge_code_profile_active then return end

  -- Keep LSP/diagnostics attached for coding, but disable heavy syntax engines.
  pcall(vim.treesitter.stop, bufnr)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
  end

  set_number_options_for_buf(bufnr, true, true)
  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldexpr = "0"
  vim.opt_local.foldenable = false
  vim.opt_local.synmaxcol = 120
  vim.opt_local.wrap = false
  vim.opt_local.wrapscan = false
  vim.opt_local.list = false
  vim.opt_local.cursorline = false

  vim.bo[bufnr].undolevels = 300

  vim.opt.lazyredraw = true
  vim.opt.updatetime = 800

  vim.b[bufnr].huge_code_profile_active = true

  local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
  vim.notify(
    string.format("Huge code profile ON for %s (%.1fMB) — LSP kept active", vim.bo[bufnr].filetype, size / 1000000),
    vim.log.levels.WARN
  )
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("huge_code_profile_apply", { clear = true }),
  callback = function(args)
    if is_target_huge_code_file(args.buf) then
      apply_huge_code_profile(args.buf)
    end
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = vim.api.nvim_create_augroup("huge_code_profile_restore", { clear = true }),
  callback = function(args)
    if not vim.b[args.buf].huge_code_profile_active then return end

    vim.opt.lazyredraw = false
    vim.opt.updatetime = 100
    set_number_options_for_buf(args.buf, true, true)
    vim.b[args.buf].huge_code_profile_active = false
  end,
})

-- ── JSON in diff mode: aggressive optimizations ──────────────────────────────────

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("json_diff_optimize", { clear = true }),
  callback = function()
    if vim.bo.filetype == "json" and vim.wo.diff then
      local file_size = vim.fn.getfsize(vim.fn.expand("%"))

      if file_size > HUGE_FILE_THRESHOLD then
        -- En diff mode, JSON grande = read-only mode
        vim.bo.modifiable = false
        vim.bo.readonly = true

        -- No syntax highlighting (demasiado lento)
        pcall(vim.treesitter.stop, 0)
        vim.cmd("syntax off")

        -- Minimal rendering
        vim.opt.lazyredraw = true
        vim.opt.updatetime = 2000
        vim.opt.redrawtime = 10000
        vim.wo.number = false
        vim.wo.relativenumber = false

        detach_all_lsp_clients(0)

        vim.notify("JSON en diff mode optimizado (read-only)", vim.log.levels.WARN)
      end
    end
  end,
})

-- ── JSON Performance: Manual toggle for syntax/LSP ──────────────────────────────

vim.api.nvim_create_user_command("JsonOptimizeOn", function()
  vim.opt.lazyredraw = true
  vim.opt.updatetime = 2000
  pcall(vim.treesitter.stop, 0)
  vim.cmd("syntax off")
  detach_all_lsp_clients(0)
  set_buffer_diagnostics(0, false)
  vim.notify("JSON optimizations ON (read-only)", vim.log.levels.INFO)
end, { desc = "Disable highlighting/LSP for large JSON" })

vim.api.nvim_create_user_command("JsonOptimizeOff", function()
  vim.opt.lazyredraw = false
  vim.opt.updatetime = 100
  pcall(vim.treesitter.start, 0)
  vim.cmd("syntax on")
  detach_all_lsp_clients(0)
  set_buffer_diagnostics(0, true)
  vim.notify("JSON optimizations OFF", vim.log.levels.INFO)
end, { desc = "Re-enable highlighting/LSP for JSON" })

-- ── Diff Mode Configuration ───────────────────────────────────────────────────
-- Detects if Neovim was launched in diff mode (nvim diff, git mergetool, etc)
-- In diff mode: detach active LSP clients and keep view minimal
-- Outside diff mode: normal LSP configuration applies

local function setup_diff_mode()
  if not vim.opt.diff:get() then return end

  vim.notify("Entering diff mode", vim.log.levels.INFO)

  -- Detach all LSPs from all buffers
  for _, client in ipairs(vim.lsp.get_clients()) do
    local buffers = vim.lsp.get_buffers_by_client_id(client.id)
    for _, bufnr in ipairs(buffers) do
      vim.lsp.buf_detach_client(bufnr, client.id)
    end
  end

  -- Disable treesitter highlighting for cleaner diffs
  pcall(vim.treesitter.stop)
  vim.cmd("set number")
  vim.cmd("set colorcolumn=")

  -- Make diff view minimal
  vim.opt_local.foldmethod = "diff"
  vim.opt_local.foldenable = true
  vim.opt_local.foldlevel = 0
end

-- Run on UIEnter to catch diff mode before LSP initialization
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("DiffMode", { clear = true }),
  once = true,
  callback = function()
    setup_diff_mode()
  end,
})
