local M = {}
local core = require("modules.integrations.avante.core")
local keymaps = require("modules.integrations.avante.keymaps")
local providers = require("modules.integrations.avante.providers")
local setup_done = false

---@class AvanteModule
---@field setup fun(opts: table)
---@field get fun(): table
---@field toggle fun()

function M.setup()
  if setup_done then
    return true
  end

  local avante = core.get()
  if not avante then
    return false
  end

  avante.setup(providers.setup_options())
  keymaps.setup()
  setup_done = true
  return true
end

return M
