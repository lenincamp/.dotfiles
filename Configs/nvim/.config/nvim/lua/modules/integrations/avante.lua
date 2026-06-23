local M = {}
local lazy_bootstrap = require("modules.bootstrap.lazy")
local build = require("modules.integrations.avante.build")
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

  if not build.ensure_ready(function(ok)
    if not ok or setup_done then
      return
    end

    if lazy_bootstrap.load("avante.nvim") then
      return
    end

    pcall(M.setup)
  end) then
    return false
  end

  local avante = core.get()
  if not avante then
    return false
  end

  local state = providers.context()

  avante.setup(providers.setup_options(state))

  if not (state.has_copilot_provider and state.has_copilot_auth and state.enable_copilot) then
    require("avante.config").providers.copilot = nil
  end

  keymaps.setup(state)
  setup_done = true
  return true
end

return M
