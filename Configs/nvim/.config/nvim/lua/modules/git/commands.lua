local M = {}

local function git_root()
  local start = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local root = vim.fn.systemlist({ "git", "-C", start, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return root
end

local function run(command, opts)
  opts = opts or {}
  local result = vim.system(command, { cwd = opts.cwd, text = true }):wait()
  local stdout = result and result.stdout or ""
  local stderr = result and result.stderr or ""
  local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
  return lines, result and result.code or 1, stderr
end

local function open_output_buffer(name, lines, height)
  local bufnr = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].native_output_name == name then
      bufnr = buf
      break
    end
  end

  if not bufnr then
    bufnr = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, bufnr, name)
  end

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false
  vim.b[bufnr].native_output_name = name
  pcall(vim.treesitter.stop, bufnr)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, #lines > 0 and lines or { "No output" })
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].syntax = "diff"

  local wins = vim.fn.win_findbuf(bufnr)
  if #wins > 0 and vim.api.nvim_win_is_valid(wins[1]) then
    vim.api.nvim_set_current_win(wins[1])
  else
    vim.cmd("botright " .. (height or 20) .. "split")
    vim.api.nvim_win_set_buf(0, bufnr)
  end

  vim.wo.wrap = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
end

local function git_status_grep_text(text)
  text = vim.trim(text or "")
  if text == "" then return end

  local root = git_root()
  if not root then
    vim.notify("Not inside a git repository", vim.log.levels.WARN)
    return
  end

  local changed, changed_code = run({ "git", "-C", root, "diff", "--name-only", "--diff-filter=ACMRTUXB", "HEAD" })
  local untracked, untracked_code = run({ "git", "-C", root, "ls-files", "--others", "--exclude-standard" })
  local files = {}
  if changed_code == 0 then
    vim.list_extend(files, changed)
  end
  if untracked_code == 0 then
    vim.list_extend(files, untracked)
  end

  if #files == 0 then
    vim.notify("No staged or unstaged git files with content", vim.log.levels.INFO)
    return
  end

  local command = { "rg", "--vimgrep", "--smart-case", "--hidden", "-F", "--", text }
  vim.list_extend(command, files)

  local lines, code, stderr = run(command, { cwd = root })
  if code ~= 0 and #lines == 0 then
    vim.notify(vim.trim(stderr) ~= "" and vim.trim(stderr) or "No text matches found", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, line in ipairs(lines) do
    local file, lnum, col, matched = line:match("^([^:]+):(%d+):(%d+):(.*)$")
    if file then
      items[#items + 1] = {
        filename = vim.fs.normalize(root .. "/" .. file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = matched,
      }
    end
  end

  if #items == 0 then
    vim.notify("No text matches found", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, " ", { title = "Git status grep: " .. text, items = items })

  require("modules.editor.picker").select_items(items, {
    prompt = "Git status grep: " .. text,
    scope = "project",
    search_threshold = 0,
    preview_open = true,
    preview = function(item) return item.filename end,
    preview_lnum = function(item) return item.lnum end,
    preview_match = function(item)
      return { lnum = item.lnum, col = item.col, length = #text }
    end,
    format_item = function(item)
      return string.format("%s:%d:%d  %s", vim.fn.fnamemodify(item.filename, ":~:."), item.lnum or 0, item.col or 0, item.text or "")
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
      vim.api.nvim_win_set_cursor(0, { item.lnum or 1, math.max((item.col or 1) - 1, 0) })
    end
  end)
end

local function git_status_grep(opts)
  if opts.args ~= "" then
    git_status_grep_text(opts.args)
    return
  end

  vim.ui.input({ prompt = "SearchText > ", scope = "project" }, function(input)
    git_status_grep_text(input)
  end)
end

local function git_line_history(opts)
  if vim.bo.buftype ~= "" then
    vim.notify("Git line history needs a file buffer", vim.log.levels.WARN)
    return
  end
  local spec = string.format("%d,%d:%s", opts.line1, opts.line2, vim.fn.expand("%:p"))
  local lines = vim.fn.systemlist({ "git", "--no-pager", "log", "--no-color", "-p", "-L", spec })
  if vim.v.shell_error ~= 0 then
    vim.notify(#lines > 0 and table.concat(lines, "\n") or "git line history failed", vim.log.levels.WARN)
    return
  end
  open_output_buffer("native://git-line-history/" .. spec, lines, 20)
end

function M.setup()
  vim.api.nvim_create_user_command("GitStatusGrep", git_status_grep, {
    nargs = "*",
    desc = "Grep in git changed files",
  })

  vim.api.nvim_create_user_command("GitLineHistory", git_line_history, {
    range = true,
    desc = "Git line history with delta",
  })
end

return M