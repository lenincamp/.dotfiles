local servers_by_filetype = {
  lua = { "lua_ls" },
  kotlin = { "kotlin_language_server" },
  sh = { "bashls" },
  bash = { "bashls" },
  zsh = { "bashls" },
  vim = { "vimls" },
  dockerfile = { "dockerls" },
  xml = { "lemminx" },
  markdown = { "marksman" },
  ["markdown.mdx"] = { "marksman" },
  toml = { "taplo" },
  yaml = { "yamlls" },
  ["yaml.docker-compose"] = { "docker_compose_language_service" },

  javascript = { "vtsls", "eslint", "lwc_ls" },
  javascriptreact = { "vtsls", "eslint", "tailwindcss" },
  typescript = { "vtsls", "eslint" },
  typescriptreact = { "vtsls", "eslint", "tailwindcss" },

  html = { "eslint", "tailwindcss", "lwc_ls" },
  css = { "tailwindcss" },
  scss = { "tailwindcss" },
  less = { "tailwindcss" },
  vue = { "tailwindcss" },
  svelte = { "tailwindcss" },

  apex = { "apex_ls" },
  visualforce = { "visualforce_ls" },
}

local function servers_for_filetype(filetype)
  return servers_by_filetype[filetype]
end

local M = {}

local enabled_servers = {}

local WEB_PRIMARY_LSP = "vtsls"
local WEB_SECONDARY_LSP_DEFER_MS = 10

local function enable_server_once(server)
  if enabled_servers[server] then
    return true
  end

  local ok, err = pcall(vim.lsp.enable, { server })
  if not ok then
    ok, err = pcall(vim.lsp.enable, server)
  end

  if not ok then
    vim.notify("LSP enable failed [" .. server .. "]: " .. tostring(err), vim.log.levels.WARN)
    return false
  end

  enabled_servers[server] = true
  return true
end

local function has_client_for_buffer(server, bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = server })) do
    if client.name == server then
      return true
    end
  end
  return false
end

local function start_server_for_buffer(server, bufnr)
  if has_client_for_buffer(server, bufnr) then
    return
  end

  local base = vim.lsp.config[server]
  if type(base) ~= "table" then
    return
  end
  if type(base.cmd) ~= "table" then
    return
  end

  local function start_with_config(config)
    config.name = config.name or server
    pcall(vim.lsp.start, config, {
      bufnr = bufnr,
      reuse_client = function(client, candidate)
        return client.name == server
          and client.config
          and candidate
          and client.config.root_dir == candidate.root_dir
      end,
    })
  end

  local root_dir = base.root_dir
  if type(root_dir) == "function" then
    pcall(root_dir, bufnr, function(root)
      if type(root) ~= "string" or root == "" then
        return
      end
      local config = vim.deepcopy(base)
      config.root_dir = root
      if type(config.build_settings) == "function" then
        config.settings = vim.tbl_deep_extend("force", config.settings or {}, config.build_settings(root))
      end
      config.build_settings = nil
      start_with_config(config)
    end)
    return
  end

  start_with_config(vim.deepcopy(base))
end

local function should_skip_buffer(bufnr, opts)
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return true
  end

  if vim.bo[bufnr].buftype ~= "" then
    return true
  end

  if opts.force then
    return false
  end

  if vim.opt.diff:get() then
    return true
  end

  if vim.b[bufnr].diff_lsp_disabled then
    return true
  end

  return false
end

function M.enable_for_buffer(bufnr, opts)
  opts = opts or {}
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if should_skip_buffer(bufnr, opts) then
    return 0
  end

  local ft = vim.bo[bufnr].filetype
  local servers = servers_for_filetype(ft)
  if type(servers) ~= "table" then
    return 0
  end

  local enabled_count = 0
  for _, server in ipairs(servers) do
    local allowed = (not opts.only_server or opts.only_server == server)
      and not (opts.skip_servers and opts.skip_servers[server])
    if allowed and enable_server_once(server) then
      start_server_for_buffer(server, bufnr)
      enabled_count = enabled_count + 1
    end
  end

  return enabled_count
end

local function should_defer_lsp(bufnr)
  local servers = servers_for_filetype(vim.bo[bufnr].filetype)
  if type(servers) ~= "table" then
    return false
  end

  for _, server in ipairs(servers) do
    if server == WEB_PRIMARY_LSP then
      return true
    end
  end

  return false
end

function M.request_enable_for_buffer(bufnr)
  if should_defer_lsp(bufnr) then
    M.enable_for_buffer(bufnr, { only_server = WEB_PRIMARY_LSP })

    vim.defer_fn(function()
      M.enable_for_buffer(bufnr, { skip_servers = { [WEB_PRIMARY_LSP] = true } })
    end, WEB_SECONDARY_LSP_DEFER_MS)
    return
  end

  M.enable_for_buffer(bufnr)
end

return M
