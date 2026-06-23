local M = {}

function M.get()
  local ok, mod = pcall(require, "avante")
  if not ok or type(mod) ~= "table" then return nil end
  return mod
end

return M
