local M = {}

function M.api()
  local pack_api = rawget(vim, "pack")
  if type(pack_api) == "table" then
    return pack_api
  end

  local ok, resolved = pcall(function()
    return vim.pack
  end)
  if ok and type(resolved) == "table" then
    return resolved
  end

  return nil
end

function M.install()
  local pack_api = M.api()
  return pack_api and (pack_api.add or pack_api.install)
end

function M.update()
  local pack_api = M.api()
  return pack_api and pack_api.update
end

function M.delete()
  local pack_api = M.api()
  return pack_api and (pack_api.del or pack_api.delete)
end

function M.get()
  local pack_api = M.api()
  return pack_api and pack_api.get
end

function M.installed_names()
  local get = M.get()
  if not get then return {} end

  local ok, installed = pcall(get)
  if not ok or type(installed) ~= "table" then return {} end

  local names = {}
  for name, plugin in pairs(installed) do
    if type(name) == "number" and type(plugin) == "table" then
      name = plugin.name or (plugin.spec and plugin.spec.name)
    end
    if name then
      table.insert(names, tostring(name))
    end
  end
  return names
end

function M.safe_delete(names)
  local delete = M.delete()
  if not delete then
    return names
  end

  local failed = {}
  local ok = pcall(delete, names)
  if ok then
    return failed
  end

  for _, name in ipairs(names) do
    local one_ok = pcall(delete, { name })
    if not one_ok then
      one_ok = pcall(delete, name)
    end
    if not one_ok then
      table.insert(failed, name)
    end
  end

  return failed
end

return M
