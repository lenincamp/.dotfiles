local M = {}

local build_commands = {}

function M.set_commands(commands)
  build_commands = commands or {}
end

function M.run(name, dir)
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

function M.run_for(names, pack_dir)
  for _, name in ipairs(names) do
    M.run(name, pack_dir .. "/" .. name)
  end
end

return M
