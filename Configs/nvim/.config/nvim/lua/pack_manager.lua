-- Pack management commands: :PackInstall, :PackUpdate, :PackDelete, :PackList.
-- Usage: require("pack_manager").setup(packs, pack_dir)
--   packs    — module from lua/packs.lua (fields: list, name, origin)
--   pack_dir — absolute path to the opt/ directory

local M = {}

local on_all_done

local build_commands = {
  ["avante.nvim"] = { "make" },
}

local function native_install()
  return vim.pack and (vim.pack.add or vim.pack.install)
end

local function native_update()
  return vim.pack and vim.pack.update
end

local function native_delete()
  return vim.pack and (vim.pack.del or vim.pack.delete)
end

local function split_args(args)
  local names = {}
  for name in args:gmatch("%S+") do
    table.insert(names, name)
  end
  return names
end

local function filter_packs(packs, names)
  if #names == 0 then return packs.list end

  local wanted = {}
  for _, name in ipairs(names) do wanted[name] = true end

  local filtered = {}
  for _, pack in ipairs(packs.list) do
    local name = packs.name(pack)
    if wanted[name] or wanted[packs.origin(pack)] then
      table.insert(filtered, pack)
    end
  end
  return filtered
end

local function run_build(name, dir)
  local command = build_commands[name]
  if not command then return end

  vim.system(command, { cwd = dir, text = true }, function(out)
    vim.schedule(function()
      if out.code == 0 then
        vim.notify(name .. " build ok", vim.log.levels.INFO)
      else
        vim.notify(name .. " build: " .. vim.trim(out.stderr), vim.log.levels.WARN)
      end
    end)
  end)
end

local function run_builds_for(names, pack_dir)
  for _, name in ipairs(names) do
    run_build(name, pack_dir .. "/" .. name)
  end
end

local function finish_pack(done, total, errors, label)
  done.value = done.value + 1
  on_all_done(done.value, total, errors, label)
end

local function run_build_if_needed(name, dir, done, total, errors, label)
  local command = build_commands[name]
  if not command then
    finish_pack(done, total, errors, label)
    return
  end

  vim.system(command, { cwd = dir, text = true }, function(out)
    if out.code ~= 0 then
      table.insert(errors, name .. " build: " .. vim.trim(out.stderr))
    end
    finish_pack(done, total, errors, label)
  end)
end

-- Shared async completion handler; notifies and regenerates help tags when
-- all parallel git operations finish.
function on_all_done(done, total, errors, label)
  if done ~= total then return end
  vim.schedule(function()
    if #errors == 0 then
      vim.notify(label .. ": " .. total .. " plugin(s) ok ✓", vim.log.levels.INFO)
    else
      vim.notify(label .. " error(s):\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
    end
    vim.cmd("silent! helptags ALL")
  end)
end

function M.setup(packs, pack_dir)

  vim.api.nvim_create_user_command("PackInstall", function(opts)
    local names = split_args(opts.args)
    local selected = filter_packs(packs, names)

    local install = native_install()
    if install then
      local ok, err = pcall(install, packs.specs(selected), { load = true })
      if not ok then ok, err = pcall(install, packs.specs(selected)) end
      if ok then
        vim.notify("PackInstall: vim.pack handled " .. #selected .. " plugin(s)", vim.log.levels.INFO)
        local built = {}
        for _, pack in ipairs(selected) do table.insert(built, packs.name(pack)) end
        run_builds_for(built, pack_dir)
      else
        vim.notify("PackInstall: " .. tostring(err), vim.log.levels.ERROR)
      end
      return
    end

    local missing = {}
    for _, pack in ipairs(selected) do
      if vim.fn.isdirectory(pack_dir .. "/" .. packs.name(pack)) == 0 then
        table.insert(missing, pack)
      end
    end

    if #missing == 0 then
      vim.notify("PackInstall: all plugins already installed ✓", vim.log.levels.INFO)
      return
    end

    local total, done, errors = #missing, { value = 0 }, {}
    vim.notify("PackInstall: cloning " .. total .. " missing plugin(s)…", vim.log.levels.INFO)

    for _, pack in ipairs(missing) do
      local name   = packs.name(pack)
      local url    = packs.url(pack)
      vim.system(
        { "git", "clone", "--depth", "1", url, pack_dir .. "/" .. name },
        { text = true },
        function(out)
          if out.code ~= 0 then
            table.insert(errors, name .. ": " .. vim.trim(out.stderr))
            finish_pack(done, total, errors, "PackInstall")
            return
          end
          run_build_if_needed(name, pack_dir .. "/" .. name, done, total, errors, "PackInstall")
        end
      )
    end
  end, {
    nargs = "*",
    complete = function() return vim.tbl_map(packs.name, packs.list) end,
    desc = "Install plugins with vim.pack, or clone missing plugins as fallback",
  })

  vim.api.nvim_create_user_command("PackUpdate", function(opts)
    local names = split_args(opts.args)
    local update = native_update()
    if update then
      local ok, err
      if #names == 0 then
        ok, err = pcall(update)
      else
        ok, err = pcall(update, names)
      end
      if ok then
        vim.notify("PackUpdate: vim.pack update started", vim.log.levels.INFO)
        run_builds_for(#names == 0 and vim.tbl_keys(build_commands) or names, pack_dir)
      else
        vim.notify("PackUpdate: " .. tostring(err), vim.log.levels.ERROR)
      end
      return
    end

    local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
    if #dirs == 0 then
      vim.notify("PackUpdate: no plugins installed", vim.log.levels.INFO)
      return
    end

    local total, done, errors = #dirs, { value = 0 }, {}
    vim.notify("PackUpdate: updating " .. total .. " plugins…", vim.log.levels.INFO)

    for _, dir in ipairs(dirs) do
      local name = vim.fn.fnamemodify(dir, ":t")
      vim.system(
        { "sh", "-c",
          "cd " .. dir ..
          " && git fetch origin" ..
          " && git reset --hard origin/$(git rev-parse --abbrev-ref origin/HEAD | cut -d'/' -f2)"
        },
        { text = true },
        function(out)
          if out.code ~= 0 then
            table.insert(errors, name .. ": " .. vim.trim(out.stderr))
            finish_pack(done, total, errors, "PackUpdate")
            return
          end
          run_build_if_needed(name, dir, done, total, errors, "PackUpdate")
        end
      )
    end
  end, {
    nargs = "*",
    complete = function() return vim.tbl_map(packs.name, packs.list) end,
    desc = "Update plugins with vim.pack, or git fallback",
  })

  vim.api.nvim_create_user_command("PackDelete", function(opts)
    local names = split_args(opts.args)
    if #names == 0 then
      vim.notify("PackDelete: pass one or more plugin names", vim.log.levels.WARN)
      return
    end

    local delete = native_delete()
    if delete then
      local ok, err = pcall(delete, names)
      if ok then
        vim.notify("PackDelete: vim.pack removed " .. #names .. " plugin(s)", vim.log.levels.INFO)
      else
        vim.notify("PackDelete: " .. tostring(err), vim.log.levels.ERROR)
      end
      return
    end

    for _, name in ipairs(names) do
      local path = pack_dir .. "/" .. name
      if vim.fn.isdirectory(path) == 1 then
        vim.fn.delete(path, "rf")
      end
    end
    vim.notify("PackDelete: removed " .. #names .. " plugin(s)", vim.log.levels.INFO)
  end, {
    nargs = "+",
    complete = function() return vim.tbl_map(packs.name, packs.list) end,
    desc = "Delete plugins with vim.pack, or remove pack directories as fallback",
  })

  vim.api.nvim_create_user_command("PackList", function()
    if vim.pack and vim.pack.get then
      local ok, installed = pcall(vim.pack.get)
      if ok and type(installed) == "table" then
        local lines = {}
        for name, plugin in pairs(installed) do
          if type(name) == "number" and type(plugin) == "table" then name = plugin.name or plugin.spec and plugin.spec.name end
          if name then table.insert(lines, tostring(name)) end
        end
        table.sort(lines)
        vim.notify("Plugins (" .. #lines .. "):\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
        return
      end
    end

    local dirs = vim.fn.glob(pack_dir .. "/*", false, true)
    table.sort(dirs)
    local lines = {}
    for _, dir in ipairs(dirs) do
      table.insert(lines, vim.fn.fnamemodify(dir, ":t"))
    end
    vim.notify("Plugins (" .. #lines .. "):\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "List installed plugins" })

end

return M
