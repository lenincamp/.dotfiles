local M = {}

local lsp_buffer = require("modules.lsp.buffer")

-- ── Global option overrides ─────────────────────────────────────────────────

local baseline
local overrides = {}

local function ensure_baseline()
  if baseline then
    return
  end

  baseline = {
    lazyredraw = vim.o.lazyredraw,
    updatetime = vim.o.updatetime,
    redrawtime = vim.o.redrawtime,
  }
end

local function recompute_options()
  ensure_baseline()

  local lazyredraw = baseline.lazyredraw
  local updatetime = baseline.updatetime
  local redrawtime = baseline.redrawtime

  for _, opts in pairs(overrides) do
    if opts.lazyredraw ~= nil then
      lazyredraw = lazyredraw or opts.lazyredraw
    end
    if type(opts.updatetime) == "number" then
      updatetime = math.max(updatetime, opts.updatetime)
    end
    if type(opts.redrawtime) == "number" then
      redrawtime = math.max(redrawtime, opts.redrawtime)
    end
  end

  vim.o.lazyredraw = lazyredraw
  vim.o.updatetime = updatetime
  vim.o.redrawtime = redrawtime
end

local function set_override(key, opts)
  if type(key) ~= "string" or key == "" then
    return
  end

  overrides[key] = opts or {}
  recompute_options()
end

local function clear_override_key(key)
  overrides[key] = nil
  recompute_options()
end

-- ── Profiles ────────────────────────────────────────────────────────────────

local HUGE_FILE_THRESHOLD = 2500000

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
  html = true,
  sql = true,
  soql = true,
}

local function set_number_options(bufnr, number, relativenumber)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].number = number
      vim.wo[win].relativenumber = relativenumber
    end
  end
end

local function file_size(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return path ~= "" and vim.fn.getfsize(path) or -1
end

local function apply_large_buffer_rendering(bufnr)
  set_number_options(bufnr, true, true)
  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldexpr = "0"
  vim.opt_local.foldenable = false
  vim.opt_local.synmaxcol = 120
  vim.opt_local.wrap = false
  vim.opt_local.wrapscan = false
  vim.opt_local.list = false
  vim.opt_local.cursorline = false
end

local function is_huge_text(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if not HUGE_TEXT_FILETYPES[vim.bo[bufnr].filetype] then return false end
  return file_size(bufnr) > HUGE_FILE_THRESHOLD
end

local function is_huge_code(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if not HUGE_CODE_FILETYPES[vim.bo[bufnr].filetype] then return false end
  return file_size(bufnr) > HUGE_FILE_THRESHOLD
end

local function clear_buf_override(bufnr, variable)
  local key = vim.b[bufnr][variable]
  if key then
    clear_override_key(key)
    vim.b[bufnr][variable] = nil
  end
end

local function apply_json_large(bufnr)
  local size = file_size(bufnr)
  if size <= HUGE_FILE_THRESHOLD then
    return
  end

  pcall(vim.treesitter.stop, bufnr)
  apply_large_buffer_rendering(bufnr)
  lsp_buffer.detach_all(bufnr)
  lsp_buffer.set_diagnostics(bufnr, false)

  local override_key = "json_large:" .. bufnr
  vim.b[bufnr].json_large_global_override_key = override_key
  set_override(override_key, {
    lazyredraw = true,
    updatetime = 1500,
    redrawtime = 5000,
  })

  vim.bo[bufnr].undolevels = 0
  vim.bo[bufnr].undofile = false

  vim.notify(
    string.format("JSON grande detectado (%.1fMB) — fast search activo (<leader>/)", size / 1000000),
    vim.log.levels.WARN
  )
end

local function apply_huge_text(bufnr)
  if vim.b[bufnr].huge_text_profile_active then return end

  local override_key = "huge_text:" .. bufnr
  vim.b[bufnr].huge_text_global_override_key = override_key

  pcall(vim.treesitter.stop, bufnr)
  lsp_buffer.set_diagnostics(bufnr, false)
  lsp_buffer.detach_all(bufnr)
  apply_large_buffer_rendering(bufnr)

  vim.bo[bufnr].undolevels = 100
  vim.bo[bufnr].undofile = false

  set_override(override_key, {
    lazyredraw = true,
    updatetime = 1000,
  })

  vim.b[bufnr].huge_text_profile_active = true

  vim.notify(
    string.format("Huge file profile ON for %s (%.1fMB)", vim.bo[bufnr].filetype, file_size(bufnr) / 1000000),
    vim.log.levels.WARN
  )
end

local function apply_huge_code(bufnr)
  if vim.b[bufnr].huge_code_profile_active then return end

  local override_key = "huge_code:" .. bufnr
  vim.b[bufnr].huge_code_global_override_key = override_key

  pcall(vim.treesitter.stop, bufnr)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
  end

  apply_large_buffer_rendering(bufnr)
  vim.bo[bufnr].undolevels = 300

  set_override(override_key, {
    lazyredraw = true,
    updatetime = 800,
  })

  vim.b[bufnr].huge_code_profile_active = true

  vim.notify(
    string.format("Huge code profile ON for %s (%.1fMB) — LSP kept active", vim.bo[bufnr].filetype, file_size(bufnr) / 1000000),
    vim.log.levels.WARN
  )
end

local function apply_json_diff(bufnr)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true
  pcall(vim.treesitter.stop, bufnr)
  vim.cmd("syntax off")

  local override_key = "json_diff:" .. bufnr
  vim.b[bufnr].json_diff_global_override_key = override_key
  set_override(override_key, {
    lazyredraw = true,
    updatetime = 2000,
    redrawtime = 10000,
  })
  vim.wo.number = false
  vim.wo.relativenumber = false

  lsp_buffer.detach_all(0)

  vim.notify("JSON en diff mode optimizado (read-only)", vim.log.levels.WARN)
end

local function json_manual_on()
  set_override("json_optimize_manual", {
    lazyredraw = true,
    updatetime = 2000,
  })
  pcall(vim.treesitter.stop, 0)
  vim.cmd("syntax off")
  lsp_buffer.detach_all(0)
  lsp_buffer.set_diagnostics(0, false)
  vim.notify("JSON optimizations ON (read-only)", vim.log.levels.INFO)
end

local function json_manual_off()
  clear_override_key("json_optimize_manual")
  pcall(vim.treesitter.start, 0)
  vim.cmd("syntax on")
  lsp_buffer.detach_all(0)
  lsp_buffer.set_diagnostics(0, true)
  vim.notify("JSON optimizations OFF", vim.log.levels.INFO)
end

-- ── Autocmd setup ───────────────────────────────────────────────────────────

local function setup_json_filetype()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "json", "jsonc" },
    group = vim.api.nvim_create_augroup("json_large_file", { clear = true }),
    callback = function(ev)
      vim.wo.spell = false
      vim.wo.conceallevel = 0
      vim.bo[ev.buf].tabstop = 2
      vim.bo[ev.buf].shiftwidth = 2
      vim.bo[ev.buf].softtabstop = 2
      vim.b[ev.buf].autoformat = false

      apply_json_large(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("json_large_file_restore", { clear = true }),
    callback = function(args)
      clear_buf_override(args.buf, "json_large_global_override_key")
    end,
  })
end

local function setup_huge_text_profile()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("huge_text_profile_apply", { clear = true }),
    callback = function(args)
      if is_huge_text(args.buf) then
        apply_huge_text(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("huge_text_profile_restore", { clear = true }),
    callback = function(args)
      if not vim.b[args.buf].huge_text_profile_active then return end

      clear_buf_override(args.buf, "huge_text_global_override_key")
      set_number_options(args.buf, true, true)
      vim.b[args.buf].huge_text_profile_active = false
    end,
  })
end

local function setup_huge_code_profile()
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("huge_code_profile_apply", { clear = true }),
    callback = function(args)
      if is_huge_code(args.buf) then
        apply_huge_code(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("huge_code_profile_restore", { clear = true }),
    callback = function(args)
      if not vim.b[args.buf].huge_code_profile_active then return end

      clear_buf_override(args.buf, "huge_code_global_override_key")
      set_number_options(args.buf, true, true)
      vim.b[args.buf].huge_code_profile_active = false
    end,
  })
end

local function setup_json_diff_profile()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("json_diff_optimize", { clear = true }),
    callback = function()
      if vim.bo.filetype ~= "json" or not vim.wo.diff then
        return
      end

      if vim.fn.getfsize(vim.fn.expand("%")) <= HUGE_FILE_THRESHOLD then
        return
      end

      apply_json_diff(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("json_diff_optimize_restore", { clear = true }),
    callback = function(args)
      clear_buf_override(args.buf, "json_diff_global_override_key")
    end,
  })
end

local function setup_json_commands()
  vim.api.nvim_create_user_command("JsonOptimizeOn", function()
    json_manual_on()
  end, { desc = "Disable highlighting/LSP for large JSON" })

  vim.api.nvim_create_user_command("JsonOptimizeOff", function()
    json_manual_off()
  end, { desc = "Re-enable highlighting/LSP for JSON" })
end

local function setup_insert_redraw_restore()
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("insert_responsive_redraw", { clear = true }),
    callback = function()
      vim.o.lazyredraw = false
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = vim.api.nvim_create_augroup("insert_responsive_redraw_restore", { clear = true }),
    callback = function()
      recompute_options()
    end,
  })
end

function M.setup()
  setup_json_filetype()
  setup_huge_text_profile()
  setup_huge_code_profile()
  setup_json_diff_profile()
  setup_json_commands()
  setup_insert_redraw_restore()
end

return M