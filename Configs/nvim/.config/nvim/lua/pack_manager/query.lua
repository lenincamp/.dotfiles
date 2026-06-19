local M = {}

function M.split_args(args)
  local names = {}
  for name in (args or ""):gmatch("%S+") do
    table.insert(names, name)
  end
  return names
end

function M.declared_pack_names(packs)
  local names = {}
  for _, pack in ipairs(packs.list) do
    table.insert(names, packs.name(pack))
  end
  return names
end

function M.declared_pack_set(packs)
  local set = {}
  for _, name in ipairs(M.declared_pack_names(packs)) do
    set[name] = true
  end
  return set
end

function M.filter_packs(packs, names)
  if #names == 0 then return packs.list end

  local wanted = {}
  for _, name in ipairs(names) do
    wanted[name] = true
  end

  local filtered = {}
  for _, pack in ipairs(packs.list) do
    local name = packs.name(pack)
    if wanted[name] or wanted[packs.origin(pack)] then
      table.insert(filtered, pack)
    end
  end
  return filtered
end

function M.config_aliases_for_pack(name)
  local aliases = {}

  local function add(value)
    if value and value ~= "" then
      aliases[value:lower()] = true
    end
  end

  local raw = name:lower()
  add(raw)
  add(raw:gsub("%.nvim$", ""))
  add(raw:gsub("%.lua$", ""))
  add(raw:gsub("^nvim%-", ""))

  local dashed = raw:gsub("[._]", "-")
  add(dashed)
  add(dashed:gsub("%.nvim$", ""))
  add(dashed:gsub("%.lua$", ""))
  add(dashed:gsub("^nvim%-", ""))

  if raw:find("^mini%.") then
    add(raw:gsub("^mini%.", "mini-"))
  end

  return aliases
end

function M.declared_config_aliases(packs)
  local aliases = {}
  for _, name in ipairs(M.declared_pack_names(packs)) do
    for alias in pairs(M.config_aliases_for_pack(name)) do
      aliases[alias] = true
    end
  end

  for _, name in ipairs({ "bars", "search", "persistence", "tests", "mybatis" }) do
    aliases[name] = true
  end

  return aliases
end

function M.duplicate_declared_packs(packs)
  local counts = {}
  for _, pack in ipairs(packs.list) do
    local name = packs.name(pack)
    counts[name] = (counts[name] or 0) + 1
  end

  local duplicates = {}
  for name, count in pairs(counts) do
    if count > 1 then
      table.insert(duplicates, name .. " x" .. count)
    end
  end
  table.sort(duplicates)
  return duplicates
end

return M
