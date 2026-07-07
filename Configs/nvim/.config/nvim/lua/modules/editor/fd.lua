local M = {}

local git_excludes = { "--exclude", ".git", "--exclude", ".gitignore" }

local build_excludes = {
  "--exclude", "node_modules",
  "--exclude", "target",
  "--exclude", "dist",
  "--exclude", "build",
  "--exclude", "out",
  "--exclude", "coverage",
  "--exclude", ".gradle",
  "--exclude", ".idea",
  "--exclude", "__pycache__",
  "--exclude", ".next",
  "--exclude", ".nuxt",
  "--exclude", "vendor",
  "--exclude", ".tox",
  "--exclude", "venv",
  "--exclude", ".mypy_cache",
  "--exclude", ".pytest_cache",
  "--exclude", ".cache",
  "--exclude", ".terraform",
}

--- For :find / my_find (basic)
function M.basic()
  local cmd = { "--hidden" }
  vim.list_extend(cmd, git_excludes)
  vim.list_extend(cmd, build_excludes)
  return cmd
end

--- For root search (full)
function M.full()
  return M.basic()
end

--- Includes git-ignored files (no .git exclusions)
function M.ignored()
  local cmd = { "--hidden", "--no-ignore" }
  vim.list_extend(cmd, build_excludes)
  return cmd
end

--- Build fd args from flags
function M.args(opts)
  opts = opts or {}
  local cmd = { "fd", "--type", "f" }
  local excl = opts.ignored and M.ignored() or M.basic()
  vim.list_extend(cmd, excl)
  if opts.cwd then
    vim.list_extend(cmd, { "--search-path", opts.cwd })
  end
  return cmd
end

return M
