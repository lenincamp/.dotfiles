local M = {}

local java_context = require("modules.editor.mybatis.java_context")
local parser = require("modules.editor.mybatis.parser")
local search = require("modules.editor.mybatis.search")
local xml_context = require("modules.editor.mybatis.xml_context")

local SQLMAP_XML_GLOB = "*-sqlmap.xml"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function get_peek_module()
  local ok, peek = pcall(require, "modules.editor.peek")
  if not ok or type(peek.preview_location) ~= "function" then
    return nil
  end
  return peek
end

local function open_or_peek_file(path, lnum, col, opts)
  opts = opts or {}

  if opts.peek then
    local peek = get_peek_module()
    if peek and peek.preview_location({
      filename = path,
      lnum = lnum or 1,
      col = col or 1,
      title = opts.title,
    }) then
      return true
    end
  end

  open_file(path)
  if lnum and lnum > 0 then
    vim.api.nvim_win_set_cursor(0, { lnum, math.max(0, (col or 1) - 1) })
  end
  return true
end

local function current_word()
  local word = vim.fn.expand("<cword>")
  if not word or word == "" then
    return nil
  end
  return word
end

local function open_items_with_loclist(items, title)
  if vim.tbl_isempty(items) then
    return false
  end

  vim.fn.setloclist(0, {}, " ", {
    title = title,
    items = items,
  })

  vim.cmd("lopen")

  return true
end

local function open_loclist(lines, title)
  if not lines or vim.tbl_isempty(lines) then
    return false
  end

  local items = search.parse_vimgrep_lines(lines)
  if vim.tbl_isempty(items) then
    return false
  end

  vim.fn.setloclist(0, {}, " ", {
    title = title,
    items = items,
  })

  if #items == 1 then
    vim.cmd("lfirst")
  else
    vim.cmd("lopen")
  end

  return true
end

local function mapper_files_for_namespace(namespace)
  return search.rg_files_with_matches(parser.mapper_namespace_pattern(namespace), java_context.project_root(), SQLMAP_XML_GLOB)
end

local function jump_to_mapper_statement(namespace, statement_id, opts)
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

    return open_or_peek_file(item.filename, item.lnum, item.col, {
      peek = true,
      title = " MyBatis XML " .. statement_id .. " ",
    })
  end

  return open_loclist(lines, "MyBatis id: " .. statement_id)
end

local function open_or_pick_java_usages(namespace, method, opts)
  opts = opts or {}

  local items = java_context.find_usages_for_statement(namespace, method)
  if vim.tbl_isempty(items) then
    return false
  end

  if #items > 1 then
    return open_items_with_loclist(items, "MyBatis usages: " .. namespace .. "." .. method)
  end

  return open_or_peek_file(items[1].filename, items[1].lnum, items[1].col, {
    peek = opts.peek,
    title = " MyBatis Java usage " .. method .. " ",
  })
end

local function xml_to_java_method_via_statement_usage(namespace, method, opts)
  opts = opts or {}

  local item = java_context.find_usage_for_statement(namespace, method)
  if not item then
    return false
  end

  open_or_peek_file(item.filename, item.lnum, item.col, {
    peek = opts.peek,
    title = " MyBatis Java usage " .. method .. " ",
  })

  if not opts.peek then
    java_context.jump_to_method_from_line(method, item.lnum)
  end

  return true
end

function M.java_to_mapper_namespace(opts)
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

    open_or_peek_file(item.filename, item.lnum, item.col, {
      peek = true,
      title = " MyBatis XML namespace ",
    })
    return
  end

  open_loclist(lines, "MyBatis namespace: " .. fqn)
end

function M.java_to_mapper_statement(opts)
  opts = opts or {}

  if not java_context.ensure_java_buffer() then
    return
  end

  local ref_namespace, ref_method = java_context.statement_ref_near_cursor()
  if ref_namespace and ref_method and jump_to_mapper_statement(ref_namespace, ref_method, opts) then
    return
  end

  local fqn = java_context.current_fqn()
  if not fqn then
    notify("MyBatis: no pude inferir namespace Java", vim.log.levels.WARN)
    return
  end

  local method = current_word()
  if not method then
    notify("MyBatis: coloca el cursor en el nombre del método", vim.log.levels.WARN)
    return
  end

  if not jump_to_mapper_statement(fqn, method, opts) then
    notify("MyBatis: no encontré mapper XML para " .. fqn, vim.log.levels.INFO)
  end
end

function M.xml_to_java_namespace(opts)
  opts = opts or {}

  if not xml_context.ensure_xml_buffer() then
    return
  end

  local namespace = xml_context.current_mapper_namespace()
  if not namespace then
    notify("MyBatis: no encontré namespace en <mapper>", vim.log.levels.WARN)
    return
  end

  local target = java_context.find_file_for_namespace(namespace)
  if not target then
    notify("MyBatis: no encontré clase Java para namespace " .. namespace, vim.log.levels.INFO)
    return
  end

  open_or_peek_file(target, 1, 1, {
    peek = opts.peek,
    title = " MyBatis Java namespace ",
  })
end

function M.xml_to_java_method(opts)
  opts = opts or {}

  if not xml_context.ensure_xml_buffer() then
    return
  end

  local namespace = xml_context.current_mapper_namespace()
  if not namespace then
    notify("MyBatis: no encontré namespace en <mapper>", vim.log.levels.WARN)
    return
  end

  local method = xml_context.current_mapper_statement_id() or current_word()
  if not method then
    notify("MyBatis: coloca el cursor sobre el id del statement", vim.log.levels.WARN)
    return
  end

  if parser.namespace_looks_like_package(namespace) and xml_to_java_method_via_statement_usage(namespace, method, opts) then
    return
  end

  local target = java_context.find_file_for_namespace(namespace)
  if not target then
    if xml_to_java_method_via_statement_usage(namespace, method, opts) then
      return
    end
    notify("MyBatis: no encontré clase Java para namespace " .. namespace, vim.log.levels.INFO)
    return
  end

  if opts.peek then
    local item = java_context.find_method_declaration(target, method)
    if item then
      open_or_peek_file(item.filename, item.lnum, item.col, {
        peek = true,
        title = " MyBatis Java method " .. method .. " ",
      })
      return
    end

    if xml_to_java_method_via_statement_usage(namespace, method, opts) then
      return
    end

    notify("MyBatis: método no encontrado en interfaz Java: " .. method, vim.log.levels.INFO)
    return
  end

  open_file(target)
  if not java_context.jump_to_method_from_line(method) then
    if xml_to_java_method_via_statement_usage(namespace, method, opts) then
      return
    end
    notify("MyBatis: método no encontrado en interfaz Java: " .. method, vim.log.levels.INFO)
  end
end

function M.xml_to_java_parameter_type(opts)
  opts = opts or {}

  if not xml_context.ensure_xml_buffer() then
    return
  end

  local parameter_type = xml_context.current_mapper_parameter_type() or current_word()
  if not parameter_type then
    notify("MyBatis: coloca el cursor sobre parameterType o dentro del statement", vim.log.levels.WARN)
    return
  end

  local target = java_context.find_file_for_type(parameter_type)
  if not target then
    notify("MyBatis: no encontré clase para parameterType=" .. parameter_type, vim.log.levels.INFO)
    return
  end

  open_or_peek_file(target, 1, 1, {
    peek = opts.peek,
    title = " MyBatis Java parameterType ",
  })
end

local function java_to_mapper_statement_quiet(opts)
  opts = opts or {}

  local ref_namespace, ref_method = java_context.statement_ref_near_cursor()
  if ref_namespace and ref_method then
    return jump_to_mapper_statement(ref_namespace, ref_method, opts)
  end

  local fqn = java_context.current_fqn()
  local method = current_word()
  if not fqn or not method then
    return false
  end

  return jump_to_mapper_statement(fqn, method, opts)
end

local function xml_to_java_definition_quiet(opts)
  opts = opts or {}

  local java_type = xml_context.java_type_under_cursor()
  if java_type then
    local target = java_context.find_file_for_type(java_type)
    if target then
      return open_or_peek_file(target, 1, 1, {
        peek = opts.peek,
        title = " MyBatis Java type " .. java_type .. " ",
      })
    end
  end

  local namespace = xml_context.current_mapper_namespace()
  if not namespace then
    return false
  end

  local attr, attr_value = xml_context.attr_under_cursor()
  if attr == "id" and attr_value and attr_value ~= "" then
    return open_or_pick_java_usages(namespace, attr_value, opts)
  end

  local method = xml_context.current_mapper_statement_id() or current_word()
  if method then
    return open_or_pick_java_usages(namespace, method, opts)
  end

  local target = java_context.find_file_for_namespace(namespace)
  if not target then
    return false
  end

  return open_or_peek_file(target, 1, 1, {
    peek = opts.peek,
    title = " MyBatis Java namespace ",
  })
end

function M.peek_definition()
  if vim.bo.filetype == "java" then
    return java_to_mapper_statement_quiet({ peek = true })
  end

  if xml_context.is_xml_like_filetype() then
    return xml_to_java_definition_quiet({ peek = true })
  end

  return false
end

return M
