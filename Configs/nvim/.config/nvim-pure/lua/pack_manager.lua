-- Pack management commands: :PackInstall, :PackUpdate, :PackList.
-- Usage: require("pack_manager").setup(packs, pack_dir)
--   packs    — module from lua/packs.lua (fields: list, name, origin)
--   pack_dir — absolute path to the opt/ directory

local M = {}

local on_all_done

local build_commands = {
  ["avante.nvim"] = { "make" },
}

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

  vim.api.nvim_create_user_command("PackInstall", function()
    local missing = {}
    for _, pack in ipairs(packs.list) do
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
      local origin = packs.origin(pack)
      local url    = origin:match("^https?://") and origin or ("https://github.com/" .. origin)
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
  end, { desc = "Clone missing plugins from their origins" })

  vim.api.nvim_create_user_command("PackUpdate", function()
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
  end, { desc = "Git pull all installed plugins" })

  vim.api.nvim_create_user_command("PackList", function()
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
