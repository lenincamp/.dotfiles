local native = require("pack_manager.native")
local query = require("pack_manager.query")

local M = {}

function M.collect(packs, pack_dir)
  local expected = query.declared_pack_set(packs)
  local orphan_map = {}

  for _, name in ipairs(native.installed_names()) do
    if not expected[name] then
      orphan_map[name] = orphan_map[name] or {
        name = name,
        native = false,
        dir = false,
        path = nil,
      }
      orphan_map[name].native = true
    end
  end

  local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
  for _, dir in ipairs(dirs) do
    local name = vim.fn.fnamemodify(dir, ":t")
    if name ~= "" and not expected[name] then
      orphan_map[name] = orphan_map[name] or {
        name = name,
        native = false,
        dir = false,
        path = nil,
      }
      orphan_map[name].dir = true
      orphan_map[name].path = dir
    end
  end

  local orphans = {}
  for _, item in pairs(orphan_map) do
    table.insert(orphans, item)
  end

  table.sort(orphans, function(a, b)
    return a.name < b.name
  end)

  return orphans
end

function M.potential_config_files(packs)
  local config_dir = vim.fn.stdpath("config") .. "/plugins"
  if vim.fn.isdirectory(config_dir) ~= 1 then
    return {}
  end

  local allowed = query.declared_config_aliases(packs)
  local allowed_paths = {}
  local ok_registry, registry = pcall(require, "modules.plugins.registry")
  if ok_registry and type(registry.configs) == "table" then
    for _, spec in pairs(registry.configs) do
      if type(spec) == "table" and type(spec.path) == "string" then
        allowed_paths[spec.path] = true
      end
    end
  end

  local files = vim.fn.glob(config_dir .. "/**/*.lua", false, true)
  local potential = {}

  for _, file in ipairs(files) do
    local stem = vim.fn.fnamemodify(file, ":t:r")
    local rel = file:sub(#config_dir + 2)
    if stem ~= "" and not allowed[stem:lower()] and not allowed_paths[rel] then
      table.insert(potential, vim.fn.fnamemodify(file, ":~:."))
    end
  end

  table.sort(potential)
  return potential
end

return M
