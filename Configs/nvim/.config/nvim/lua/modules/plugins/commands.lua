local M = {}

local function load_lazy_config(load_cfg_once, loader)
  if type(loader) == "function" then
    return loader()
  end

  if type(loader) == "table" then
    for _, name in ipairs(loader) do
      if not load_cfg_once(name) then
        return false
      end
    end
    return true
  end

  if type(loader) == "string" and loader ~= "" then
    return load_cfg_once(loader)
  end

  return false
end

local function register_lazy_command(run_lazy_loader, loader, cmd_name)
  if vim.fn.exists(":" .. cmd_name) == 2 then
    return
  end

  vim.api.nvim_create_user_command(cmd_name, function(opts)
    pcall(vim.api.nvim_del_user_command, cmd_name)

    if not run_lazy_loader(loader) then
      return
    end

    local bang = opts.bang and "!" or ""
    local args = opts.args ~= "" and (" " .. opts.args) or ""
    vim.cmd(cmd_name .. bang .. args)
  end, {
    nargs = "*",
    bang = true,
    desc = "Lazy command wrapper for :" .. cmd_name,
  })
end

function M.setup(registry, load_cfg_once)
  local function run_lazy_loader(loader)
    return load_lazy_config(load_cfg_once, loader)
  end

  for _, cmd_name in ipairs(registry.mason_lazy_commands) do
    register_lazy_command(run_lazy_loader, "mason", cmd_name)
  end

  for _, cmd_name in ipairs(registry.dap_core_lazy_commands) do
    register_lazy_command(run_lazy_loader, "nvim-dap", cmd_name)
  end

  for _, cmd_name in ipairs(registry.dap_view_lazy_commands) do
    register_lazy_command(run_lazy_loader, { "nvim-dap", "nvim-dap-view" }, cmd_name)
  end
end

return M
