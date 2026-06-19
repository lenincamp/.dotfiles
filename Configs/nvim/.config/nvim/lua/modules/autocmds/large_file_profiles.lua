local M = {}

local lsp_core = require("modules.core.lsp")
local large_file_options = require("modules.autocmds.large_file_options")

M.HUGE_FILE_THRESHOLD = 2500000

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

function M.set_number_options(bufnr, number, relativenumber)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].number = number
      vim.wo[win].relativenumber = relativenumber
    end
  end
end

function M.file_size(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  return path ~= "" and vim.fn.getfsize(path) or -1
end

function M.apply_large_buffer_rendering(bufnr)
  M.set_number_options(bufnr, true, true)
  vim.opt_local.foldmethod = "manual"
  vim.opt_local.foldexpr = "0"
  vim.opt_local.foldenable = false
  vim.opt_local.synmaxcol = 120
  vim.opt_local.wrap = false
  vim.opt_local.wrapscan = false
  vim.opt_local.list = false
  vim.opt_local.cursorline = false
end

function M.is_huge_text(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if not HUGE_TEXT_FILETYPES[vim.bo[bufnr].filetype] then return false end
  return M.file_size(bufnr) > M.HUGE_FILE_THRESHOLD
end

function M.is_huge_code(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if not HUGE_CODE_FILETYPES[vim.bo[bufnr].filetype] then return false end
  return M.file_size(bufnr) > M.HUGE_FILE_THRESHOLD
end

function M.clear_override(bufnr, variable)
  local key = vim.b[bufnr][variable]
  if key then
    large_file_options.clear(key)
    vim.b[bufnr][variable] = nil
  end
end

function M.apply_json_large(bufnr)
  local size = M.file_size(bufnr)
  if size <= M.HUGE_FILE_THRESHOLD then
    return
  end

  pcall(vim.treesitter.stop, bufnr)
  M.apply_large_buffer_rendering(bufnr)
  lsp_core.detach_all(bufnr)
  lsp_core.set_diagnostics(bufnr, false)

  local override_key = "json_large:" .. bufnr
  vim.b[bufnr].json_large_global_override_key = override_key
  large_file_options.set(override_key, {
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

function M.apply_huge_text(bufnr)
  if vim.b[bufnr].huge_text_profile_active then return end

  local override_key = "huge_text:" .. bufnr
  vim.b[bufnr].huge_text_global_override_key = override_key

  pcall(vim.treesitter.stop, bufnr)
  lsp_core.set_diagnostics(bufnr, false)
  lsp_core.detach_all(bufnr)
  M.apply_large_buffer_rendering(bufnr)

  vim.bo[bufnr].undolevels = 100
  vim.bo[bufnr].undofile = false

  large_file_options.set(override_key, {
    lazyredraw = true,
    updatetime = 1000,
  })

  vim.b[bufnr].huge_text_profile_active = true

  vim.notify(
    string.format("Huge file profile ON for %s (%.1fMB)", vim.bo[bufnr].filetype, M.file_size(bufnr) / 1000000),
    vim.log.levels.WARN
  )
end

function M.apply_huge_code(bufnr)
  if vim.b[bufnr].huge_code_profile_active then return end

  local override_key = "huge_code:" .. bufnr
  vim.b[bufnr].huge_code_global_override_key = override_key

  pcall(vim.treesitter.stop, bufnr)
  if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
    pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
  end

  M.apply_large_buffer_rendering(bufnr)
  vim.bo[bufnr].undolevels = 300

  large_file_options.set(override_key, {
    lazyredraw = true,
    updatetime = 800,
  })

  vim.b[bufnr].huge_code_profile_active = true

  vim.notify(
    string.format("Huge code profile ON for %s (%.1fMB) — LSP kept active", vim.bo[bufnr].filetype, M.file_size(bufnr) / 1000000),
    vim.log.levels.WARN
  )
end

function M.apply_json_diff(bufnr)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true
  pcall(vim.treesitter.stop, bufnr)
  vim.cmd("syntax off")

  local override_key = "json_diff:" .. bufnr
  vim.b[bufnr].json_diff_global_override_key = override_key
  large_file_options.set(override_key, {
    lazyredraw = true,
    updatetime = 2000,
    redrawtime = 10000,
  })
  vim.wo.number = false
  vim.wo.relativenumber = false

  lsp_core.detach_all(0)

  vim.notify("JSON en diff mode optimizado (read-only)", vim.log.levels.WARN)
end

function M.json_manual_on()
  large_file_options.set("json_optimize_manual", {
    lazyredraw = true,
    updatetime = 2000,
  })
  pcall(vim.treesitter.stop, 0)
  vim.cmd("syntax off")
  lsp_core.detach_all(0)
  lsp_core.set_diagnostics(0, false)
  vim.notify("JSON optimizations ON (read-only)", vim.log.levels.INFO)
end

function M.json_manual_off()
  large_file_options.clear("json_optimize_manual")
  pcall(vim.treesitter.start, 0)
  vim.cmd("syntax on")
  lsp_core.detach_all(0)
  lsp_core.set_diagnostics(0, true)
  vim.notify("JSON optimizations OFF", vim.log.levels.INFO)
end

return M
