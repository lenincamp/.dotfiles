local M = {}

local cursor = require("modules.editor.cursor")
local java_context = require("modules.editor.mybatis.java_context")
local locations = require("modules.editor.locations")
local parser = require("modules.editor.mybatis.parser")
local xml_context = require("modules.editor.mybatis.xml_context")

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

local function open_or_pick_usages(namespace, method, opts)
  opts = opts or {}

  local items = java_context.find_usages_for_statement(namespace, method)
  if vim.tbl_isempty(items) then
    return false
  end

  if #items > 1 then
    return locations.open_items_loclist(items, "MyBatis usages: " .. namespace .. "." .. method)
  end

  return locations.open_or_peek(items[1], {
    peek = opts.peek,
    title = " MyBatis Java usage " .. method .. " ",
  })
end

local function method_via_statement_usage(namespace, method, opts)
  opts = opts or {}

  local item = java_context.find_usage_for_statement(namespace, method)
  if not item then
    return false
  end

  locations.open_or_peek(item, {
    peek = opts.peek,
    title = " MyBatis Java usage " .. method .. " ",
  })

  if not opts.peek then
    java_context.jump_to_method_from_line(method, item.lnum)
  end

  return true
end

function M.namespace(opts)
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

  locations.open_or_peek({ filename = target, lnum = 1, col = 1 }, {
    peek = opts.peek,
    title = " MyBatis Java namespace ",
  })
end

function M.method(opts)
  opts = opts or {}

  if not xml_context.ensure_xml_buffer() then
    return
  end

  local namespace = xml_context.current_mapper_namespace()
  if not namespace then
    notify("MyBatis: no encontré namespace en <mapper>", vim.log.levels.WARN)
    return
  end

  local method = xml_context.current_mapper_statement_id() or cursor.word()
  if not method then
    notify("MyBatis: coloca el cursor sobre el id del statement", vim.log.levels.WARN)
    return
  end

  if parser.namespace_looks_like_package(namespace) and method_via_statement_usage(namespace, method, opts) then
    return
  end

  local target = java_context.find_file_for_namespace(namespace)
  if not target then
    if method_via_statement_usage(namespace, method, opts) then
      return
    end
    notify("MyBatis: no encontré clase Java para namespace " .. namespace, vim.log.levels.INFO)
    return
  end

  if opts.peek then
    local item = java_context.find_method_declaration(target, method)
    if item then
      locations.open_or_peek(item, {
        peek = true,
        title = " MyBatis Java method " .. method .. " ",
      })
      return
    end

    if method_via_statement_usage(namespace, method, opts) then
      return
    end

    notify("MyBatis: método no encontrado en interfaz Java: " .. method, vim.log.levels.INFO)
    return
  end

  locations.open_file(target)
  if not java_context.jump_to_method_from_line(method) then
    if method_via_statement_usage(namespace, method, opts) then
      return
    end
    notify("MyBatis: método no encontrado en interfaz Java: " .. method, vim.log.levels.INFO)
  end
end

function M.parameter_type(opts)
  opts = opts or {}

  if not xml_context.ensure_xml_buffer() then
    return
  end

  local parameter_type = xml_context.current_mapper_parameter_type() or cursor.word()
  if not parameter_type then
    notify("MyBatis: coloca el cursor sobre parameterType o dentro del statement", vim.log.levels.WARN)
    return
  end

  local target = java_context.find_file_for_type(parameter_type)
  if not target then
    notify("MyBatis: no encontré clase para parameterType=" .. parameter_type, vim.log.levels.INFO)
    return
  end

  locations.open_or_peek({ filename = target, lnum = 1, col = 1 }, {
    peek = opts.peek,
    title = " MyBatis Java parameterType ",
  })
end

function M.definition_quiet(opts)
  opts = opts or {}

  local java_type = xml_context.java_type_under_cursor()
  if java_type then
    local target = java_context.find_file_for_type(java_type)
    if target then
      return locations.open_or_peek({ filename = target, lnum = 1, col = 1 }, {
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
    return open_or_pick_usages(namespace, attr_value, opts)
  end

  local method = xml_context.current_mapper_statement_id() or cursor.word()
  if method then
    return open_or_pick_usages(namespace, method, opts)
  end

  local target = java_context.find_file_for_namespace(namespace)
  if not target then
    return false
  end

  return locations.open_or_peek({ filename = target, lnum = 1, col = 1 }, {
    peek = opts.peek,
    title = " MyBatis Java namespace ",
  })
end

return M
