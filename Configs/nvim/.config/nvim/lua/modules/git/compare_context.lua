local M = {}

local function exec_cmd(args, opts)
  opts = opts or {}
  local trim_output = opts.trim_output ~= false

  if vim.system then
    local result = vim.system(args, { text = true }):wait()
    local stdout = result.stdout or ""
    local stderr = result.stderr or ""
    if trim_output then
      stdout = vim.trim(stdout)
      stderr = vim.trim(stderr)
    end
    local output = stdout ~= "" and stdout or stderr
    return result.code == 0, output
  end

  local out = vim.fn.system(args)
  local ok = vim.v.shell_error == 0
  if trim_output then
    out = vim.trim(out or "")
  end
  return ok, out or ""
end

local function get_git_root(path)
  local ok, out = exec_cmd({ "git", "-C", path, "rev-parse", "--show-toplevel" })
  if not ok or out == "" then
    return nil
  end
  return out
end

local function classify_current_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local bt = vim.bo[buf].buftype
  local ft = vim.bo[buf].filetype
  local name = vim.api.nvim_buf_get_name(buf)

  if ft == "oil" or ft == "netrw" then
    return "explorer"
  end

  if bt ~= "" and bt ~= "acwrite" then
    return "special"
  end

  if name == "" then
    return "special"
  end

  if vim.fn.isdirectory(name) == 1 then
    return "directory"
  end

  return "file"
end

local function prompt_git_ref(on_ref)
  vim.ui.input({ prompt = "Git reference (branch/tag/commit): ", scope = "project" }, function(input)
    local ref = vim.trim(input or "")
    if ref == "" then
      return
    end
    on_ref(ref)
  end)
end

local function validate_git_ref(repo_root, ref)
  return exec_cmd({ "git", "-C", repo_root, "rev-parse", "--verify", "--quiet", ref .. "^{commit}" })
end

local function is_file_tracked(repo_root, relpath)
  local ok = exec_cmd({ "git", "-C", repo_root, "ls-files", "--error-unmatch", "--", relpath })
  return ok
end

local function open_file_diff_view(ref)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Current buffer is not a file", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.notify("Save the file before comparing", vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(file) ~= 1 then
    vim.notify("Current file does not exist on disk", vim.log.levels.WARN)
    return
  end

  local repo_root = get_git_root(vim.fn.fnamemodify(file, ":h"))
  if not repo_root then
    vim.notify("No Git repository found for this file", vim.log.levels.ERROR)
    return
  end

  local prefix = repo_root .. "/"
  if file:sub(1, #prefix) ~= prefix then
    vim.notify("Current file is outside repository root", vim.log.levels.ERROR)
    return
  end

  local relpath = file:sub(#prefix + 1)
  if not is_file_tracked(repo_root, relpath) then
    vim.notify("File is not tracked by Git yet (new or ignored)", vim.log.levels.WARN)
    return
  end

  local ok_ref = validate_git_ref(repo_root, ref)
  if not ok_ref then
    vim.notify("Git reference not found: " .. ref, vim.log.levels.ERROR)
    return
  end

  local ok_blob, blob = exec_cmd({ "git", "-C", repo_root, "show", ref .. ":" .. relpath }, { trim_output = false })
  if not ok_blob then
    vim.notify("File does not exist in reference: " .. ref, vim.log.levels.WARN)
    return
  end

  if blob:find("\0", 1, true) then
    vim.notify("Binary file diff is not supported in this view", vim.log.levels.WARN)
    return
  end

  local cur_win = vim.api.nvim_get_current_win()
  local cur_ft = vim.bo.filetype
  local left_name = string.format("%s:%s", ref, relpath)

  vim.cmd("leftabove vnew")
  local left_buf = vim.api.nvim_get_current_buf()
  local left_lines = vim.split(blob, "\n", { plain = true })

  if #left_lines > 0 and left_lines[#left_lines] == "" then
    table.remove(left_lines)
  end
  if #left_lines == 0 then
    left_lines = { "" }
  end

  vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, left_lines)
  pcall(vim.api.nvim_buf_set_name, left_buf, left_name)
  vim.bo[left_buf].buftype = "nofile"
  vim.bo[left_buf].bufhidden = "wipe"
  vim.bo[left_buf].swapfile = false
  vim.bo[left_buf].modifiable = false
  vim.bo[left_buf].readonly = true
  if cur_ft ~= "" then
    vim.bo[left_buf].filetype = cur_ft
  end

  vim.cmd("diffthis")
  vim.api.nvim_set_current_win(cur_win)
  vim.cmd("diffthis")
  vim.notify("Opened file diff: " .. left_name, vim.log.levels.INFO)
end

local function run_compare_load(ref)
  if vim.system then
    vim.system({ "git", "compare-load", ref }, { text = true }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          vim.notify("Loaded diff from " .. ref .. " into worktree", vim.log.levels.INFO)
          return
        end

        local msg = vim.trim((result.stderr or "") ~= "" and result.stderr or (result.stdout or ""))
        if msg == "" then
          msg = "git compare-load failed"
        end
        vim.notify(msg, vim.log.levels.ERROR)
      end)
    end)
    return
  end

  local out = vim.fn.system({ "git", "compare-load", ref })
  if vim.v.shell_error == 0 then
    vim.notify("Loaded diff from " .. ref .. " into worktree", vim.log.levels.INFO)
    return
  end

  local msg = vim.trim(out)
  if msg == "" then
    msg = "git compare-load failed"
  end
  vim.notify(msg, vim.log.levels.ERROR)
end

function M.prompt()
  if vim.fn.executable("git") ~= 1 then
    vim.notify("git is not available", vim.log.levels.ERROR)
    return
  end

  local context = classify_current_buffer()

  if context == "file" then
    prompt_git_ref(function(ref)
      open_file_diff_view(ref)
    end)
    return
  end

  prompt_git_ref(function(ref)
    run_compare_load(ref)
  end)
end

return M
