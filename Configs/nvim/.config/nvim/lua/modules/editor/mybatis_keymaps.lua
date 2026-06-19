local M = {}

local specs = {
  { mode = "n", lhs = "<leader>mX", desc = "MyBatis: Java -> mapper namespace", action = "java_to_mapper_namespace" },
  { mode = "n", lhs = "<leader>mx", desc = "MyBatis: Java -> mapper statement id", action = "java_to_mapper_statement" },
  { mode = "n", lhs = "<leader>mJ", desc = "MyBatis: XML -> Java interface", action = "xml_to_java_namespace" },
  { mode = "n", lhs = "<leader>mj", desc = "MyBatis: XML -> Java method", action = "xml_to_java_method" },
  { mode = "n", lhs = "<leader>mp", desc = "MyBatis: XML -> parameterType class", action = "xml_to_java_parameter_type" },
}

function M.lazy_specs()
  local out = {}
  for _, spec in ipairs(specs) do
    out[#out + 1] = {
      mode = spec.mode,
      lhs = spec.lhs,
      desc = spec.desc,
    }
  end
  return out
end

function M.apply(mybatis)
  if type(mybatis) ~= "table" then
    return
  end

  for _, spec in ipairs(specs) do
    local fn = mybatis[spec.action]
    if type(fn) == "function" then
      vim.keymap.set(spec.mode, spec.lhs, fn, { desc = spec.desc })
    end
  end
end

return M
