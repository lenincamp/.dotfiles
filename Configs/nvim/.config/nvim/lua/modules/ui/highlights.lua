local M = {}

local callbacks = {}
local setup_done = false

local function apply_one(name, callback)
  local ok, err = pcall(callback)
  if not ok then
    vim.notify("Highlight refresh failed [" .. name .. "]: " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.apply()
  for name, callback in pairs(callbacks) do
    apply_one(name, callback)
  end
end

function M.register(name, callback)
  if type(name) ~= "string" or name == "" or type(callback) ~= "function" then
    return
  end

  callbacks[name] = callback
  if not setup_done then
    setup_done = true
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("PureUiHighlights", { clear = true }),
      callback = M.apply,
    })
  end

  apply_one(name, callback)
end

return M
