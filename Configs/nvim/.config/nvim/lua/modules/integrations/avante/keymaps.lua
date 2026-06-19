local files = require("modules.integrations.avante.files")
local providers = require("modules.integrations.avante.providers")

local M = {}

local function get_avante_module()
  local ok, mod = pcall(require, "avante")
  if not ok or type(mod) ~= "table" then
    return nil
  end

  return mod
end

local function pick_provider(state)
  local ok_cfg, cfg = pcall(require, "avante.config")
  local current = (ok_cfg and cfg.provider) or "?"

  require("modules.editor.picker").select_items(providers.provider_items(state), {
    prompt = "Avante provider  (active: " .. current .. ")",
    scope = "global",
    search_threshold = 0,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      require("avante.api").switch_provider(choice.name)
    end
  end)
end

function M.setup(state)
  local map = vim.keymap.set

  map({ "n", "x" }, "<leader>aa", function()
    require("avante.api").ask()
  end, { desc = "Avante: ask" })

  map("n", "<leader>at", function()
    local avante = get_avante_module()
    if not avante then
      return
    end

    avante.toggle()
  end, { desc = "Avante: toggle" })

  map({ "n", "x" }, "<leader>ae", function()
    require("avante.api").edit()
  end, { desc = "Avante: edit" })

  map("n", "<leader>an", "<cmd>AvanteChatNew<CR>", { desc = "Avante: new chat" })
  map("n", "<leader>ah", "<cmd>AvanteHistory<CR>", { desc = "Avante: history" })
  map("n", "<leader>aS", "<cmd>AvanteStop<CR>", { desc = "Avante: stop" })
  map("n", "<leader>ar", "<cmd>AvanteRefresh<CR>", { desc = "Avante: refresh" })
  map("n", "<leader>af", "<cmd>AvanteFocus<CR>", { desc = "Avante: focus" })
  map("n", "<leader>a?", function()
    pick_provider(state)
  end, { desc = "Avante: pick provider/model" })
  map("n", "<leader>aM", "<cmd>AvanteModels<CR>", { desc = "Avante: provider models (dynamic)" })
  map("n", "<leader>aP", "<cmd>AvanteSwitchProvider<CR>", { desc = "Avante: provider" })
  map("n", "<leader>aC", "<cmd>AvanteClear<CR>", { desc = "Avante: clear" })
  map("n", "<leader>aR", "<cmd>AvanteShowRepoMap<CR>", { desc = "Avante: repo map" })
  map("n", "<leader>ac", files.add_current_buffer, { desc = "Avante: add current file" })
  map("n", "<leader>aB", files.add_open_buffers, { desc = "Avante: add open buffers" })

  map("n", "<leader>az", function()
    require("avante.api").zen_mode()
  end, { desc = "Avante: zen mode" })
end

return M
