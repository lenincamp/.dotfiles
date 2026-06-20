local M = {}

local java_to_xml = require("modules.editor.mybatis.java_to_xml")
local xml_to_java = require("modules.editor.mybatis.xml_to_java")
local xml_context = require("modules.editor.mybatis.xml_context")

function M.java_to_mapper_namespace(opts)
  return java_to_xml.namespace(opts)
end

function M.java_to_mapper_statement(opts)
  return java_to_xml.statement(opts)
end

function M.xml_to_java_namespace(opts)
  return xml_to_java.namespace(opts)
end

function M.xml_to_java_method(opts)
  return xml_to_java.method(opts)
end

function M.xml_to_java_parameter_type(opts)
  return xml_to_java.parameter_type(opts)
end

function M.peek_definition()
  if vim.bo.filetype == "java" then
    return java_to_xml.statement_quiet({ peek = true })
  end

  if xml_context.is_xml_like_filetype() then
    return xml_to_java.definition_quiet({ peek = true })
  end

  return false
end

return M
