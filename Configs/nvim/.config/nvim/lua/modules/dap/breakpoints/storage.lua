local M = {}

local path_core = require("modules.core.path")

function M.storage_dir()
  return vim.fn.stdpath("data") .. "/breakpoints"
end

function M.data_dir()
  local dir = M.storage_dir()
  vim.fn.mkdir(dir, "p")
  return dir
end

function M.project_root()
  return path_core.project_root(vim.fn.getcwd(), { "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", "package.json" })
end

function M.project_key()
  return path_core.project_key(M.project_root())
end

function M.bp_path(key)
  return M.data_dir() .. "/" .. (key or M.project_key()) .. ".json"
end

function M.meta_path(key)
  return M.data_dir() .. "/" .. (key or M.project_key()) .. ".meta.json"
end

function M.bp_key(fname, line)
  return fname .. ":" .. tostring(line)
end

function M.load_meta(key)
  local file = io.open(M.meta_path(key), "r")
  if not file then
    return {}
  end

  local raw = file:read("*a")
  file:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  return ok and decoded or {}
end

function M.save_meta(meta, key)
  local file = io.open(M.meta_path(key), "w")
  if file then
    file:write(vim.json.encode(meta))
    file:close()
  end
end

return M
