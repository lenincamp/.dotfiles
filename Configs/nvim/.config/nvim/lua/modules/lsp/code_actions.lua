local M = {}

local group = vim.api.nvim_create_augroup("LspCodeActionLightbulb", { clear = true })
local sign_group = "lsp_code_action_lightbulb"
local sign_name = "LspCodeActionLightbulb"
local timers = {}
local versions = {}
local configured = false

local function close_timer(timer)
  if not timer then
    return
  end

  local ok, closing = pcall(timer.is_closing, timer)
  if ok and not closing then
    pcall(timer.stop, timer)
    pcall(timer.close, timer)
  end
end

local function supports_code_action(bufnr)
  local method = "textDocument/codeAction"
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    local ok, supported = pcall(function()
      return client:supports_method(method, bufnr)
    end)
    if ok and supported then
      return true
    end
  end
  return false
end

local function clear(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.fn.sign_unplace(sign_group, { buffer = bufnr })
  end
end

local function code_action_params(bufnr)
  local params = vim.lsp.util.make_range_params(0, "utf-16")
  params.context = {
    diagnostics = vim.diagnostic.get(bufnr, { lnum = params.range.start.line }),
    only = { "quickfix" },
  }
  return params
end

local function has_line_diagnostics(bufnr, line)
  return #vim.diagnostic.get(bufnr, { lnum = line - 1 }) > 0
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end
  if vim.api.nvim_get_current_buf() ~= bufnr then
    clear(bufnr)
    return
  end
  if vim.api.nvim_get_mode().mode:match("^i") then
    return
  end
  if not supports_code_action(bufnr) then
    clear(bufnr)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  if not has_line_diagnostics(bufnr, line) then
    clear(bufnr)
    return
  end

  versions[bufnr] = (versions[bufnr] or 0) + 1
  local version = versions[bufnr]

  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", code_action_params(bufnr), function(results)
    if versions[bufnr] ~= version or not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    local has_action = false
    for _, result in pairs(results or {}) do
      if type(result.result) == "table" and #result.result > 0 then
        has_action = true
        break
      end
    end

    clear(bufnr)
    if has_action then
      vim.fn.sign_place(0, sign_group, sign_name, bufnr, { lnum = line, priority = 4 })
    end
  end)
end

local function schedule(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if timers[bufnr] then
    close_timer(timers[bufnr])
  end

  local timer = vim.uv.new_timer()
  timers[bufnr] = timer
  timer:start(180, 0, vim.schedule_wrap(function()
    local current = timers[bufnr] == timer
    if current then timers[bufnr] = nil end
    close_timer(timer)
    if current then M.refresh(bufnr) end
  end))
end

function M.setup()
  if configured then return end
  configured = true

  vim.api.nvim_set_hl(0, "LspCodeActionLightbulb", { link = "DiagnosticHint", default = true })
  vim.fn.sign_define(sign_name, { text = "?", texthl = "LspCodeActionLightbulb", linehl = "", numhl = "" })

  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(args)
      schedule(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "LspDetach" }, {
    group = group,
    callback = function(args)
      clear(args.buf)
    end,
  })
end

return M