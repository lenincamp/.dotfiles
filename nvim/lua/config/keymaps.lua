-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
-- local opts = { noremap = true, silent = true }
-- Delete a word backwards
keymap.set("n", "dw", "vb_d")

--Jump
keymap.set("n", "L", "$")
keymap.set("n", "H", "^")
keymap.set("n", "[b", "<Cmd>bp<CR>", { desc = "Prev buffer" })
keymap.set("n", "]b", "<Cmd>bn<CR>", { desc = "Next buffer" })

local goto_preview = require("goto-preview")
keymap.set("n", "gpd", function()
  goto_preview.goto_preview_definition({})
end, { desc = "[G]oto [P]review [D]efinition" })
keymap.set("n", "gpt", function()
  goto_preview.goto_preview_type_definition({})
end, { desc = "[G]o to [P]review [T]ype Definition" })
keymap.set("n", "gpi", function()
  goto_preview.goto_preview_implementation({})
end, { desc = "[G]o to [P]review [I]mplementation" })
keymap.set("n", "gpD", function()
  goto_preview.goto_preview_declaration({})
end, { desc = "[G]o to [P]review [D]eclaration" })
keymap.set("n", "gP", function()
  goto_preview.close_all_win()
end, { desc = "Close all win" })
keymap.set("n", "gpr", function()
  goto_preview.goto_preview_references()
end, { desc = "[G]o to [P]review [R]references" })

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
