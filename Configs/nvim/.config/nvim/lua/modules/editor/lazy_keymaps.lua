local M = {}

local replaying_lhs = {}

local function run_loader(load_cfg_once, loader)
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

local function set_lazy_keys(load_cfg_once, default_loader, load_label, mappings)
  local function replay(lhs, mapping_loader)
    if replaying_lhs[lhs] then
      return
    end

    if not run_loader(load_cfg_once, mapping_loader or default_loader) then
      return
    end

    replaying_lhs[lhs] = true
    vim.schedule(function()
      local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
      vim.api.nvim_feedkeys(keys, "m", false)
      replaying_lhs[lhs] = nil
    end)
  end

  for _, mapping in ipairs(mappings) do
    vim.keymap.set(mapping.mode or "n", mapping.lhs, function()
      replay(mapping.lhs, mapping.loader)
    end, {
      silent = true,
      nowait = mapping.nowait,
      desc = mapping.desc or ("Load " .. load_label),
    })
  end
end

function M.setup(load_cfg_once)
  if type(load_cfg_once) ~= "function" then
    return
  end

  local ok_dap_keymaps, dap_keymaps = pcall(require, "modules.dap.keymaps")
  local ok_test_runner, test_runner = pcall(require, "modules.testing.runner")
  local ok_mybatis_keymaps, mybatis_keymaps = pcall(require, "modules.editor.mybatis_keymaps")

  local dap_core_loader = "nvim-dap"

  if ok_test_runner and type(test_runner.lazy_specs) == "function" then
    set_lazy_keys(load_cfg_once, function()
      test_runner.setup_keymaps()
      return true
    end, "tests", test_runner.lazy_specs())
  end

  if ok_mybatis_keymaps and type(mybatis_keymaps.lazy_specs) == "function" then
    set_lazy_keys(load_cfg_once, function()
      local ok_mybatis, mybatis = pcall(require, "modules.editor.mybatis")
      if not ok_mybatis then
        return false
      end
      mybatis_keymaps.apply(mybatis)
      return true
    end, "mybatis", mybatis_keymaps.lazy_specs())
  end

  if ok_dap_keymaps and type(dap_keymaps.lazy_specs) == "function" then
    set_lazy_keys(load_cfg_once, dap_core_loader, "dap", dap_keymaps.lazy_specs())
  end

  set_lazy_keys(load_cfg_once, "minuet", "minuet", {
    { mode = "n", lhs = "<leader>amp", desc = "Minuet: NES predict" },
    { mode = "n", lhs = "<leader>ama", desc = "Minuet: NES apply" },
    { mode = "n", lhs = "<leader>amd", desc = "Minuet: NES dismiss" },
  })

  set_lazy_keys(load_cfg_once, "dadbod", "dadbod", {
    { mode = "n", lhs = "<leader>Du", desc = "Dadbod: toggle UI" },
    { mode = "n", lhs = "<leader>Df", desc = "Dadbod: find buffer" },
    { mode = "n", lhs = "<leader>Da", desc = "Dadbod: add connection" },
    { mode = "n", lhs = "<leader>Dr", desc = "Dadbod: rename buffer" },
  })

  for _, command in ipairs({
    "DB",
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
    "DBUIRenameBuffer",
    "DBUIDeleteBuffer",
    "DBUILastQueryInfo",
  }) do
    vim.api.nvim_create_user_command(command, function(opts)
      pcall(vim.api.nvim_del_user_command, command)
      load_cfg_once("dadbod")
      local range = opts.range > 0 and (opts.line1 .. "," .. opts.line2) or ""
      vim.cmd(range .. command .. (opts.bang and "!" or "") .. (opts.args ~= "" and " " .. opts.args or ""))
    end, { bang = true, nargs = "*", complete = "file", range = true })
  end

end

return M