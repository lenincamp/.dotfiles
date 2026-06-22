local M = {}

--- Load a lazy.nvim plugin by its spec name (same as in lua/plugins/init.lua).
--- @param name string
--- @return boolean
function M.load(name)
  if type(name) ~= "string" or name == "" then
    return false
  end
  require("lazy").load({ plugins = { name } })
  return true
end

return M
