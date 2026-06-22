-- Personal plugins: GitHub by default, local ~/workspace/plugins when dev flag set.
--
-- Local dev (uncomment in init.lua):
--   vim.g.pure_local_plugins = true

local M = {}

M.github_user = "lenincamp"
M.local_root = vim.fn.expand("~/workspace/plugins")

function M.use_local()
  return vim.g.pure_local_plugins == true
end

--- Prepend rtp for plugins needed before lazy.setup (boot gutter/highlights).
function M.prepend_rtp_if_local()
  if not M.use_local() then
    return
  end
  vim.opt.rtp:prepend(M.local_root .. "/picker.nvim")
  vim.opt.rtp:prepend(M.local_root .. "/colorscheme-sync.nvim")
end

--- Resolve on-disk path for a personal plugin (local or lazy data dir).
function M.plugin_path(name)
  if M.use_local() then
    local path = M.local_root .. "/" .. name
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  local lazy_path = vim.fn.stdpath("data") .. "/lazy/" .. name
  if vim.fn.isdirectory(lazy_path) == 1 then
    return lazy_path
  end
  return nil
end

function M.dofile_lua(name, relpath)
  local root = M.plugin_path(name)
  if not root then
    return nil
  end
  local path = root .. "/" .. relpath
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  return dofile(path)
end

--- Lazy.nvim plugin spec: GitHub repo or local dir.
--- @param repo string e.g. "lenincamp/picker.nvim"
--- @param name string plugin name e.g. "picker.nvim"
--- @param opts table|nil extra lazy spec fields
function M.spec(repo, name, opts)
  opts = opts or {}
  if M.use_local() then
    return vim.tbl_extend("force", {
      dir = M.local_root .. "/" .. name,
      name = name,
    }, opts)
  end
  return vim.tbl_extend("force", {
    repo,
    name = name,
  }, opts)
end

return M
