local M = {}

function M.setup()
  local map = vim.keymap.set
  local avante = require("avante")
  local api    = require("avante.api")

  map({ "n", "v" }, "<leader>aa", api.ask,                                    { desc = "Avante: ask" })
  map("v",          "<leader>ae", api.edit,                                   { desc = "Avante: edit" })
  map("n",          "<leader>ar", api.refresh,                                { desc = "Avante: refresh" })
  map("n",          "<leader>af", api.focus,                                  { desc = "Avante: focus" })
  map("n",          "<leader>aS", api.stop,                                   { desc = "Avante: stop" })
  map({ "n", "v" }, "<leader>az", api.zen_mode,                               { desc = "Avante: zen mode" })
  map("n",          "<leader>a?", api.select_model,                           { desc = "Avante: select model" })
  map("n",          "<leader>ah", api.select_history,                         { desc = "Avante: history" })
  map("n",          "<leader>aM", api.select_acp_model,                       { desc = "Avante: select ACP model" })
  map("n",          "<leader>ai", api.select_acp_mode,                        { desc = "Avante: select ACP mode" })
  map("n",          "<leader>aB", api.add_buffer_files,                       { desc = "Avante: add all buffers" })
  map("n",          "<leader>at", function() avante.toggle() end,             { desc = "Avante: toggle" })
  map("n",          "<leader>ad", function() avante.toggle.debug() end,       { desc = "Avante: toggle debug" })
  map("n",          "<leader>as", function() avante.toggle.suggestion() end,  { desc = "Avante: toggle suggestion" })
  map("n",          "<leader>aR", function() require("avante.repo_map").show() end, { desc = "Avante: repo map" })
  map("n",          "<leader>ac", function()
    local sidebar = avante.get()
    if sidebar then sidebar.file_selector:add_current_buffer() end
  end, { desc = "Avante: add current buffer" })

  -- custom
  map("n", "<leader>an", "<cmd>AvanteChatNew<CR>",        { desc = "Avante: new chat" })
  map("n", "<leader>aP", "<cmd>AvanteSwitchProvider<CR>", { desc = "Avante: switch provider" })
  map("n", "<leader>aC", "<cmd>AvanteClear<CR>",          { desc = "Avante: clear" })
end

return M
