local M = {}

local core = require("modules.editor.search.core")
local picker = require("modules.editor.picker")

function M.open_explorer(cwd, reveal_path)
  require("modules.editor.explorer").open(cwd, reveal_path)
end

function M.find_files(opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()

  if opts.input_mode then
    picker.select_items({}, {
      prompt = opts.title or "Find files",
      scope = "project",
      search_threshold = 0,
      input_mode = true,
      input_only = true,
      auto_select_single = false,
      filters = core.file_filters(),
      submit_query = function(query, state)
        local next_opts = vim.tbl_extend("force", opts, {
          cwd = cwd,
          query = query,
          input_mode = false,
          preview = true,
          preview_open = true,
          auto_select_single = false,
          layout = "intellij_grep",
        })
        if state and state.filter and state.filter.glob then
          next_opts.glob = state.filter.glob
        end
        if state and state.regex_pattern then
          next_opts.regex_query = state.regex_pattern
        end
        M.find_files(next_opts)
      end,
    }, function() end)
    return
  end

  local items, err = core.file_items(cwd, opts)
  if not items then
    core.notify(err, vim.log.levels.WARN)
    return
  end

  if opts.regex_query then
    local filtered = {}
    for _, item in ipairs(items) do
      local ok, matched = pcall(function()
        return item.label:find(opts.regex_query) ~= nil
      end)
      if ok and matched then
        filtered[#filtered + 1] = item
      end
    end
    items = filtered
    if #items == 0 then
      core.notify((opts.title or "Find files") .. ": no regex results for " .. opts.regex_query, vim.log.levels.WARN)
      return
    end
  end

  local select_opts = {
    prompt = opts.title or "Find files",
    scope = "project",
    search_threshold = 0,
    query = opts.query,
    input_mode = opts.input_mode,
    auto_select_single = opts.auto_select_single,
    preview_open = opts.preview_open,
    filters = core.file_filters(),
    format_item = function(item)
      return item.label
    end,
  }
  if opts.preview ~= false then
    select_opts.preview = function(item) return item.path end
  end

  picker.select_items(items, select_opts, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end)
end

function M.git_files(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or core.root()
  require("modules.editor.git_picker").git_files(opts)
end

function M.recent_files(opts)
  opts = opts or {}
  local cwd = not opts.global and vim.fs.normalize(opts.cwd or vim.fn.getcwd()) or nil
  local items = {}
  for _, path in ipairs(vim.v.oldfiles or {}) do
    local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local in_cwd = not cwd or normalized == cwd or normalized:sub(1, #cwd + 1) == (cwd .. "/")
    if vim.fn.filereadable(normalized) == 1 and in_cwd then
      items[#items + 1] = {
        label = cwd and vim.fn.fnamemodify(normalized, ":.") or vim.fn.fnamemodify(normalized, ":~:."),
        path = normalized,
      }
    end
  end

  picker.select_items(items, {
    prompt = opts.title or "Recent files",
    scope = cwd and "project" or "global",
    search_threshold = 0,
    query = opts.query,
    filters = core.file_filters(),
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

function M.open_terminal(cwd)
  vim.cmd("botright 15split")
  local buffer = vim.api.nvim_get_current_buf()
  vim.fn.termopen(vim.o.shell, { cwd = cwd or vim.fn.getcwd() })
  vim.bo[buffer].buflisted = false
  vim.cmd("startinsert")
end

return M
