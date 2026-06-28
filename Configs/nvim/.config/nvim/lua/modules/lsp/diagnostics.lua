local M = {}

local diag_icons = { Error = "✘ ", Warn = "▲ ", Info = "● ", Hint = "◆ " }
local FLOAT_MAX_WIDTH = 100
local FLOAT_MIN_WIDTH = 36

local function get_diagnostic_api()
  local diagnostic = rawget(vim, "diagnostic")
  if type(diagnostic) == "table" then
    return diagnostic
  end

  local ok, resolved = pcall(function()
    return vim.diagnostic
  end)
  if ok and type(resolved) == "table" then
    return resolved
  end

  return nil
end

local function source_label(diag)
  local parts = {}
  if diag.source and diag.source ~= "" then
    parts[#parts + 1] = diag.source
  end
  if diag.code and diag.code ~= "" then
    parts[#parts + 1] = tostring(diag.code)
  end
  return table.concat(parts, " ")
end

local function wrap_text(text, width)
  local lines = {}
  for _, raw_line in ipairs(vim.split(tostring(text or ""), "\n", { plain = true })) do
    local line = vim.trim(raw_line)
    while vim.fn.strdisplaywidth(line) > width do
      local cut = width
      while cut > 20 and line:sub(cut, cut) ~= " " do
        cut = cut - 1
      end
      if cut <= 20 then
        cut = width
      end
      lines[#lines + 1] = vim.trim(line:sub(1, cut))
      line = vim.trim(line:sub(cut + 1))
    end
    lines[#lines + 1] = line
  end
  return table.concat(lines, "\n")
end

local function format_diagnostic(diag, width)
  local label = source_label(diag)
  local message = wrap_text(diag.message, width or FLOAT_MAX_WIDTH)
  if label ~= "" then
    return string.format("[%s]\n%s", label, message)
  end
  return message
end

local function float_options(diagnostic)
  local max_width = math.max(FLOAT_MIN_WIDTH, math.min(FLOAT_MAX_WIDTH, vim.o.columns - 8))
  return {
    border = "rounded",
    source = false,
    header = "Diagnostics",
    focusable = true,
    max_width = max_width + 4,
    max_height = math.max(6, vim.o.lines - 6),
    format = function(diag)
      return format_diagnostic(diag, max_width)
    end,
    prefix = function(diag)
      local severity_name = diagnostic.severity[diag.severity]
      local icon = diag_icons[severity_name] or "● "
      return icon, "DiagnosticSign" .. severity_name
    end,
  }
end

function M.open_float(opts)
  local diagnostic = get_diagnostic_api()
  if not diagnostic or type(diagnostic.open_float) ~= "function" then
    return
  end
  local ok = pcall(diagnostic.open_float, 0, vim.tbl_extend("force", float_options(diagnostic), opts or {}))
  if not ok then
    pcall(diagnostic.open_float, 0, vim.tbl_extend("force", float_options(diagnostic), {
      scope = "cursor",
      focusable = false,
      max_width = math.max(FLOAT_MIN_WIDTH, math.min(72, vim.o.columns - 8)),
    }))
  end
end

function M.setup()
  local diagnostic = get_diagnostic_api()
  if not diagnostic then
    return
  end

  diagnostic.config({
    signs = {
      text = {
        [diagnostic.severity.ERROR] = diag_icons.Error,
        [diagnostic.severity.WARN] = diag_icons.Warn,
        [diagnostic.severity.INFO] = diag_icons.Info,
        [diagnostic.severity.HINT] = diag_icons.Hint,
      },
    },
    virtual_text = {
      spacing = 2,
      source = "if_many",
      prefix = function(diag)
        local severity_name = diagnostic.severity[diag.severity]
        return diag_icons[severity_name] or "● "
      end,
    },
    virtual_lines = false,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = "rounded",
      source = false,
      header = "",
      format = function(diag)
        return format_diagnostic(diag, math.max(FLOAT_MIN_WIDTH, math.min(FLOAT_MAX_WIDTH, vim.o.columns - 8)))
      end,
      prefix = function(diag)
        local severity_name = diagnostic.severity[diag.severity]
        local icon = diag_icons[severity_name] or "● "
        return icon, "DiagnosticSign" .. severity_name
      end,
    },
  })
end

return M
