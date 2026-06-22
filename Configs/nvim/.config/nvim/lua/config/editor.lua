local M = {}

local config = vim.fn.stdpath("config")
local editor_root = config .. "/plugins/editor"

function M.load(name)
  local key = "config.editor." .. name
  local cached = package.loaded[key]
  if type(cached) == "table" then
    return cached
  end
  package.loaded[key] = dofile(editor_root .. "/" .. name .. ".lua")
  return package.loaded[key]
end

for _, name in ipairs({ "sessions", "task_runner", "command_center", "terminal" }) do
  package.preload["config.editor." .. name] = function()
    return M.load(name)
  end
end

package.preload["config.test"] = function()
  return dofile(config .. "/plugins/test/neotest.lua")
end

package.preload["config.ui"] = function()
  return dofile(config .. "/plugins/ui/toggles.lua")
end

return M
