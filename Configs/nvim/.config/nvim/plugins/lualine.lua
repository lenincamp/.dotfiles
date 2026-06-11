-- Lualine manages winbar and optional statusline/tabline.

local ok, lualine = pcall(require, "lualine")
if not ok then return end

local ui = require("ui_toggles")
local colorschemes = require("colorschemes")

-- Filetype icon lookup (nerd fonts v3)
local ft_icons = {
  java = "󰬷", javascript = "󰌞", typescript = "󰛦",
  javascriptreact = "󰜈", typescriptreact = "󰜈",
  lua = "󰢱", python = "󰌠", html = "󰌝",
  css = "󰌜", scss = "󰌜", json = "󰘦",
  markdown = "󰍔", xml = "󰗀", yaml = "󰈙",
  toml = "󰈙", sh = "󰆍", bash = "󰆍",
  vim = "󰕷", sql = "󰆼", kotlin = "󱈙",
  rust = "󱘗", go = "󰟓", c = "󰙱",
  cpp = "󰙲", cs = "󰌛", ruby = "󰴭",
  php = "󰌟", swift = "󰛥",
}

local function ft_icon(buf)
  local ft = vim.bo[buf].filetype
  local ico = ft_icons[ft]
  if ico then return "%#WinBarIcon#" .. ico .. " " end

  -- Fallback: try extension from filename
  local name = vim.api.nvim_buf_get_name(buf)
  local ext = name:match("%.(%w+)$")
  ico = ext and ft_icons[ext:lower()]
  return ico and ("%#WinBarIcon#" .. ico .. " ") or "%#WinBarIcon#󰈙 "
end

local function max_dirs_for_width(win)
  local width = vim.api.nvim_win_get_width(win)
  if width < 60 then return 1 end
  if width < 90 then return 2 end
  if width < 130 then return 3 end
  return 4
end

local function build_winbar_path(buf, max_dirs)
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then return "" end
  path = vim.fn.fnamemodify(path, ":~:.")

  local parts = vim.split(path, "/", { plain = true })
  if #parts == 0 then return "" end

  local truncated = false
  if #parts > max_dirs + 1 then
    local kept = {}
    for i = #parts - max_dirs, #parts do
      kept[#kept + 1] = parts[i]
    end
    parts = kept
    truncated = true
  end

  local sep = " %#WinBarSep#› %#WinBarPath#"
  local crumbs = {}
  if truncated then crumbs[#crumbs + 1] = "%#WinBarSep#…" end

  for i, part in ipairs(parts) do
    crumbs[#crumbs + 1] = (i == #parts)
      and ("%#WinBarFile#" .. part)
      or ("%#WinBarPath#" .. part)
  end

  return ft_icon(buf) .. table.concat(crumbs, sep)
end

local function winbar_breadcrumb_component()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)

  if vim.bo[buf].buftype ~= "" then return "" end

  local max_dirs = max_dirs_for_width(win)
  local cache_key = tostring(max_dirs)
  local cache = vim.b[buf].lualine_winbar_cache

  if type(cache) ~= "table" then
    cache = {}
    vim.b[buf].lualine_winbar_cache = cache
  end

  local cached = cache[cache_key]
  if cached == nil then
    cached = build_winbar_path(buf, max_dirs)
    cache[cache_key] = cached
  end

  if cached == "" then return "" end
  local mod = vim.bo[buf].modified and " %#WinBarMod#●%#WinBar# " or " "
  return " " .. cached .. mod
end

local function build_config()
  local winbar_sections = {}
  if ui.winbar_enabled() then
    winbar_sections = {
      lualine_c = {
        {
          winbar_breadcrumb_component,
          padding = { left = 0, right = 0 },
        },
      },
    }
  end

  return {
    options = {
      theme = colorschemes.lualine_theme(vim.g.pure_colorscheme or vim.g.colors_name),
      globalstatus = false,
      component_separators = "",
      section_separators = "",
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 200,
      },
      disabled_filetypes = {
        winbar = {
          "snacks_dashboard",
          "help",
          "qf",
        },
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        {
          "filename",
          path = 1,
          shorting_target = 40,
        },
      },
      lualine_x = { "diagnostics" },
      lualine_y = { "filetype" },
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
    winbar = winbar_sections,
    inactive_winbar = winbar_sections,
    tabline = {
      lualine_a = {
        {
          "tabs",
          mode = 2,
          cond = function() return ui.tabline_mode() == "tabs" end,
        },
        {
          "buffers",
          mode = 2,
          cond = function() return ui.tabline_mode() == "buffers" end,
        },
      },
      lualine_z = {
        {
          function()
            return "cwd: " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          end,
        },
      },
    },
    extensions = {},
  }
end

local function apply_lualine()
  lualine.setup(build_config())
  ui.apply_bars_state()
  if not ui.winbar_enabled() then
    vim.o.winbar = ""
  end
end

_G.PureLualineApply = apply_lualine

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "BufWritePost", "FileType" }, {
  group = vim.api.nvim_create_augroup("lualine_winbar_cache", { clear = true }),
  callback = function(args)
    vim.b[args.buf].lualine_winbar_cache = nil
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("lualine_winbar_cwd", { clear = true }),
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.b[buf].lualine_winbar_cache = nil
      end
    end
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("pure_lualine_theme_sync", { clear = true }),
  callback = function()
    apply_lualine()
    ui.apply_winbar_state()
  end,
})

ui.apply()
apply_lualine()
