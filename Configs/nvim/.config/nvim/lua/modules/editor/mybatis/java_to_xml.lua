local M = {}

local cursor = require("modules.editor.cursor")
local java_context = require("modules.editor.mybatis.java_context")
local locations = require("modules.editor.locations")
local parser = require("modules.editor.mybatis.parser")
local search = require("modules.editor.mybatis.search")

local SQLMAP_XML_GLOB = "*-sqlmap.xml"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function open_loclist(lines, title)
  if not lines or vim.tbl_isempty(lines) then
    return false
  end

  local items = search.parse_vimgrep_lines(lines)
  if vim.tbl_isempty(items) then
    return false
  end

  return locations.open_items_loclist(items, title, { open_single = true })
end

local function mapper_files_for_namespace(namespace)
  return search.rg_files_with_matches(parser.mapper_namespace_pattern(namespace), java_context.project_root(), SQLMAP_XML_GLOB)
end

function M.statement_for(namespace, statement_id, opts)
  opts = opts or {}

  if not namespace or namespace == "" or not statement_id or statement_id == "" then
    return false
  end

  local files = mapper_files_for_namespace(namespace)
  if #files == 0 then
    return false
  end

  local lines = search.rg_vimgrep(parser.statement_id_pattern(statement_id), files)
  if opts.peek then
    local item = search.first_vimgrep_item(lines)
    if not item then
      return false
    end

    return locations.open_or_peek(item, {
      peek = true,
      title = " MyBatis XML " .. statement_id .. " ",
    })
  end

  return open_loclist(lines, "MyBatis id: " .. statement_id)
end

function M.namespace(opts)
  opts = opts or {}

  if not java_context.ensure_java_buffer() then
    return
  end

  local fqn = java_context.current_fqn()
  if not fqn then
    notify("MyBatis: no pude inferir namespace Java", vim.log.levels.WARN)
    return
  end

  local lines = search.rg_vimgrep(parser.mapper_namespace_pattern(fqn), java_context.project_root(), {
    glob = SQLMAP_XML_GLOB,
  })

  if #lines == 0 then
    notify("MyBatis: no encontré mapper XML para " .. fqn, vim.log.levels.INFO)
    return
  end

  if opts.peek then
    local item = search.first_vimgrep_item(lines)
    if not item then
      notify("MyBatis: no encontré mapper XML para " .. fqn, vim.log.levels.INFO)
      return
    end

    locations.open_or_peek(item, {
      peek = true,
      title = " MyBatis XML namespace ",
    })
    return
  end

  open_loclist(lines, "MyBatis namespace: " .. fqn)
end

function M.statement(opts)
  opts = opts or {}

  if not java_context.ensure_java_buffer() then
    return
  end

  local ref_namespace, ref_method = java_context.statement_ref_near_cursor()
  if ref_namespace and ref_method and M.statement_for(ref_namespace, ref_method, opts) then
    return
  end

  local fqn = java_context.current_fqn()
  if not fqn then
    notify("MyBatis: no pude inferir namespace Java", vim.log.levels.WARN)
    return
  end

  local method = cursor.word()
  if not method then
    notify("MyBatis: coloca el cursor en el nombre del método", vim.log.levels.WARN)
    return
  end

  if not M.statement_for(fqn, method, opts) then
    notify("MyBatis: no encontré mapper XML para " .. fqn, vim.log.levels.INFO)
  end
end

function M.statement_quiet(opts)
  opts = opts or {}

  local ref_namespace, ref_method = java_context.statement_ref_near_cursor()
  if ref_namespace and ref_method then
    return M.statement_for(ref_namespace, ref_method, opts)
  end

  local fqn = java_context.current_fqn()
  local method = cursor.word()
  if not fqn or not method then
    return false
  end

  return M.statement_for(fqn, method, opts)
end

return M
