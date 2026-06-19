local M = {}

local java_project = require("modules.dap.java_project")

function M.java_project_name(path_hint)
  return java_project.name(path_hint)
end

function M.capabilities(session)
  return (session and session.capabilities) or {}
end

function M.normalize_error(err)
  if not err then return nil end
  if type(err) == "string" then return err end
  if type(err) ~= "table" then return tostring(err) end

  local msg = err.message
  if not msg and err.body and err.body.error then
    msg = err.body.error.message
  end
  if not msg and err.error then
    msg = err.error.message or err.error
  end
  return msg or vim.inspect(err)
end

local function notify_java_eval_hint(msg)
  if not msg then return end
  local lowered = msg:lower()
  if lowered:find("classnotfound")
      or lowered:find("noclassdeffound")
      or lowered:find("library")
      or lowered:find("module") then
    vim.notify(
      "Java DAP: possible classpath/module issue. Prefer JDTLS main-class config (not Current File), then :JdtUpdateConfig and restart debug session.",
      vim.log.levels.WARN
    )
  end

  if lowered:find("specify projectname") then
    vim.notify(
      "Java DAP: missing projectName on attach session. Auto-retry is enabled; if it persists, run :JdtUpdateConfig and re-attach.",
      vim.log.levels.WARN
    )
  end
end

local function is_missing_project_name_error(msg)
  if not msg then return false end
  return msg:lower():find("specify projectname") ~= nil
end

local function maybe_set_java_project_name(session)
  if not session or not session.config or session.config.type ~= "java" then return false end
  if type(session.config.projectName) == "string" and session.config.projectName ~= "" then return true end

  local frame_source_path = session.current_frame
    and session.current_frame.source
    and session.current_frame.source.path
  local buf_path = vim.api.nvim_buf_get_name(0)
  local hint = frame_source_path or (buf_path ~= "" and buf_path or nil)

  local resolved = M.java_project_name(hint)
  if not resolved then return false end
  session.config.projectName = resolved
  return true
end

function M.request(session, command, args, on_success, retry_count)
  if not session then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end

  session:request(command, args, function(err, response)
    if err then
      local msg = M.normalize_error(err)
      if (retry_count or 0) < 1 and is_missing_project_name_error(msg) and maybe_set_java_project_name(session) then
        M.request(session, command, args, on_success, 1)
        return
      end
      vim.schedule(function()
        notify_java_eval_hint(msg)
        vim.notify(string.format("DAP %s error: %s", command, msg), vim.log.levels.ERROR)
      end)
      return
    end
    if on_success then on_success(response) end
  end)
end

function M.current_frame_id(session)
  local frame = session and session.current_frame
  return frame and frame.id or nil
end

function M.eval_in_repl(dap, session, expr)
  local frame_id = M.current_frame_id(session)
  M.request(session, "evaluate", {
    expression = expr,
    context = "repl",
    frameId = frame_id,
  }, function(response)
    local result = response and response.result
    if result and result ~= "" then
      dap.repl.append(result)
      dap.repl.append("\n")
    end
  end)
end

return M
