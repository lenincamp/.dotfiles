local M = {}
local shell = require("modules.core.shell")

local function run_fast_text_search_current_file(bufnr, query)
  query = vim.trim(query or "")
  if query == nil or query == "" then return end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    vim.notify("Buffer has no file on disk", vim.log.levels.WARN)
    return
  end

  local lines, code = shell.systemlist({
    "rg",
    "--vimgrep",
    "--smart-case",
    "--",
    query,
    file,
  })

  if code == 2 then
    lines, code = shell.systemlist({
      "rg",
      "--vimgrep",
      "--smart-case",
      "--fixed-strings",
      "--",
      query,
      file,
    })
  end

  if code ~= 0 and #lines == 0 then
    vim.notify("No text matches found", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, line in ipairs(lines) do
    local filename, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)$")
    if filename then
      items[#items + 1] = {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      }
    end
  end

  vim.fn.setqflist({}, " ", { title = string.format("Search current file: %s", query), items = items })
  require("modules.editor.picker").select_items(items, {
    prompt = string.format("Search current file: %s", query),
    scope = "buffer",
    search_threshold = 0,
    preview_open = true,
    preview = function(item) return item.filename end,
    preview_lnum = function(item) return item.lnum end,
    preview_match = function(item) return { lnum = item.lnum, col = item.col, length = #query } end,
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

local function fast_text_search_current_file(bufnr)
  vim.ui.input({ prompt = "Search text > ", scope = "buffer" }, function(query)
    run_fast_text_search_current_file(bufnr, query)
  end)
end

local function edit_netrw_hiding_list()
  vim.ui.input({
    prompt = "Edit Hiding List: ",
    default = vim.g.netrw_list_hide or "",
    scope = "buffer",
  }, function(value)
    if value == nil then
      return
    end

    vim.g.netrw_list_hide = value
    local keys = vim.api.nvim_replace_termcodes("<Plug>NetrwRefresh", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    callback = function()
      vim.highlight.on_yank({ timeout = 200 })
    end,
  })

  vim.keymap.set("n", "<leader>/", function()
    fast_text_search_current_file(vim.api.nvim_get_current_buf())
  end, { silent = true, desc = "Fast search text in current file (rg)" })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("pure_netrw_split_navigation", { clear = true }),
    pattern = "netrw",
    callback = function(args)
      vim.keymap.set("n", "<leader>er", "<Plug>NetrwRefresh", {
        buffer = args.buf,
        remap = true,
        silent = true,
        desc = "Netrw: refresh directory listing",
      })
      vim.keymap.set("n", "<leader>eh", edit_netrw_hiding_list, {
        buffer = args.buf,
        silent = true,
        desc = "Netrw: edit file hiding list",
      })
      vim.keymap.set("n", "<C-l>", function()
        require("modules.ui.split_nav").move("l")
      end, { buffer = args.buf, silent = true, nowait = true, desc = "Move to right window" })
    end,
  })

end

return M
