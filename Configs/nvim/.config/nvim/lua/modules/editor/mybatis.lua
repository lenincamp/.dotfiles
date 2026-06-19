local M = {}
local navigation = require("modules.editor.mybatis.navigation")

function M.java_to_mapper_namespace()
  navigation.java_to_mapper_namespace()
end

function M.java_to_mapper_statement()
  navigation.java_to_mapper_statement()
end

function M.xml_to_java_namespace()
  navigation.xml_to_java_namespace()
end

function M.xml_to_java_method()
  navigation.xml_to_java_method()
end

function M.xml_to_java_parameter_type()
  navigation.xml_to_java_parameter_type()
end

function M.peek_definition()
  return navigation.peek_definition()
end

function M.java_to_mapper_namespace_peek()
  navigation.java_to_mapper_namespace({ peek = true })
end

function M.java_to_mapper_statement_peek()
  navigation.java_to_mapper_statement({ peek = true })
end

function M.xml_to_java_namespace_peek()
  navigation.xml_to_java_namespace({ peek = true })
end

function M.xml_to_java_method_peek()
  navigation.xml_to_java_method({ peek = true })
end

function M.xml_to_java_parameter_type_peek()
  navigation.xml_to_java_parameter_type({ peek = true })
end

return M
