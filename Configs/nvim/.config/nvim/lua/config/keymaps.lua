-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
-- local opts = { noremap = true, silent = true }
-- Delete a word backwards
keymap.set("n", "dw", "vb_d")
keymap.set("v", "p", '"_dP')

--Jump
keymap.set("n", "L", "$")
keymap.set("n", "H", "^")
keymap.set("n", "<C-i>", "<C-I>", { noremap = true, desc = "Jump forward" })
keymap.set("v", "J", "<cmd>m '>+1<CR>gv=gv")
keymap.set("v", "K", "<cmd>m '<-2<CR>gv=gv")
keymap.set("n", "<TAB>", "<cmd>bn<CR>")
keymap.set("n", "<S-TAB>", "<cmd>bp<CR>")

--lsp
keymap.set(
  "n",
  "gV",
  ":vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>",
  { silent = true, desc = "Split & Goto definition" }
)

local goto_preview = require("goto-preview")
keymap.set("n", "gpd", function()
  goto_preview.goto_preview_definition({})
end, { desc = "[G]o to [P]review [D]efinition" })
keymap.set("n", "gpt", function()
  goto_preview.goto_preview_type_definition({})
end, { desc = "[G]o to [P]review [T]ype Definition" })
keymap.set("n", "gpi", function()
  goto_preview.goto_preview_implementation({})
end, { desc = "[G]o to [P]review [I]mplementation" })
keymap.set("n", "gpD", function()
  goto_preview.goto_preview_declaration({})
end, { desc = "[G]o to [P]review [D]eclaration" })
keymap.set("n", "gpc", function()
  goto_preview.close_all_win({ skip_curr_window = true })
end, { desc = "Close all win except first" })
keymap.set("n", "gpa", function()
  goto_preview.close_all_win()
end, { desc = "Close all win except first" })

keymap.set("n", "gpr", function()
  goto_preview.goto_preview_references()
end, { desc = "[G]o to [P]review [R]references" })
keymap.set(
  { "n" },
  "<leader>rr",
  [[:%s/\V<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace all ocurrencies" }
)

keymap.set(
  { "v" },
  "<leader>rr",
  [["vy:%s/\V<C-r>=escape(@v, '/\')<CR>/<C-r>v/gI<Left><Left><Left>]],
  { desc = "Replace all ocurrencies" }
)

vim.keymap.set("n", "gps", function()
  local clients = vim.lsp.get_clients({ name = "sonarlint.nvim" })
  if #clients > 0 then
    vim.lsp.stop_client(clients)
    vim.notify("SonarLint desactivado", vim.log.levels.INFO)
  else
    local sonarlint = require("lazy.core.config").plugins["sonarlint.nvim"]
    require("lazy.core.loader").reload(sonarlint)
    vim.notify("SonarLint activado", vim.log.levels.INFO)
  end
end, { desc = "Enable/Disable SonarLint" })

local function copy_relative_path_and_show_notify()
  local cwd = vim.fn.getcwd()
  local buffer_path = vim.fn.expand("%:p")
  local file_name = vim.fn.expand("%:t")

  local function string_startswith(str, prefix)
    return str:sub(1, #prefix) == prefix
  end

  local function string_endswith(str, suffix)
    return suffix == "" or str:sub(-#suffix) == suffix
  end

  if not string_endswith(cwd, "/") then
    cwd = cwd .. "/"
  end

  if string_startswith(buffer_path, cwd) then
    vim.ui.select({ "Ruta completa", "Nombre del fichero" }, { prompt = "Selecciona la opción:" }, function(opcion)
      if opcion == "Ruta completa" then
        local relative_path = buffer_path:sub(#cwd + 1)
        vim.fn.setreg("+", relative_path)
        vim.notify("Path: " .. relative_path, vim.log.levels.INFO)
      elseif opcion == "Nombre del fichero" then
        vim.fn.setreg("+", file_name)
        vim.notify("Nombre del fichero: " .. file_name, vim.log.levels.INFO)
      end
    end)
  else
    vim.notify("El archivo no está dentro del directorio de trabajo actual.", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>cp", copy_relative_path_and_show_notify, { desc = "[C]opy absolute [P]ath to clipboard" })
