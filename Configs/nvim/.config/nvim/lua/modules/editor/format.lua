local M = {}

local formatter_by_ft = {
  lua = {
    { cmd = { "stylua", "--search-parent-directories", "--stdin-filepath", "$FILENAME", "-" }, stdin = true },
  },
  javascript = {
    { cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" }, stdin = true },
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  typescript = {
    { cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" }, stdin = true },
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  javascriptreact = {
    { cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" }, stdin = true },
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  typescriptreact = {
    { cmd = { "eslint_d", "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" }, stdin = true },
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  html = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  css = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  scss = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  json = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  markdown = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  apex = {
    { cmd = { "prettier", "--stdin-filepath", "$FILENAME" }, stdin = true },
  },
  sh = {
    { cmd = { "shfmt", "-filename", "$FILENAME" }, stdin = true },
  },
  bash = {
    { cmd = { "shfmt", "-filename", "$FILENAME" }, stdin = true },
  },
  zsh = {
    { cmd = { "shfmt", "-ln", "bash", "-filename", "$FILENAME" }, stdin = true },
  },
  sql = {
    { cmd = { "sqlfluff", "format", "--disable-progress-bar", "-" }, stdin = true },
  },
  kotlin = {
    { cmd = { "ktlint", "--format", "--stdin" }, stdin = true },
  },
}

local lsp_only_filetypes = {
  java = true,
  xml = true,
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Format" })
end

local function expand_command(command, filename)
  local expanded = {}
  for _, part in ipairs(command) do
    expanded[#expanded + 1] = part == "$FILENAME" and filename or part
  end
  return expanded
end

local function buffer_text(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
end

local function set_buffer_text(bufnr, text)
  local lines = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  pcall(vim.fn.winrestview, view)
end

local function run_formatter(bufnr, formatter)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local command = expand_command(formatter.cmd, filename)
  if vim.fn.executable(command[1]) ~= 1 then
    return false, command[1] .. " not executable"
  end

  local result = vim.system(command, {
    stdin = formatter.stdin and buffer_text(bufnr) or nil,
    text = true,
  }):wait()

  if result.code ~= 0 then
    local error_output = vim.trim(result.stderr or result.stdout or "")
    return false, error_output ~= "" and error_output or (command[1] .. " failed")
  end

  if formatter.stdin and result.stdout and result.stdout ~= "" then
    set_buffer_text(bufnr, result.stdout)
  end

  return true
end

local function lsp_format(bufnr)
  local ok = pcall(vim.lsp.buf.format, {
    bufnr = bufnr,
    timeout_ms = 3000,
  })
  return ok
end

function M.format(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local ft = vim.bo[bufnr].filetype
  local formatters = formatter_by_ft[ft] or {}
  local last_error = nil

  if not lsp_only_filetypes[ft] then
    for _, formatter in ipairs(formatters) do
      local ok, err = run_formatter(bufnr, formatter)
      if ok then
        return true
      end
      last_error = err
    end
  end

  if lsp_format(bufnr) then
    return true
  end

  if opts.notify ~= false and last_error then
    notify(last_error, vim.log.levels.WARN)
  end
  return false
end

function M.format_on_save(args)
  if vim.g.autoformat == false or vim.b[args.buf].autoformat == false or vim.opt.diff:get() then
    return
  end
  M.format({ bufnr = args.buf, notify = false })
end

return M
