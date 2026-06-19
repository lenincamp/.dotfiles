local common = require("modules.theme.sync.common")
local palette = require("modules.theme.palette")

local M = {}

function M.replace_first(content, pattern, replacement)
  local updated, count = content:gsub(pattern, replacement, 1)
  if count == 0 then return content, false end
  return updated, true
end

function M.replace_section_value(content, section, key, value)
  local pattern = string.format("(%%[%s%%][%%s%%S]-\n%s%%s*=%%s*\")[^\"]+(\"[^\n]*\n?)", section, key)
  local updated, count = content:gsub(pattern, "%1" .. value .. "%2", 1)
  if count == 0 then return content, false end
  return updated, true
end

function M.upsert_palette_block(content, palette_name, block_lines)
  local header = "[palettes." .. palette_name .. "]"
  local lines = vim.split(content, "\n", { plain = true })

  local start_idx = nil
  for index, line in ipairs(lines) do
    if line == header then
      start_idx = index
      break
    end
  end

  if not start_idx then
    local trimmed = content:gsub("%s*$", "")
    return trimmed .. "\n\n" .. table.concat(block_lines, "\n") .. "\n"
  end

  local end_idx = #lines
  for index = start_idx + 1, #lines do
    if lines[index]:match("^%[.+%]$") then
      end_idx = index - 1
      break
    end
  end

  local merged = {}
  for index = 1, start_idx - 1 do
    table.insert(merged, lines[index])
  end
  vim.list_extend(merged, block_lines)
  for index = end_idx + 1, #lines do
    table.insert(merged, lines[index])
  end

  return table.concat(merged, "\n")
end

function M.render(content, item, mode)
  local colors = palette.build(mode)
  local palette_name = common.sanitize_key(item.key):gsub("-", "_")
  local updated = content

  updated = M.replace_first(updated, 'palette%s*=%s*"[^"]+"', 'palette = "' .. palette_name .. '"')
  updated = M.replace_section_value(updated, "directory", "style", "bold " .. colors.accent)
  updated = M.replace_section_value(updated, "git_branch", "style", "bold " .. colors.border)
  updated = M.replace_section_value(updated, "git_status", "style", "bold " .. colors.warn)
  updated = M.replace_section_value(updated, "nodejs", "style", "bold " .. colors.ok)
  updated = M.replace_section_value(updated, "cmd_duration", "style", "bold " .. colors.warn)
  updated = M.replace_section_value(updated, "status", "success_style", "bold " .. colors.ok)
  updated = M.replace_section_value(updated, "status", "failure_style", "bold " .. colors.error)

  return M.upsert_palette_block(updated, palette_name, {
    "[palettes." .. palette_name .. "]",
    "text = \"" .. colors.fg .. "\"",
    "surface0 = \"" .. colors.selection .. "\"",
    "surface1 = \"" .. colors.border .. "\"",
    "base = \"" .. colors.bg .. "\"",
    "blue = \"" .. colors.accent .. "\"",
    "green = \"" .. colors.ok .. "\"",
    "yellow = \"" .. colors.warn .. "\"",
    "red = \"" .. colors.error .. "\"",
  })
end

function M.sync(theme, ctx)
  local item = ctx.current_theme(theme)
  local mode = ctx.theme_mode(item, vim.o.background)
  local starship_path = vim.fn.expand("~/.config/starship.toml")
  local content = common.read_text_file(starship_path)
  if type(content) ~= "string" then return end

  local ok_write = pcall(common.write_text_file_if_changed, starship_path, M.render(content, item, mode))
  if not ok_write then
    vim.notify("starship theme sync failed: " .. starship_path, vim.log.levels.WARN)
  end
end

return M
