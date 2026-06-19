local M = {}

function M.setup()
  if M._setup_done then
    return
  end
  M._setup_done = true

  local specs = require("modules.editor.keymap_specs")
  specs.apply(specs.search_specs())
end

return M
