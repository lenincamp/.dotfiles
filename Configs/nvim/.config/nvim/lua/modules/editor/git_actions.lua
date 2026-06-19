local M = {}

function M.git_compare_load_prompt()
  local ok, git_compare = pcall(require, "modules.git.compare_context")
  if not ok then
    vim.notify("modules.git.compare_context module is not available", vim.log.levels.ERROR)
    return
  end

  git_compare.prompt()
end

return M
