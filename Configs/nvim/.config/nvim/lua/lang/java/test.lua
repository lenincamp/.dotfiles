local M = {}

local java_paths = require("lang.java.paths")
local shell = require("modules.core.shell")

local function get_class_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_pos = vim.api.nvim_win_get_cursor(0)
  local pattern = "class%s+(%w+)"
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local name = line:match(pattern)
    if name then return name end
  end
  return "UnknownClass"
end

local function get_method_name()
  return vim.fn.expand("<cword>")
end

local function maven_base(format)
  return java_paths.java17_env_prefix()
    .. format
    .. " -DfailIfNoTests=false -Djacoco.skip=true"
    .. " -Dmaven.javadoc.skip=true -Dmaven.site.skip=true"
    .. " -Dsurefire.useFile=false -DtrimStackTrace=false"
    .. " -Dmaven.source.skip=true -o -B -pl api -am"
end

function M.method_command(is_debug)
  local base = maven_base("mvn test -Dtest=%s#%s")
  local command = is_debug and (base .. " -Dmaven.surefire.debug") or base
  return string.format(command, get_class_name(), get_method_name())
    .. ' | grep -A 10 -B 1 "T E S T S"'
end

function M.class_command()
  return string.format(maven_base("mvn test -Dtest=%s"), get_class_name())
    .. ' | grep -A 100 "T E S T S" | grep -B 100 "BUILD SUCCESS"'
end

function M.run_method(is_debug)
  local command = M.method_command(is_debug)
  shell.tmux_send_keys("scratch", command)
  vim.notify("executing: " .. command, vim.log.levels.INFO)
end

function M.run_class()
  local command = M.class_command()
  shell.tmux_send_keys("scratch", command)
  vim.notify("executing Test Class: " .. command, vim.log.levels.INFO)
end

return M
