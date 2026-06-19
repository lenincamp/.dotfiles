local alacritty = require("modules.theme.sync.alacritty")

local M = {}

function M.color_value(hex)
  if type(hex) ~= "string" then return nil end
  local red, green, blue = hex:match("#?(%x%x)(%x%x)(%x%x)")
  if not red or not green or not blue then return nil end

  return string.format(
    "{%d, %d, %d, 65535}",
    tonumber(red, 16) * 257,
    tonumber(green, 16) * 257,
    tonumber(blue, 16) * 257
  )
end

function M.set_primary_colors(colors)
  if type(colors) ~= "table" then return false end
  if vim.fn.executable("osascript") ~= 1 then return false end

  local background = M.color_value(colors.bg)
  local foreground = M.color_value(colors.fg)
  if not background or not foreground then return false end

  local script = table.concat({
    'tell application "iTerm2"',
    "if (count of windows) == 0 then error \"No active iTerm2 window\"",
    "tell current session of current tab of current window",
    "set background color to " .. background,
    "set foreground color to " .. foreground,
    "end tell",
    "end tell",
  }, "\n")

  vim.fn.system({ "osascript", "-e", script })
  return vim.v.shell_error == 0
end

function M.sync(theme, ctx)
  local term_program = vim.env.TERM_PROGRAM
  local in_iterm2 = term_program == "iTerm.app"
  local force_sync = vim.g.pure_iterm2_sync_always == true

  if not in_iterm2 and not force_sync then return false end

  local item = ctx.current_theme(theme)
  local mode = (ctx.theme_mode(item, vim.o.background) == "light") and "light" or "dark"
  local colors = alacritty.terminal_primary_colors(item, mode, ctx.sync_profile)
  local cache_key = table.concat({ item.key or "", colors.bg or "", colors.fg or "" }, "|")
  if vim.g._pure_iterm2_primary_last == cache_key then return true end

  if M.set_primary_colors(colors) then
    vim.g._pure_iterm2_primary_last = cache_key
    return true
  end

  vim.g._pure_iterm2_primary_last = cache_key
  if vim.g.pure_iterm2_sync_notify == true then
    vim.notify("iTerm2 sync not applied. Check AppleScript permissions and active iTerm window.", vim.log.levels.WARN)
  end
  return false
end

return M
