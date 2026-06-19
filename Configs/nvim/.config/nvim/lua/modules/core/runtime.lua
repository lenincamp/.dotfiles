local M = {}

local loader_api = {}
local lsp_api = {}
local diff_api = {}

function M.set_loader_api(api)
  loader_api = type(api) == "table" and api or {}
end

function M.load_config(name)
  if type(loader_api.load_config) == "function" then
    return loader_api.load_config(name)
  end
  return false
end

function M.load_pack(name)
  if type(loader_api.load_pack) == "function" then
    return loader_api.load_pack(name)
  end
  return false
end

function M.resolve_plugin_config(name)
  if type(loader_api.resolve_config_path) == "function" then
    return loader_api.resolve_config_path(name)
  end
  return nil
end

function M.set_lsp_api(api)
  lsp_api = type(api) == "table" and api or {}
end

function M.enable_lsp_for_buffer(bufnr, opts)
  if type(lsp_api.enable_for_buffer) == "function" then
    return lsp_api.enable_for_buffer(bufnr, opts)
  end
  return 0
end

function M.set_diff_api(api)
  diff_api = type(api) == "table" and api or {}
end

function M.setup_diff_mappings(...)
  if type(diff_api.setup) == "function" then
    return diff_api.setup(...)
  end
end

function M.cleanup_diff_mappings(...)
  if type(diff_api.cleanup) == "function" then
    return diff_api.cleanup(...)
  end
end

return M
