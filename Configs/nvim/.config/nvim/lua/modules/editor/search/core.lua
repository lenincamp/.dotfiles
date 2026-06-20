local M = {}

local root_cache = {}
local root_markers = { ".git", "pom.xml", "package.json", "build.gradle" }
local root_cache_group_initialized = false

function M.notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

local function ensure_root_cache_autocmd()
  if root_cache_group_initialized then
    return
  end
  root_cache_group_initialized = true

  vim.api.nvim_create_autocmd("BufFilePost", {
    group = vim.api.nvim_create_augroup("root_cache", { clear = true }),
    callback = function(args)
      root_cache[args.buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("root_cache_cwd", { clear = true }),
    callback = function()
      root_cache = {}
    end,
  })
end

function M.run(command, opts)
  opts = opts or {}
  local result = vim.system(command, { cwd = opts.cwd, text = true }):wait()
  local stdout = result and result.stdout or ""
  local stderr = result and result.stderr or ""
  local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
  return lines, result and result.code or 1, stderr
end

function M.focus_buffer_window(bufnr)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_set_current_tabpage(tab)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end
  return false
end

function M.make_file_item(cwd, path)
  return {
    label = path,
    path = vim.fs.normalize(cwd .. "/" .. path),
  }
end

function M.item_path(item)
  return type(item) == "table" and (item.path or item.filename or item.label or "") or tostring(item or "")
end

function M.path_has_extension(path, extensions)
  path = path:lower()
  for _, extension in ipairs(extensions) do
    if path:sub(-#extension) == extension then
      return true
    end
  end
  return false
end

function M.file_glob_args(globs)
  local args = {}
  for _, glob in ipairs(globs or {}) do
    args[#args + 1] = "--glob"
    args[#args + 1] = glob
  end
  return args
end

function M.file_filters()
  return {
    { key = "J", label = "Java", glob = { "*.java" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".java" }) end },
    { key = "j", label = "JS/TS", glob = { "*.js", "*.ts" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".js", ".ts" }) end },
    { key = "x", label = "JSX/TSX", glob = { "*.jsx", "*.tsx" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".jsx", ".tsx" }) end },
    {
      key = "S",
      label = "Salesforce",
      glob = { "force-app/**", "*.cls", "*.trigger", "*.page", "*.component", "*.cmp", "*.app", "*.design", "*.object", "*.field-meta.xml", "*.js-meta.xml" },
      predicate = function(item)
        local path = M.item_path(item):lower()
        return path:find("force%-app/", 1, false) ~= nil
            or M.path_has_extension(path, { ".cls", ".trigger", ".page", ".component", ".cmp", ".app", ".design", ".object", ".field-meta.xml", ".js-meta.xml" })
      end,
    },
    { key = "X", label = "XML", glob = { "*.xml" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".xml" }) end },
    { key = "n", label = "JSON", glob = { "*.json", "*.jsonc" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".json", ".jsonc" }) end },
    { key = "y", label = "YAML/TOML/properties", glob = { "*.yml", "*.yaml", "*.toml", "*.properties" }, predicate = function(item) return M.path_has_extension(M.item_path(item), { ".yml", ".yaml", ".toml", ".properties" }) end },
  }
end

function M.file_items(cwd, opts)
  opts = opts or {}
  local command = { "rg", "--files", "--hidden", "--glob", "!.git" }
  if opts.ignored then
    command[#command + 1] = "--no-ignore"
  end
  vim.list_extend(command, M.file_glob_args(opts.glob))

  local lines, code, stderr = M.run(command, { cwd = cwd })
  if code ~= 0 and #lines == 0 then
    return nil, vim.trim(stderr) ~= "" and vim.trim(stderr) or "No files found"
  end

  return vim.tbl_map(function(path)
    return M.make_file_item(cwd, path)
  end, lines)
end

function M.regex_escape(text)
  return (text:gsub("([\\%^%$%(%)%%%.%[%]%*%+%-%?%|{}])", "\\%1"))
end

function M.selected_text_or_word()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local saved = vim.fn.getreg("z")
    local saved_type = vim.fn.getregtype("z")
    vim.cmd([[silent normal! "zy]])
    local text = vim.fn.getreg("z")
    vim.fn.setreg("z", saved, saved_type)
    return vim.trim(text)
  end
  return vim.fn.expand("<cword>")
end

function M.root()
  ensure_root_cache_autocmd()

  local buf = vim.api.nvim_get_current_buf()
  if not root_cache[buf] then
    root_cache[buf] = vim.fs.root(buf, root_markers) or vim.fn.getcwd()
  end
  return root_cache[buf]
end

return M
