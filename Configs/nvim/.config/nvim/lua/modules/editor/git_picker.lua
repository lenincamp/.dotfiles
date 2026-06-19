local M = {}
local picker = require("modules.editor.picker")
local preview = require("modules.editor.preview")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function run(command, opts)
  opts = opts or {}
  local result = vim.system(command, { cwd = opts.cwd, text = true }):wait()
  local stdout = result and result.stdout or ""
  local stderr = result and result.stderr or ""
  local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
  return lines, result and result.code or 1, stderr
end

local function git_root(cwd)
  local lines, code = run({ "git", "-C", cwd or vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
  if code ~= 0 or not lines[1] then
    return nil
  end
  return lines[1]
end

local function git_relpath(root, path)
  return vim.fs.relpath(root, path) or path
end

local function make_file_item(cwd, path)
  return {
    label = path,
    path = vim.fs.normalize(cwd .. "/" .. path),
  }
end

local function git_commit_items(root, args)
  local command = {
    "git", "-C", root,
    "log",
    "--date=short",
    "--format=%H%x1f%h%x1f%ad%x1f%an%x1f%s",
  }
  vim.list_extend(command, args or {})

  local lines, code, stderr = run(command)
  if code ~= 0 then
    return nil, vim.trim(stderr) ~= "" and vim.trim(stderr) or "git log failed"
  end

  local items = {}
  for _, line in ipairs(lines) do
    local hash, short_hash, date, author, subject = line:match("^([^\31]+)\31([^\31]+)\31([^\31]+)\31([^\31]+)\31(.*)$")
    if hash then
      items[#items + 1] = {
        hash = hash,
        short_hash = short_hash,
        date = date,
        author = author,
        subject = subject,
        label = string.format("%s  %s  %s  %s", short_hash, date, author, subject),
      }
    end
  end
  return items
end

local function git_show_commit(root, hash, path, render_width)
  local command = {
    "git", "-C", root,
    "show",
    "--stat",
    "--patch",
    "--find-renames",
    "--color=never",
    "--format=fuller",
    hash,
  }
  if path then
    vim.list_extend(command, { "--", git_relpath(root, path) })
  end
  local lines, code, stderr = run(command)
  if code ~= 0 then
    return { vim.trim(stderr) ~= "" and vim.trim(stderr) or "git show failed" }
  end
  if #lines == 0 then
    return { "No changes for this selection" }
  end

  if vim.fn.executable("delta") ~= 1 then
    return lines, nil, "diff"
  end

  local delta_command = { "delta", "--paging=never" }
  if tonumber(render_width) and tonumber(render_width) > 20 then
    vim.list_extend(delta_command, { "--width", tostring(math.floor(render_width)) })
  end

  local delta = vim.system(delta_command, {
    text = true,
    stdin = table.concat(lines, "\n") .. "\n",
  }):wait()
  if delta and delta.code == 0 and delta.stdout and delta.stdout ~= "" then
    local rendered, highlights = preview.ansi_to_lines(delta.stdout)
    return rendered, highlights, nil
  end

  return lines, nil, "diff"
end

local function select_git_commit(opts)
  opts = opts or {}
  local root = opts.root
  local items, err = git_commit_items(root, opts.log_args)
  if not items then
    notify(err, vim.log.levels.WARN)
    return
  end

  picker.select_items(items, {
    prompt = opts.title or "Git log",
    scope = "project",
    search_threshold = 0,
    preview_open = true,
    auto_select_single = false,
    preview_lines = function(item, render_width)
      local lines, highlights, syntax = git_show_commit(root, item.hash, opts.path, render_width)
      return { lines = lines, highlights = highlights, syntax = syntax }
    end,
    format_item = function(item)
      return item.label
    end,
    quickfix_item = function(item)
      return { text = item.label, filename = opts.path or root, lnum = 1, col = 1 }
    end,
  }, function(item)
    if not item then return end
    local lines, highlights, syntax = git_show_commit(root, item.hash, opts.path, math.max(80, vim.o.columns))
    preview.open_output_buffer({
      name = "native://git-show/" .. item.hash .. (opts.path and (":" .. opts.path) or ""),
      lines = lines,
      highlights = highlights,
      height = 22,
      syntax = syntax or "diff",
    })
  end)
end

local function browse_url(url, copy_only)
  if copy_only then
    vim.fn.setreg("+", url)
    notify("Copied: " .. url)
    return
  end

  vim.ui.open(url)
end

local function github_url_for(file_path, line1, line2)
  local root = git_root(vim.fn.getcwd())
  if not root then
    return nil, "Not inside a git repository"
  end

  local remotes, remote_code = run({ "git", "-C", root, "remote", "get-url", "origin" })
  if remote_code ~= 0 or not remotes[1] then
    return nil, "No origin remote"
  end

  local branch_lines, branch_code = run({ "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" })
  local branch = branch_code == 0 and branch_lines[1] or "HEAD"
  local remote = remotes[1]:gsub("%.git$", "")
  local host, owner, repo = remote:match("git@([^:]+):([^/]+)/(.+)$")
  if not host then
    host, owner, repo = remote:match("https?://([^/]+)/([^/]+)/(.+)$")
  end
  if not host or not owner or not repo then
    return nil, "Unsupported git remote: " .. remote
  end

  local rel = vim.fs.relpath(root, file_path)
  if not rel then
    return nil, "File is outside git root"
  end

  local line_suffix = ""
  if line1 and line1 > 0 then
    line_suffix = "#L" .. line1
    if line2 and line2 > line1 then
      line_suffix = line_suffix .. "-L" .. line2
    end
  end

  return string.format("https://%s/%s/%s/blob/%s/%s%s", host, owner, repo, branch, rel, line_suffix)
end

function M.git_files(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = git_root(cwd)
  if not root then
    notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end

  local lines = run({ "git", "-C", root, "ls-files" })
  local items = vim.tbl_map(function(path)
    return make_file_item(root, path)
  end, lines)

  picker.select_items(items, {
    prompt = opts.title or "Git files",
    scope = "project",
    query = opts.query,
    preview = function(item) return item.path end,
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end)
end

function M.git_log(cwd)
  local root = git_root(cwd or vim.fn.getcwd())
  if not root then
    notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end
  select_git_commit({
    root = root,
    log_args = { "--all", "--max-count=300" },
    title = "Git log: " .. vim.fn.fnamemodify(root, ":t"),
  })
end

function M.git_blame_line()
  if vim.bo.buftype ~= "" then
    notify("Git blame needs a file buffer", vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand("%:p")
  if file == "" then
    return
  end
  local root = git_root(vim.fs.dirname(file))
  if not root then
    notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local rel = git_relpath(root, file)
  local lines, code, stderr = run({ "git", "-C", root, "blame", "-L", line .. "," .. line, "--", rel })
  if code ~= 0 then
    notify(vim.trim(stderr) ~= "" and vim.trim(stderr) or "git blame failed", vim.log.levels.WARN)
    return
  end
  local hash = lines[1] and lines[1]:match("^(%x+)") or nil
  if not hash then
    notify("No blame commit found for current line", vim.log.levels.WARN)
    return
  end
  select_git_commit({
    root = root,
    path = file,
    log_args = { "--max-count=1", hash },
    title = "Git blame line: " .. vim.fn.fnamemodify(file, ":~:.") .. ":" .. line,
  })
end

function M.git_file_history()
  if vim.bo.buftype ~= "" then
    notify("Git file history needs a file buffer", vim.log.levels.WARN)
    return
  end
  local file = vim.fn.expand("%:p")
  if file == "" then
    return
  end
  local root = git_root(vim.fs.dirname(file))
  if not root then
    notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end
  select_git_commit({
    root = root,
    path = file,
    log_args = { "--follow", "--max-count=300", "--", git_relpath(root, file) },
    title = "Git file history: " .. vim.fn.fnamemodify(file, ":~:."),
  })
end

function M.git_browse(copy_only)
  local file = vim.fn.expand("%:p")
  if file == "" then
    notify("Current buffer has no file", vim.log.levels.WARN)
    return
  end

  local line1 = vim.fn.line("v")
  local line2 = vim.fn.line(".")
  if vim.fn.mode() == "n" then
    line1 = vim.api.nvim_win_get_cursor(0)[1]
    line2 = line1
  elseif line1 > line2 then
    line1, line2 = line2, line1
  end

  local url, err = github_url_for(file, line1, line2)
  if not url then
    notify(err, vim.log.levels.WARN)
    return
  end
  browse_url(url, copy_only)
end

return M
