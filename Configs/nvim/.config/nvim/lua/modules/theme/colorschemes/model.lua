local M = {}

function M.options(themes, picker_priority)
  local dark_items = {}
  local light_items = {}
  picker_priority = picker_priority or {}

  for _, theme in ipairs(themes) do
    local item = vim.tbl_extend("force", {}, theme, { source = "favorite" })
    if (theme.opts and theme.opts.background) == "light" then
      table.insert(light_items, item)
    else
      table.insert(dark_items, item)
    end
  end

  local function by_priority_then_label(a, b)
    local priority_a = picker_priority[a.key] or 999
    local priority_b = picker_priority[b.key] or 999
    if priority_a ~= priority_b then return priority_a < priority_b end
    return a.label < b.label
  end

  table.sort(dark_items, by_priority_then_label)
  table.sort(light_items, by_priority_then_label)

  local items = {}
  table.insert(items, { key = "_header_dark", label = "──────── High Contrast Dark ────────", source = "header" })
  vim.list_extend(items, dark_items)
  table.insert(items, { key = "_header_light", label = "──────── High Contrast Light ───────", source = "header" })
  vim.list_extend(items, light_items)

  return items
end

function M.resolve(theme, ctx)
  if type(theme) == "table" then return theme end

  local key = ctx.aliases[theme] or theme or ctx.default
  if ctx.theme_map[key] then return ctx.theme_map[key] end

  for _, item in ipairs(M.options(ctx.themes, ctx.picker_priority)) do
    if item.key == key or item.scheme == key then return item end
  end

  return ctx.theme_map[ctx.default]
end

function M.family_key(item)
  return item.plugin or ("builtin:" .. item.scheme)
end

function M.find_family_variant(themes, last_dark_by_family, item, mode)
  local family = M.family_key(item)
  local wanted = mode == "light" and "light" or "dark"
  local options = {}

  for _, theme in ipairs(themes) do
    if M.family_key(theme) == family and ((theme.opts and theme.opts.background) or "dark") == wanted then
      table.insert(options, theme)
    end
  end

  if #options == 0 then return nil end

  if wanted == "dark" then
    local remembered = last_dark_by_family[family]
    if remembered then
      for _, theme in ipairs(options) do
        if theme.key == remembered then return theme end
      end
    end
  end

  return options[1]
end

return M
