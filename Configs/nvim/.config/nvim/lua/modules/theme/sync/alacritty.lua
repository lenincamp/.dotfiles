local common = require("modules.theme.sync.common")
local palette = require("modules.theme.palette")

local M = {}

local function replace_toml_string_value(line, key, value)
  local prefix, suffix = line:match("^(%s*" .. key .. "%s*=%s*\")[^\"]*(\".*)$")
  if prefix then
    return prefix .. value .. suffix, true
  end

  prefix, suffix = line:match("^(%s*" .. key .. "%s*=%s*')[^']*('.*)$")
  if prefix then
    return prefix .. value .. suffix, true
  end

  return line, false
end

function M.replace_primary_values(content, colors)
  local has_final_newline = content:sub(-1) == "\n"
  local lines = vim.split(content, "\n", { plain = true })
  local in_primary = false
  local background_updated = false
  local foreground_updated = false

  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end

  for index, line in ipairs(lines) do
    local section = line:match("^%s*%[([^%]]+)%]%s*$")
    if section then
      in_primary = section == "colors.primary"
    elseif in_primary then
      local updated_line = line
      if not background_updated then
        updated_line, background_updated = replace_toml_string_value(updated_line, "background", colors.bg)
      end
      if not foreground_updated then
        updated_line, foreground_updated = replace_toml_string_value(updated_line, "foreground", colors.fg)
      end
      lines[index] = updated_line
    end
  end

  if not background_updated or not foreground_updated then
    return content, false
  end

  local updated = table.concat(lines, "\n")
  if has_final_newline then
    updated = updated .. "\n"
  end

  return updated, true
end

function M.terminal_primary_colors(item, mode, sync_profile)
  local colors = palette.build(mode)
  local profile = sync_profile(item)
  local terminal = type(profile.terminal) == "table" and profile.terminal
    or type(profile.alacritty) == "table" and profile.alacritty
    or {}

  return {
    bg = terminal.background or colors.bg,
    fg = terminal.foreground or colors.fg,
  }
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item, vim.o.background)
  local colors = M.terminal_primary_colors(item, mode, ctx.sync_profile)
  local path = vim.fn.expand("~/.config/alacritty/alacritty.toml")
  local content = common.read_text_file(path)
  if type(content) ~= "string" then return end

  local updated, changed = M.replace_primary_values(content, colors)
  if not changed then return end

  local ok_write = pcall(common.write_text_file_if_changed, path, updated)
  if not ok_write then
    vim.notify("alacritty theme sync failed: " .. path, vim.log.levels.WARN)
  end
end

return M
