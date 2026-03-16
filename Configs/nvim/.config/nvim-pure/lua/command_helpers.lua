-- Command helpers: utility functions for keymaps

--- Copy file path to clipboard (relative or name only)
local function copy_path()
  local cwd  = vim.fn.getcwd()
  local full = vim.fn.expand("%:p")
  local name = vim.fn.expand("%:t")
  if full:sub(1, #cwd) ~= cwd then
    vim.notify("File is outside the working directory.", vim.log.levels.WARN)
    return
  end
  vim.ui.select({ "Relative path", "File name only" }, { prompt = "Copy to clipboard:" },
    function(choice)
      if choice == "Relative path" then
        local rel = full:sub(#cwd + 2)
        vim.fn.setreg("+", rel)
        vim.notify("Copied: " .. rel)
      elseif choice == "File name only" then
        vim.fn.setreg("+", name)
        vim.notify("Copied: " .. name)
      end
    end)
end

--- Rename file with LSP awareness (Snacks or fallback)
local function rename_file()
  local ok_s, Snacks = pcall(require, "snacks")
  if ok_s and Snacks.rename then
    Snacks.rename.rename_file()
  else
    vim.ui.input({ prompt = "New name: ", default = vim.fn.expand("%:t") }, function(name)
      if name and name ~= "" then
        vim.cmd("saveas " .. vim.fn.expand("%:h") .. "/" .. name)
      end
    end)
  end
end

--- Format with conform or LSP fallback
local function format()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ lsp_fallback = true, async = true })
  else
    vim.lsp.buf.format()
  end
end

local words_state = {
  buf = nil,
  word = nil,
}

local function reset_words_state()
  words_state.buf = nil
  words_state.word = nil
end

--- Clear search-related highlights and leave search/words mode.
local function clear_search_highlights()
  vim.cmd("nohlsearch")

  local ok_s, Snacks = pcall(require, "snacks")
  if ok_s and Snacks.words then
    Snacks.words.clear()
    Snacks.words.disable()
  end

  vim.g.snacks_words = false
  reset_words_state()
end

--- Enable native search highlight and return the original key (for expr mappings).
---@param key string
---@return string
local function enable_search_highlight_and_return(key)
  if type(key) ~= "string" or key == "" then
    return ""
  end

  vim.o.hlsearch = true
  vim.g.snacks_words = false
  return key
end

--- Jump LSP word references with Snacks.words, enabling it only when needed.
---@param count number
local function jump_word_reference(count)
  local ok_s, Snacks = pcall(require, "snacks")
  if not (ok_s and Snacks.words) then
    return
  end

  vim.g.snacks_words = true
  Snacks.words.enable()

  local jump_count = count or 1
  local buf = vim.api.nvim_get_current_buf()
  local word = vim.fn.expand("<cword>")
  local should_refresh = words_state.buf ~= buf or words_state.word ~= word

  local function jump_now()
    if Snacks.words and Snacks.words.is_enabled and Snacks.words.is_enabled({ modes = true }) then
      Snacks.words.jump(jump_count, true)
    end
  end

  if should_refresh then
    words_state.buf = buf
    words_state.word = word
    vim.lsp.buf.document_highlight()
    vim.defer_fn(jump_now, 80)
  else
    jump_now()
  end
end

--- Line completion: close brackets + semicolon + newline
-- Counts unbalanced brackets, closes them, adds semicolon for C-family,
-- then opens new indented line (IntelliJ Ctrl-Shift-Enter behavior)
local function line_completion()
  local line = vim.api.nvim_get_current_line()
  local ft   = vim.bo.filetype

  local stack    = {}
  local open_ch  = { ["("] = ")", ["["] = "]", ["{"] = "}" }
  local close_ch = { [")"] = "(", ["]"] = "[", ["}"] = "{" }

  for i = 1, #line do
    local ch = line:sub(i, i)
    if open_ch[ch] then
      stack[#stack + 1] = open_ch[ch]
    elseif close_ch[ch] then
      if #stack > 0 and stack[#stack] == ch then
        table.remove(stack)
      end
    end
  end

  local closes = ""
  for i = #stack, 1, -1 do closes = closes .. stack[i] end

  local semi_fts = {
    java = true, javascript = true, typescript = true,
    javascriptreact = true, typescriptreact = true, css = true, scss = true,
  }
  local tail = vim.trim(line .. closes):sub(-1)
  local suffix = closes
  if semi_fts[ft] and tail ~= ";" and tail ~= "{" then
    suffix = suffix .. ";"
  end

  local keys = "<Esc>A" .. suffix .. "<CR>"
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

--- Duplicate current line (normal mode) or selected content (visual mode).
---@param force_visual? boolean
local function duplicate_line_or_selection(force_visual)
  local buf = vim.api.nvim_get_current_buf()
  local mode = force_visual and vim.fn.visualmode() or vim.fn.mode()

  if mode == "v" or mode == "V" or mode == "\022" then
    local vpos = vim.fn.getpos("v")
    local cpos = vim.fn.getpos(".")
    local srow, scol = vpos[2], vpos[3] - 1
    local erow, ecol = cpos[2], cpos[3] - 1

    if srow > erow or (srow == erow and scol > ecol) then
      srow, erow = erow, srow
      scol, ecol = ecol, scol
    end

    if mode == "\022" then
      vim.notify("Duplicate block selection is not supported yet", vim.log.levels.WARN)
      return
    end

    if mode == "V" then
      local lines = vim.api.nvim_buf_get_lines(buf, srow - 1, erow, false)
      vim.api.nvim_buf_set_lines(buf, erow, erow, false, lines)
      vim.api.nvim_win_set_cursor(0, { erow + 1, 0 })
      return
    end

    local text = vim.api.nvim_buf_get_text(buf, srow - 1, scol, erow - 1, ecol + 1, {})
    vim.api.nvim_buf_set_text(buf, erow - 1, ecol + 1, erow - 1, ecol + 1, text)
    vim.api.nvim_win_set_cursor(0, { erow, ecol + 1 })
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, { line })
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

local function get_diff_windows()
  local diff_windows = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
      diff_windows[#diff_windows + 1] = win
    end
  end
  return diff_windows
end

local function is_diff_session()
  return #get_diff_windows() >= 2
end

local function with_diff_window(action)
  return function(...)
    if not is_diff_session() then return end
    local args = { ... }

    if vim.wo.diff then
      action(unpack(args))
      return
    end

    local diff_windows = get_diff_windows()
    local target = diff_windows[1]
    if target and vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_win_call(target, function()
        action(unpack(args))
      end)
    end
  end
end

local function diff_jump_next()
  vim.cmd("normal! ]czz")
end

local function diff_jump_prev()
  vim.cmd("normal! [czz")
end

local function diff_refresh()
  vim.cmd("diffupdate")
end

local function diff_quit()
  vim.cmd("diffoff!")
end

local function diff_goto_window(index)
  if type(index) ~= "number" then return end
  vim.cmd(index .. "wincmd w")
end

local function diffget_from_window(index)
  if not is_diff_session() then return end
  if type(index) ~= "number" then return end

  local diff_windows = get_diff_windows()

  local target_win = diff_windows[index]
  if not target_win then return end

  local target_buf = vim.api.nvim_win_get_buf(target_win)
  vim.cmd("diffget " .. target_buf)
  vim.cmd("diffupdate")
end

local function set_diff_cursorbind(enabled)
  local states = {}
  for _, win in ipairs(get_diff_windows()) do
    if vim.api.nvim_win_is_valid(win) then
      states[win] = vim.wo[win].cursorbind
      vim.wo[win].cursorbind = enabled
    end
  end
  return states
end

local function restore_diff_cursorbind(states)
  for win, was_enabled in pairs(states) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].cursorbind = was_enabled
    end
  end
end

local function navigate_window(dir_cmd, wezterm_dir)
  local in_diff_session = is_diff_session()
  local saved_states = in_diff_session and set_diff_cursorbind(false) or {}
  local win_before = vim.fn.winnr()
  local allow_wezterm_in_diff = vim.g.diffmode_wezterm_fallback ~= false

  vim.cmd(dir_cmd)

  if vim.fn.winnr() == win_before and wezterm_dir and ((not in_diff_session) or allow_wezterm_in_diff) then
    local dir_map = { h = "Left", j = "Down", k = "Up", l = "Right" }
    pcall(function()
      vim.fn.system("wezterm cli activate-pane-direction " .. dir_map[wezterm_dir])
    end)
  end

  if next(saved_states) ~= nil then
    restore_diff_cursorbind(saved_states)
  end
end

local function enable_diff_mode()
  vim.cmd("diffthis")
  if _G.setup_diff_mappings then _G.setup_diff_mappings() end
end

local function disable_diff_mode()
  vim.cmd("diffoff")
  if _G.cleanup_diff_mappings then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        _G.cleanup_diff_mappings(buf)
      end
    end
  end
end

return {
  copy_path = copy_path,
  rename_file = rename_file,
  format = format,
  clear_search_highlights = clear_search_highlights,
  enable_search_highlight_and_return = enable_search_highlight_and_return,
  jump_word_reference = jump_word_reference,
  duplicate_line_or_selection = duplicate_line_or_selection,
  line_completion = line_completion,
  diff_jump_next = with_diff_window(diff_jump_next),
  diff_jump_prev = with_diff_window(diff_jump_prev),
  diff_refresh = with_diff_window(diff_refresh),
  diff_quit = with_diff_window(diff_quit),
  diffget_from_window = with_diff_window(diffget_from_window),
  diff_goto_window = with_diff_window(diff_goto_window),
  navigate_window = navigate_window,
  enable_diff_mode = enable_diff_mode,
  disable_diff_mode = disable_diff_mode,
}
