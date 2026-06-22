local M = {}

function M.run_async(command, opts, on_done)
  if type(command) ~= "table" or #command == 0 then
    return false
  end

  opts = opts or {}
  vim.system(command, opts, function(result)
    if type(on_done) == "function" then
      vim.schedule(function()
        on_done(result or {})
      end)
    end
  end)
  return true
end

function M.notify_on_failure(label, result)
  if not result or result.code == 0 then
    return
  end

  local stderr = vim.trim(result.stderr or "")
  local stdout = vim.trim(result.stdout or "")
  local detail = stderr ~= "" and stderr or stdout
  vim.notify(label .. (detail ~= "" and (": " .. detail) or " failed"), vim.log.levels.WARN)
end

function M.systemlist(command)
  local result = vim.system(command, { text = true }):wait()
  local stdout = result and result.stdout or ""
  local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
  return lines, result and result.code or 1
end

function M.open_terminal(command, opts)
  opts = opts or {}
  local height = opts.height or 15
  local position = opts.position or "botright"
  vim.cmd(position .. " " .. height .. "split | terminal " .. command)
end

function M.tmux_send_keys(target, command)
  if vim.fn.executable("tmux") ~= 1 then
    vim.notify("tmux is not available", vim.log.levels.WARN)
    return false
  end

  return M.run_async({ "tmux", "send-keys", "-t", target, command, "C-m" }, { text = true }, function(result)
    M.notify_on_failure("tmux send-keys", result)
  end)
end

return M
