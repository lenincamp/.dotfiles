local M = {}

local parser = require("modules.editor.mybatis.parser")
local search = require("modules.editor.mybatis.search")

local ROOT_MARKERS = { ".git", "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "mvnw", "gradlew" }
local JAVA_GLOB = "*.java"
local JAVA_STATEMENT_LINE_RADIUS = 30
local JAVA_STATEMENT_MULTILINE_RADIUS = 8

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function line_at(lnum)
  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
end

local function top_lines(limit)
  local max_line = vim.api.nvim_buf_line_count(0)
  return vim.api.nvim_buf_get_lines(0, 0, math.min(max_line, limit), false)
end

function M.ensure_java_buffer()
  if vim.bo.filetype ~= "java" then
    notify("MyBatis: abre una clase/interfaz Java", vim.log.levels.WARN)
    return false
  end
  return true
end

function M.project_root()
  local filepath = vim.api.nvim_buf_get_name(0)
  local source = filepath ~= "" and filepath or vim.fn.getcwd()
  return vim.fs.root(source, ROOT_MARKERS) or vim.fn.getcwd()
end

function M.current_fqn()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return nil
  end

  local class_name = vim.fn.expand("%:t:r")
  if class_name == "" then
    return nil
  end

  local package_name
  for _, line in ipairs(top_lines(120)) do
    local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if pkg then
      package_name = pkg
      break
    end
  end

  if package_name and package_name ~= "" then
    return package_name .. "." .. class_name
  end

  return class_name
end

function M.statement_ref_near_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local max_line = vim.api.nvim_buf_line_count(0)

  for radius = 0, JAVA_STATEMENT_LINE_RADIUS do
    local up = row - radius
    local down = row + radius

    if up >= 1 then
      local namespace, statement_id = parser.statement_ref_from_text(line_at(up))
      if namespace and statement_id then
        return namespace, statement_id
      end
    end

    if radius > 0 and down <= max_line then
      local namespace, statement_id = parser.statement_ref_from_text(line_at(down))
      if namespace and statement_id then
        return namespace, statement_id
      end
    end
  end

  local start_line = math.max(1, row - JAVA_STATEMENT_MULTILINE_RADIUS)
  local end_line = math.min(max_line, row + JAVA_STATEMENT_MULTILINE_RADIUS)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  return parser.statement_ref_from_text(table.concat(lines, " "))
end

local function first_readable_file(paths)
  for _, path in ipairs(paths) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

local function find_java_file_by_simple_name(root, simple_name, package_path)
  local lower_target = simple_name:lower() .. ".java"
  local package_match

  for _, path in ipairs(search.rg_files(root, "**/*.java")) do
    if vim.fn.fnamemodify(path, ":t"):lower() == lower_target then
      if package_path and path:find("/" .. package_path .. "/", 1, true) then
        return path
      end
      if not package_match then
        package_match = path
      end
    end
  end

  return package_match
end

function M.find_file_for_namespace(namespace)
  namespace = parser.normalize_java_type_name(namespace)
  if not namespace then
    return nil
  end

  local root = M.project_root()
  local rel = namespace:gsub("%.", "/") .. ".java"

  local direct = first_readable_file({
    root .. "/src/main/java/" .. rel,
    root .. "/src/test/java/" .. rel,
  })
  if direct then
    return direct
  end

  local found = search.rg_files(root, "**/" .. rel)
  if #found > 0 then
    return found[1]
  end

  local simple_name = namespace:match("([%w_]+)$")
  if not simple_name or simple_name == "" then
    return nil
  end

  local package_name = namespace:match("^(.*)%.([%w_]+)$")
  local package_path = package_name and package_name:gsub("%.", "/") or nil

  return find_java_file_by_simple_name(root, simple_name, package_path)
end

function M.find_file_for_type(type_name)
  type_name = parser.normalize_java_type_name(type_name)
  if not type_name then
    return nil
  end

  if type_name:find(".", 1, true) then
    return M.find_file_for_namespace(type_name)
  end

  local simple_name = type_name:match("([%w_]+)$")
  if not simple_name or simple_name == "" then
    return nil
  end

  local root = M.project_root()
  local by_name = search.rg_files(root, "**/" .. simple_name .. ".java")
  if #by_name > 0 then
    return by_name[1]
  end

  return find_java_file_by_simple_name(root, simple_name)
end

function M.find_usages_for_statement(namespace, method)
  namespace = parser.normalize_java_type_name(namespace)
  if not namespace or not method or method == "" then
    return {}
  end

  local token = namespace .. "." .. method
  local lines = search.rg_vimgrep(token, M.project_root(), {
    glob = JAVA_GLOB,
    fixed_strings = true,
  })

  return search.parse_vimgrep_lines(lines)
end

function M.find_usage_for_statement(namespace, method)
  local items = M.find_usages_for_statement(namespace, method)
  return parser.best_java_usage_match(items, (parser.normalize_java_type_name(namespace) or "") .. "." .. method, method)
end

function M.find_method_declaration(path, method)
  if not path or path == "" or not method or method == "" then
    return nil
  end

  local escaped = parser.regex_escape(method)
  local lines = search.rg_vimgrep("\\b" .. escaped .. "\\s*\\(", path)
  return search.first_vimgrep_item(lines)
end

function M.jump_to_method_from_line(method, lnum)
  if not method or method == "" then
    return false
  end

  local escaped = vim.fn.escape(method, "\\")
  local pattern = "\\<" .. escaped .. "\\>\\_s*("

  if lnum and lnum > 0 then
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end

  local found = vim.fn.search(pattern, "bW")
  if found ~= 0 then
    return true
  end

  return vim.fn.search(pattern, "W") ~= 0
end

return M
