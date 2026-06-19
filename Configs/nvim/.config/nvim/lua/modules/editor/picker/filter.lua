local M = {}

function M.item_label(item, opts)
  if opts and type(opts.format_item) == "function" then
    return opts.format_item(item)
  end
  if type(item) == "table" then
    return item.label or item.path or item.name or vim.inspect(item)
  end
  return tostring(item)
end

function M.item_group(item, opts)
  if opts and type(opts.group_item) == "function" then
    local ok, group = pcall(opts.group_item, item)
    return ok and group or nil
  end
  return type(item) == "table" and item.group or nil
end

function M.item_matches(label, query)
  query = vim.trim(query or "")
  if query == "" then
    return true
  end

  local function glob_pattern(token)
    local escaped = vim.pesc(token)
    return escaped:gsub("%%%*", ".*"):gsub("%%%?", ".")
  end

  label = label:lower()
  for token in query:lower():gmatch("%S+") do
    if token:find("[*?]") then
      if not label:find(glob_pattern(token)) then
        return false
      end
    elseif not label:find(token, 1, true) then
      return false
    end
  end
  return true
end

function M.items(items, opts, query)
  local filtered = {}
  for _, item in ipairs(items) do
    if M.item_matches(M.item_label(item, opts), query) then
      filtered[#filtered + 1] = item
    end
  end
  return filtered
end

function M.by_predicate(items, predicate)
  local filtered = {}
  for _, item in ipairs(items) do
    local ok, keep = pcall(predicate, item)
    if ok and keep then
      filtered[#filtered + 1] = item
    end
  end
  return filtered
end

function M.by_regex(items, opts, pattern)
  local filtered = {}
  for _, item in ipairs(items) do
    local ok, matched = pcall(function()
      return M.item_label(item, opts):find(pattern) ~= nil
    end)
    if ok and matched then
      filtered[#filtered + 1] = item
    end
  end
  return filtered
end

function M.has_filters(filters)
  return type(filters) == "table" and not vim.tbl_isempty(filters)
end

function M.quick_filter_menu(filters)
  local menu = {}
  for _, filter in ipairs(filters or {}) do
    if filter.key and filter.label then
      menu[#menu + 1] = string.format("%s=%s", filter.key, filter.label)
    end
  end
  return table.concat(menu, "  ")
end

return M
