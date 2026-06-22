local M = {}
local lazy_bootstrap = require("modules.bootstrap.lazy")
local build = require("modules.integrations.avante.build")
local keymaps = require("modules.integrations.avante.keymaps")
local providers = require("modules.integrations.avante.providers")
local setup_done = false

---@class AvanteModule
---@field setup fun(opts: table)
---@field get fun(): table
---@field toggle fun()

local function get_avante_module()
  local ok, mod = pcall(require, "avante")
  if not ok or type(mod) ~= "table" then
    return nil
  end

  return mod
end

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

  local avante = get_avante_module()
  if not avante then
    return false
  end

  local state = providers.context()

  avante.setup(providers.setup_options(state))

  if not state.has_copilot_provider then
    require("avante.config").providers.copilot = nil
  end

  keymaps.setup(state)
  setup_done = true
  return true
end

return M
