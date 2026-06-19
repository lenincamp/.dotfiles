-- Pack management commands: :PackInstall, :PackUpdate, :PackDelete, :PackList,
-- :PackPrune, :PackDoctor.
-- Usage: require("pack_manager").setup(packs, pack_dir)
--   packs    - module from lua/packs.lua (fields: list, name, origin)
--   pack_dir - absolute path to the opt/ directory

local M = {}
local build = require("pack_manager.build")
local doctor = require("pack_manager.doctor")
local native = require("pack_manager.native")
local orphans = require("pack_manager.orphans")
local query = require("pack_manager.query")

function M.setup(packs, pack_dir)
  vim.api.nvim_create_user_command("PackInstall", function(opts)
    local selected = query.filter_packs(packs, query.split_args(opts.args))
    if #selected == 0 then
      vim.notify("PackInstall: no matching declared plugins", vim.log.levels.WARN)
      return
    end

    local install = native.install()
    if not install then
      vim.notify("PackInstall requires Neovim 0.12+ with vim.pack", vim.log.levels.ERROR)
      return
    end

    local specs = packs.specs(selected)
    local ok, err = pcall(install, specs, { load = true })
    if not ok then
      ok, err = pcall(install, specs)
    end

    if not ok then
      vim.notify("PackInstall: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    local names = {}
    for _, pack in ipairs(selected) do
      table.insert(names, packs.name(pack))
    end

    vim.notify("PackInstall: handled " .. #names .. " plugin(s)", vim.log.levels.INFO)
    build.run_for(names, pack_dir)
    vim.cmd("silent! helptags ALL")
  end, {
    nargs = "*",
    complete = function()
      return vim.tbl_map(packs.name, packs.list)
    end,
    desc = "Install declared plugins (vim.pack)",
  })

  vim.api.nvim_create_user_command("PackUpdate", function(opts)
    local selected = query.filter_packs(packs, query.split_args(opts.args))
    local names = {}
    for _, pack in ipairs(selected) do
      table.insert(names, packs.name(pack))
    end

    if #names == 0 then
      vim.notify("PackUpdate: no matching declared plugins", vim.log.levels.WARN)
      return
    end

    local update = native.update()
    if not update then
      vim.notify("PackUpdate requires Neovim 0.12+ with vim.pack", vim.log.levels.ERROR)
      return
    end

    local ok, err = pcall(update, names)
    if not ok then
      vim.notify("PackUpdate: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.notify("PackUpdate: started for " .. #names .. " declared plugin(s)", vim.log.levels.INFO)
    build.run_for(names, pack_dir)
  end, {
    nargs = "*",
    complete = function()
      return vim.tbl_map(packs.name, packs.list)
    end,
    desc = "Update declared plugins (vim.pack)",
  })

  vim.api.nvim_create_user_command("PackDelete", function(opts)
    local names = query.split_args(opts.args)
    if #names == 0 then
      vim.notify("PackDelete: pass one or more plugin names", vim.log.levels.WARN)
      return
    end

    local failed = native.safe_delete(names)

    local dir_failed = {}
    for _, name in ipairs(names) do
      local path = pack_dir .. "/" .. name
      if vim.fn.isdirectory(path) == 1 and vim.fn.delete(path, "rf") ~= 0 then
        table.insert(dir_failed, name)
      end
    end

    for _, name in ipairs(dir_failed) do
      table.insert(failed, name .. " (dir)")
    end

    if #failed == 0 then
      vim.notify("PackDelete: removed " .. #names .. " plugin(s)", vim.log.levels.INFO)
    else
      vim.notify("PackDelete failed:\n" .. table.concat(failed, "\n"), vim.log.levels.WARN)
    end

    vim.cmd("silent! helptags ALL")
  end, {
    nargs = "+",
    complete = function()
      return vim.tbl_map(packs.name, packs.list)
    end,
    desc = "Delete explicit plugin names (native + dir cleanup)",
  })

  vim.api.nvim_create_user_command("PackList", function()
    local lines = native.installed_names()
    if #lines == 0 then
      local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
      table.sort(dirs)
      for _, dir in ipairs(dirs) do
        table.insert(lines, vim.fn.fnamemodify(dir, ":t"))
      end
    else
      table.sort(lines)
    end

    vim.notify("Plugins (" .. #lines .. "):\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "List installed plugins" })

  vim.api.nvim_create_user_command("PackPrune", function(opts)
    local orphan_items = orphans.collect(packs, pack_dir)
    if #orphan_items == 0 then
      vim.notify("PackPrune: no orphan plugins found", vim.log.levels.INFO)
      return
    end

    local view = {}
    for _, item in ipairs(orphan_items) do
      local tags = {}
      if item.native then table.insert(tags, "native") end
      if item.dir then table.insert(tags, "dir") end
      table.insert(view, item.name .. " [" .. table.concat(tags, ",") .. "]")
    end

    if not opts.bang then
      vim.notify(
        "PackPrune (dry-run):\n" .. table.concat(view, "\n") .. "\n\nUse :PackPrune! to remove these entries.",
        vim.log.levels.WARN
      )
      return
    end

    local native_names = {}
    local failed = {}

    for _, item in ipairs(orphan_items) do
      if item.native then
        table.insert(native_names, item.name)
      end
    end

    for _, name in ipairs(native.safe_delete(native_names)) do
      table.insert(failed, name .. " (native)")
    end

    for _, item in ipairs(orphan_items) do
      if item.dir and item.path and vim.fn.isdirectory(item.path) == 1 then
        if vim.fn.delete(item.path, "rf") ~= 0 then
          table.insert(failed, item.name .. " (dir)")
        end
      end
    end

    if #failed == 0 then
      vim.notify("PackPrune: pruned " .. #orphan_items .. " orphan plugin(s)", vim.log.levels.INFO)
    else
      vim.notify(
        "PackPrune pruned: " .. (#orphan_items - #failed) .. "\nPackPrune failed:\n" .. table.concat(failed, "\n"),
        vim.log.levels.WARN
      )
    end

    vim.cmd("silent! helptags ALL")
  end, {
    bang = true,
    desc = "Remove undeclared plugins (dry-run by default; use ! to apply)",
  })

  vim.api.nvim_create_user_command("PackDoctor", function()
    doctor.notify(packs, pack_dir)
  end, {
    desc = "Audit pack commands, duplicates, orphan installs, and potential orphan config files",
  })
end

return M
