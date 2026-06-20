local M = {}

local function query_tokens(query)
  local tokens = {}
  for token in vim.trim(query or ""):lower():gmatch("%S+") do
    tokens[#tokens + 1] = {
      glob = token:find("[*?]") ~= nil,
      text = token,
    }
  end
  return tokens
end

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

local function fuzzy_positions(lower_label, token)
  local positions = {}
  local cursor = 1

  for index = 1, #token do
    local char = token:sub(index, index)
    local found = lower_label:find(char, cursor, true)
    if not found then
      return nil
    end
    positions[#positions + 1] = found
    cursor = found + 1
  end

  return positions
end

local function fuzzy_token_score(lower_label, token)
  local cursor = 1
  local first = nil
  local previous = nil
  local score = 0

  for index = 1, #token do
    local found = lower_label:find(token:sub(index, index), cursor, true)
    if not found then
      return nil
    end
    first = first or found
    if previous and found == previous + 1 then
      score = score + 12
    end
    previous = found
    cursor = found + 1
  end

  return score + 100 - first
end

local function fuzzy_score(label, tokens)
  if #tokens == 0 then
    return 0
  end

  local score = 0
  local lower = label:lower()
  for _, token in ipairs(tokens) do
    if token.glob then
      if not M.item_matches(label, token.text) then
        return nil
      end
      score = score + 20
    else
      if lower:find(token.text, 1, true) then
        score = score + 50
      end
      local token_score = fuzzy_token_score(lower, token.text)
      if not token_score then
        return nil
      end
      score = score + token_score
    end
  end

  return score
end

local function better(a, b)
  if a.score ~= b.score then
    return a.score > b.score
  end
  return a.label < b.label
end

local function worse(a, b)
  return better(b, a)
end

local function heap_sift_up(heap, index)
  while index > 1 do
    local parent = math.floor(index / 2)
    if not worse(heap[index], heap[parent]) then
      break
    end
    heap[index], heap[parent] = heap[parent], heap[index]
    index = parent
  end
end

local function heap_sift_down(heap, index)
  local size = #heap
  while true do
    local left = index * 2
    local right = left + 1
    local smallest = index
    if left <= size and worse(heap[left], heap[smallest]) then
      smallest = left
    end
    if right <= size and worse(heap[right], heap[smallest]) then
      smallest = right
    end
    if smallest == index then
      break
    end
    heap[index], heap[smallest] = heap[smallest], heap[index]
    index = smallest
  end
end

local function heap_push(heap, entry, limit)
  if #heap < limit then
    heap[#heap + 1] = entry
    heap_sift_up(heap, #heap)
    return
  end
  if better(entry, heap[1]) then
    heap[1] = entry
    heap_sift_down(heap, 1)
  end
end

function M.match_positions(label, query)
  local all = {}
  query = vim.trim(query or "")
  if query == "" then
    return all
  end

  for token in query:gmatch("%S+") do
    if not token:find("[*?]") then
      local positions = fuzzy_positions(label:lower(), token:lower())
      if positions then
        vim.list_extend(all, positions)
      end
    end
  end
  return all
end

function M.items(items, opts, query)
  opts = opts or {}
  local tokens = query_tokens(query)
  local use_limit = #tokens > 0 and opts.filter_limit ~= false
  local limit = tonumber(opts.filter_limit) or 5000
  local entries = {}

  for _, item in ipairs(items) do
    local label = M.item_label(item, opts)
    local score = fuzzy_score(label, tokens)
    if score then
      local entry = { item = item, label = label, score = score }
      if use_limit then
        heap_push(entries, entry, limit)
      else
        entries[#entries + 1] = entry
      end
    end
  end

  if #tokens > 0 then
    table.sort(entries, better)
  end

  local filtered = {}
  for index, entry in ipairs(entries) do
    filtered[index] = entry.item
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
