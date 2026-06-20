local M = {}

local function project_roots()
  local roots = {}
  local seen = {}
  for _, path in ipairs(vim.v.oldfiles or {}) do
    local dir = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(path, ":p")))
    local root = dir and vim.fs.root(dir, { ".git", "pom.xml", "package.json", "sfdx-project.json", "build.gradle", "build.gradle.kts" }) or nil
    root = root or dir
    if root and root ~= "" and not seen[root] and vim.fn.isdirectory(root) == 1 then
      seen[root] = true
      roots[#roots + 1] = { label = vim.fn.fnamemodify(root, ":~"), path = root }
    end
  end
  table.sort(roots, function(a, b) return a.label < b.label end)
  return roots
end

local function select_recent_project()
  local projects = project_roots()
  if #projects == 0 then
    vim.notify("No recent projects", vim.log.levels.INFO)
    return
  end
  require("modules.editor.picker").select_items(projects, {
    prompt = "Recent Projects",
    scope = "global",
    search_threshold = 0,
    format_item = function(item) return item.label end,
  }, function(item)
    if item then
      vim.cmd("cd " .. vim.fn.fnameescape(item.path))
      require("modules.editor.search").find_files({ cwd = item.path, title = "Find Files: " .. item.label })
    end
  end)
end

function M.run(action)
  local search = require("modules.editor.search")

  if action == "files" then
    search.find_files({ title = "Find File" })
  elseif action == "grep" then
    search.grep({ cwd = search.root(), regex = false, title = "Search in Files" })
  elseif action == "recent" then
    search.recent_files({ title = "Recent Files" })
  elseif action == "projects" then
    select_recent_project()
  elseif action == "config" then
    search.find_files({ cwd = vim.fn.stdpath("config"), title = "Config Files" })
  elseif action == "session" then
    local ok_s, sessions = pcall(require, "modules.editor.sessions")
    if ok_s then sessions.load_last() end
  elseif action == "new" then
    vim.cmd("enew")
    vim.cmd("startinsert")
  elseif action == "quit" then
    vim.cmd("qa")
  end
end

return M
