local M = {}

local core = require("modules.editor.search.core")
local picker = require("modules.editor.picker")

function M.grep(opts)
  opts = opts or {}
  local cwd = opts.cwd or core.root()
  local query = opts.query
  if not query or query == "" then
    return M.grep_picker(opts)
  end

  local dirs = opts.dirs or { cwd }
  local items = {}
  local pattern = opts.word and ("\\b" .. core.regex_escape(query) .. "\\b") or query

  for _, dir in ipairs(dirs) do
    local command = { "rg", "--vimgrep", "--smart-case", "--hidden", "--glob", "!.git" }
    if opts.ignored then
      command[#command + 1] = "--no-ignore"
    end
    if not opts.regex and not opts.word then
      command[#command + 1] = "-F"
    end
    vim.list_extend(command, core.file_glob_args(opts.glob))
    command[#command + 1] = pattern

    local lines = core.run(command, { cwd = dir })
    for _, line in ipairs(lines) do
      local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
      if file then
        items[#items + 1] = {
          filename = vim.fs.normalize(dir .. "/" .. file),
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = text,
        }
      end
    end
  end

  local title = opts.title and (opts.title .. ": " .. query) or "Grep: " .. query
  vim.fn.setqflist({}, " ", { title = title, items = items })
  if #items == 0 then
    core.notify(title .. ": no results", vim.log.levels.WARN)
    return
  end

  picker.select_items(items, {
    prompt = title,
    scope = opts.scope or "project",
    filters = core.file_filters(),
    search_threshold = 0,
    preview_open = true,
    preview = function(item) return item.filename end,
    preview_lnum = function(item) return item.lnum end,
    preview_match = function(item)
      return {
        lnum = item.lnum,
        col = item.col,
        length = (opts.regex and not opts.word) and nil or #query,
      }
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

function M.grep_picker(opts)
  opts = opts or {}
  local cwd = opts.cwd or core.root()

  picker.select_items({}, {
    prompt = opts.title or "Grep",
    scope = opts.scope or "project",
    search_threshold = 0,
    input_mode = true,
    input_only = true,
    auto_select_single = false,
    filters = core.file_filters(),
    submit_query = function(query, state)
      local next_opts = vim.tbl_extend("force", opts, {
        cwd = cwd,
        query = query,
        regex = opts.regex ~= false,
        preview = true,
        preview_open = true,
        layout = "intellij_grep",
      })
      if state and state.filter and state.filter.glob then
        next_opts.glob = state.filter.glob
      end
      M.grep(next_opts)
    end,
  }, function(item)
    if item then
      vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    end
  end)
end

function M.grep_word(opts)
  opts = opts or {}
  opts.query = core.selected_text_or_word()
  opts.regex = true
  opts.word = true
  M.grep(opts)
end

return M
