-- avante.nvim bootstrap delegated to modules.integrations.avante

local ok, avante_integration = pcall(require, "modules.integrations.avante")
if not ok then
  return false
end

return avante_integration.setup()
