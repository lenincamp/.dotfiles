local M = {}

local parser = require("modules.editor.mybatis.parser")

local STATEMENT_TAG_NAMES = { "select", "insert", "update", "delete" }
local XML_SCAN_RADIUS = 120
local XML_OPEN_TAG_LOOKAHEAD = 20

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function cursor_col_1()
  return vim.api.nvim_win_get_cursor(0)[2] + 1
end

local function line_at(lnum)
  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
end

local function top_lines(limit)
  local max_line = vim.api.nvim_buf_line_count(0)
  return vim.api.nvim_buf_get_lines(0, 0, math.min(max_line, limit), false)
end

function M.is_xml_like_filetype()
  local ft = vim.bo.filetype
  return ft == "xml" or ft == "mybatis"
end

function M.ensure_xml_buffer()
  if not M.is_xml_like_filetype() then
    notify("MyBatis: abre un mapper XML", vim.log.levels.WARN)
    return false
  end
  return true
end

function M.current_mapper_namespace()
  for _, line in ipairs(top_lines(240)) do
    if line:find("<mapper", 1, true) then
      local namespace = line:match("namespace%s*=%s*['\"]([%w_%.]+)['\"]")
      if namespace then
        return namespace
      end
    end
  end
  return nil
end

local function is_statement_open_line(line)
  for _, tag in ipairs(STATEMENT_TAG_NAMES) do
    if line:find("<" .. tag, 1, true) then
      return true
    end
  end
  return false
end

local function is_statement_close_line(line)
  for _, tag in ipairs(STATEMENT_TAG_NAMES) do
    if line:find("</" .. tag .. ">", 1, true) then
      return true
    end
  end
  return false
end

local function statement_open_fragment_near_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local max_line = vim.api.nvim_buf_line_count(0)

  local function fragment_from(lnum)
    local parts = {}
    for index = lnum, math.min(max_line, lnum + XML_OPEN_TAG_LOOKAHEAD) do
      local line = line_at(index)
      table.insert(parts, line)
      if line:find(">", 1, true) then
        break
      end
    end
    return table.concat(parts, " ")
  end

  for lnum = row, math.max(1, row - XML_SCAN_RADIUS), -1 do
    local line = line_at(lnum)
    if is_statement_close_line(line) then
      break
    end
    if is_statement_open_line(line) then
      return fragment_from(lnum)
    end
  end

  for lnum = row, math.min(max_line, row + XML_SCAN_RADIUS) do
    local line = line_at(lnum)
    if is_statement_open_line(line) then
      return fragment_from(lnum)
    end
  end

  return nil
end

local function statement_attr_near_cursor(attr)
  local fragment = statement_open_fragment_near_cursor()
  if not fragment then
    return nil
  end
  return fragment:match(attr .. "%s*=%s*['\"]([^'\"]+)['\"]")
end

function M.current_mapper_statement_id()
  return statement_attr_near_cursor("id")
end

function M.current_mapper_parameter_type()
  return statement_attr_near_cursor("parameterType")
end

function M.attr_under_cursor()
  local line = line_at(vim.api.nvim_win_get_cursor(0)[1])
  local col = cursor_col_1()
  local init = 1

  while init <= #line do
    local start_pos, end_pos, attr, _, value_start, value, value_end = line:find("([%w_:-]+)%s*=%s*(['\"])()([^'\"]*)()", init)
    if not start_pos then
      break
    end

    if col >= start_pos and col <= end_pos then
      return attr, value, col >= value_start and col < value_end
    end

    init = end_pos + 1
  end

  return nil, nil, false
end

function M.java_type_under_cursor()
  local attr, value, on_value = M.attr_under_cursor()
  if not attr or not value or not on_value then
    return nil
  end

  local java_type_attrs = {
    parameterType = true,
    resultType = true,
    javaType = true,
    ofType = true,
    type = true,
  }

  if java_type_attrs[attr] then
    return parser.normalize_java_type_name(value)
  end

  return nil
end

return M
