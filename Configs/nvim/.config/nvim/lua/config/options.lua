-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.o.pumblend = 0
vim.o.winblend = 0
vim.cmd([[let g:loaded_python3_provider=0]])

vim.o.termguicolors = true
vim.opt.cursorline = false
vim.opt.splitright = true -- Nuevos splits a la derecha
vim.opt.splitbelow = true -- Nuevos splits abajo
vim.opt.winborder = "rounded"

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
local diffopt = {
  "internal", -- Usar el algoritmo interno de diff
  "filler", -- Mostrar líneas de relleno para mantener sincronización
  "closeoff", -- Cerrar diff cuando solo queda una ventana
  "hiddenoff", -- Desactivar diff cuando el buffer se oculta
  "foldcolumn:1", -- Mostrar columna de pliegues
  "context:999999", -- Mostrar todo el contexto (no colapsar)
  "vertical", -- Splits verticales por defecto
  "algorithm:histogram", -- Algoritmo más semántico (mejor que myers)
  "indent-heuristic", -- Usar heurística de indentación para mejores diffs
  "linematch:60", -- Mejor detección de líneas movidas (Neovim 0.9+)
}
vim.opt.diffopt:append(table.concat(diffopt, ","))

if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end
vim.g.lazyvim_mini_snippets_in_completion = true

function _G.WinbarBreadcrumb()
  -- local path = vim.fn.expand("%f")
  local path = vim.fn.expand("%:~:.")
  if path == "" then
    return ""
  end
  local separator = "\u{202F}\u{202F}"

  return path:gsub("/", separator)
end

vim.opt.winbar = " %m %{v:lua.WinbarBreadcrumb()}%="
vim.opt.showtabline = 0
vim.opt.laststatus = 0
vim.opt.cmdheight = 0
