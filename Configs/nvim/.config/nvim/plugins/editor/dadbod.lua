vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod-ui"

if not vim.env.GODEBUG or not vim.env.GODEBUG:find("x509negativeserial=1", 1, true) then
  vim.env.GODEBUG = vim.env.GODEBUG and (vim.env.GODEBUG .. ",x509negativeserial=1") or "x509negativeserial=1"
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    vim.bo.omnifunc = "vim_dadbod_completion#omni"
  end,
})

local max_sqlserver_column_width = 48

local function display_width(value)
  return vim.fn.strdisplaywidth(value)
end

local function truncate(value, width)
  if display_width(value) <= width then
    return value
  end

  return vim.fn.strcharpart(value, 0, width - 1) .. "~"
end

local function pad(value, width)
  return value .. string.rep(" ", math.max(width - display_width(value), 0))
end

local function separator_spans(line)
  if line:find("[^%-%s]") or not line:find("%-%s+%-") then
    return nil
  end

  local spans = {}
  for from, to in line:gmatch("()%-+()") do
    spans[#spans + 1] = { from = from, to = to - 1 }
  end

  return #spans > 1 and spans or nil
end

local function cells_from_line(line, spans)
  local cells = {}
  for index, span in ipairs(spans) do
    local to = index == #spans and #line or span.to
    cells[#cells + 1] = vim.trim(line:sub(span.from, to))
  end
  return cells
end

local function render_table(rows)
  local widths = {}
  for _, row in ipairs(rows) do
    for index, value in ipairs(row) do
      widths[index] = math.min(math.max(widths[index] or 0, display_width(value)), max_sqlserver_column_width)
    end
  end

  local rendered = {}
  for row_index, row in ipairs(rows) do
    local cells = {}
    for index, value in ipairs(row) do
      cells[#cells + 1] = pad(truncate(value, widths[index]), widths[index])
    end
    rendered[#rendered + 1] = table.concat(cells, " | ")

    if row_index == 1 then
      local separators = {}
      for _, width in ipairs(widths) do
        separators[#separators + 1] = string.rep("-", width)
      end
      rendered[#rendered + 1] = table.concat(separators, "-+-")
    end
  end

  return rendered
end

local function compact_sqlserver_dbout(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local db = vim.b[bufnr].db
  if type(db) ~= "table" or type(db.db_url) ~= "string" or not db.db_url:match("^sqlserver:") then
    if not opts.silent then
      vim.notify("Dadbod compact table only supports SQL Server .dbout buffers", vim.log.levels.WARN)
    end
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local output = {}
  local changed = false
  local index = 1

  while index <= #lines do
    local spans = lines[index + 1] and separator_spans(lines[index + 1])
    if spans then
      local rows = { cells_from_line(lines[index], spans) }
      index = index + 2

      while index <= #lines and lines[index] ~= "" and not lines[index]:match("^%(%d+ rows? affected%)") do
        rows[#rows + 1] = cells_from_line(lines[index], spans)
        index = index + 1
      end

      vim.list_extend(output, render_table(rows))
      changed = true
    else
      output[#output + 1] = lines[index]
      index = index + 1
    end
  end

  if not changed then
    if not opts.silent then
      vim.notify("No SQL Server table output found to compact", vim.log.levels.INFO)
    end
    return false
  end

  local was_modifiable = vim.bo[bufnr].modifiable
  local was_readonly = vim.bo[bufnr].readonly
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename ~= "" and filename:match("%.dbout$") then
    local ok, err = pcall(vim.fn.writefile, output, filename, "b")
    if not ok then
      if not opts.silent then
        vim.notify("Could not save compacted DB output: " .. tostring(err), vim.log.levels.WARN)
      end
      return false
    end
  end

  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].readonly = was_readonly
  vim.bo[bufnr].modifiable = was_modifiable
  return true
end

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*.dbout",
  callback = function(args)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        compact_sqlserver_dbout({ bufnr = args.buf, silent = true })
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function(args)
    vim.api.nvim_buf_create_user_command(args.buf, "DBCompactSqlServerTable", function()
      compact_sqlserver_dbout({ bufnr = args.buf })
    end, {})
    vim.keymap.set("n", "<leader>Dc", function()
      compact_sqlserver_dbout({ bufnr = args.buf })
    end, { buffer = args.buf, desc = "Dadbod: compact SQL Server table" })
  end,
})

local map = vim.keymap.set
map("n", "<leader>Du", "<cmd>DBUIToggle<CR>", { desc = "Dadbod: toggle UI" })
map("n", "<leader>Df", "<cmd>DBUIFindBuffer<CR>", { desc = "Dadbod: find buffer" })
map("n", "<leader>Da", "<cmd>DBUIAddConnection<CR>", { desc = "Dadbod: add connection" })
map("n", "<leader>Dr", "<cmd>DBUIRenameBuffer<CR>", { desc = "Dadbod: rename buffer" })
