local M = {}

local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return vim.fn.getcwd()
end

local function git_remote_url()
  local out = vim.fn.systemlist({ "git", "remote", "get-url", "origin" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]:gsub("%.git$", "")
  end
  return nil
end

local function git_current_branch()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "HEAD" })
  if vim.v.shell_error == 0 and out[1] then
    return out[1]
  end
  return "main"
end

local function git_relative_path(filepath)
  local root = git_root()
  if filepath:sub(1, #root) == root then
    return filepath:sub(#root + 2)
  end
  return vim.fn.fnamemodify(filepath, ":~:.")
end

--- <leader>gl: git log cwd → quickfix
function M.git_log_cwd()
  local root = vim.fn.getcwd()
  local lines = vim.fn.systemlist({ "git", "-C", root, "log", "--oneline", "-50" })
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No git log found", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, line in ipairs(lines) do
    local hash, msg = line:match("^(%S+)%s+(.+)$")
    if hash and msg then
      items[#items + 1] = {
        filename = "",
        lnum = 1,
        text = line,
        module = hash,
      }
    end
  end
  vim.fn.setqflist({}, "r", { title = "Git Log (cwd)", items = items })
  vim.cmd.copen(10)
end

--- <leader>gL: git log root → quickfix
function M.git_log_root()
  local root = git_root()
  local lines = vim.fn.systemlist({ "git", "-C", root, "log", "--oneline", "-50" })
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No git log found", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, line in ipairs(lines) do
    local hash, msg = line:match("^(%S+)%s+(.+)$")
    if hash and msg then
      items[#items + 1] = {
        filename = "",
        lnum = 1,
        text = line,
        module = hash,
      }
    end
  end
  vim.fn.setqflist({}, "r", { title = "Git Log (root)", items = items })
  vim.cmd.copen(10)
end

--- <leader>gf: git file history
function M.git_file_history()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file", vim.log.levels.WARN)
    return
  end
  local relpath = git_relative_path(file)
  local root = git_root()
  local lines = vim.fn.systemlist({ "git", "-C", root, "log", "--oneline", "-30", "--", relpath })
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("No history for " .. relpath, vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, line in ipairs(lines) do
    local hash, msg = line:match("^(%S+)%s+(.+)$")
    if hash and msg then
      items[#items + 1] = {
        filename = file,
        lnum = 1,
        text = hash .. "  " .. msg,
        module = hash,
      }
    end
  end
  vim.fn.setqflist({}, "r", { title = "Git History: " .. relpath, items = items })
  vim.cmd.copen(10)
end

--- <leader>gb: git blame line (notification)
function M.git_blame_line()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file", vim.log.levels.WARN)
    return
  end
  local relpath = git_relative_path(file)
  local root = git_root()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local output = vim.fn.systemlist({ "git", "-C", root, "blame", "-L", line_num .. "," .. line_num, "--porcelain", relpath })
  if vim.v.shell_error ~= 0 or #output == 0 then
    vim.notify("Blame failed", vim.log.levels.WARN)
    return
  end
  local hash = output[1]:match("^(%S+)")
  local author = ""
  local date = ""
  for _, line in ipairs(output) do
    if line:match("^author ") then
      author = line:gsub("^author ", "")
    end
    if line:match("^author-time ") then
      local ts = tonumber(line:gsub("^author-time ", ""))
      if ts then
        date = os.date("%Y-%m-%d", ts)
      end
    end
  end
  local short_hash = hash and hash:sub(1, 8) or "?"
  vim.notify(string.format("%s by %s (%s)", short_hash, author, date), vim.log.levels.INFO)
end

--- <leader>gB: git browse (open in browser)
function M.git_browse(open)
  local url = git_remote_url()
  if not url then
    vim.notify("No remote URL", vim.log.levels.WARN)
    return
  end
  local branch = git_current_branch()
  local file = vim.fn.expand("%:p")
  local relpath = git_relative_path(file)
  local web_url = url:gsub("^git@github%.com:", "https://github.com/")
  web_url = web_url:gsub("^https?://", "")
  if not web_url:match("^https://") then
    web_url = "https://" .. web_url
  end
  local browse_url = web_url .. "/tree/" .. branch .. "/" .. relpath
  if open then
    vim.fn.setreg("+", browse_url)
    vim.notify("Copied: " .. browse_url, vim.log.levels.INFO)
  else
    vim.ui.open(browse_url)
  end
end

--- <leader>gG: lazygit
function M.lazygit(cwd)
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("lazygit not found", vim.log.levels.WARN)
    return
  end
  vim.cmd("botright 15split")
  vim.fn.termopen({ "lazygit" }, { cwd = cwd or git_root() })
  vim.cmd("startinsert")
end

return M
