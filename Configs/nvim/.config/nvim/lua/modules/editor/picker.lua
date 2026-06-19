local M = {}
local picker_display = require("modules.editor.picker.display")
local picker_filter = require("modules.editor.picker.filter")
local picker_quickfix = require("modules.editor.picker.quickfix")
local preview = require("modules.editor.preview")

local intellij_grep = true
local last_qf_title = nil
local preview_namespace = vim.api.nvim_create_namespace("native_picker_preview")
local picker_namespace = vim.api.nvim_create_namespace("native_picker")

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO)
end

function M.select_items(items, opts, on_choice)
  if #items == 0 then
    notify((opts and opts.prompt or "Select") .. ": no results", vim.log.levels.WARN)
    return
  end

  opts = opts or {}
  local prompt = opts.prompt or "Select"
  local threshold = opts.search_threshold or 25
  local max_results = opts.max_results or 40
  local supports_filter = #items > threshold and opts.search ~= false
  local has_initial_query = opts.query and opts.query ~= ""
  local candidates_win = nil
  local candidates_buf = nil
  local preview_win = nil
  local preview_buf = nil

  local function close_candidates_window()
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
      pcall(vim.api.nvim_win_close, preview_win, true)
    end
    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
      pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
    end
    if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
      pcall(vim.api.nvim_win_close, candidates_win, true)
    end
    if candidates_buf and vim.api.nvim_buf_is_valid(candidates_buf) then
      pcall(vim.api.nvim_buf_delete, candidates_buf, { force = true })
    end
    candidates_win = nil
    candidates_buf = nil
    preview_win = nil
    preview_buf = nil
  end

  local function preview_path(item)
    if type(opts.preview) ~= "function" then return nil end
    local ok, path = pcall(opts.preview, item)
    return ok and type(path) == "string" and path or nil
  end

  local function preview_content(item, render_width)
    if type(opts.preview_lines) ~= "function" then return nil end
    local ok, result = pcall(opts.preview_lines, item, render_width)
    if not ok then return false, { "Preview failed: " .. tostring(result) }, nil end

    if type(result) == "string" then
      return true, vim.split(result, "\n", { plain = true }), nil
    end

    if type(result) == "table" and result.lines then
      return true, result.lines, result.syntax, result.highlights
    end

    if type(result) == "table" then
      return true, result, nil
    end

    return false, { "No preview" }, nil
  end

  local function preview_target_lnum(item)
    if type(opts.preview_lnum) ~= "function" then return nil end
    local ok, lnum = pcall(opts.preview_lnum, item)
    lnum = ok and tonumber(lnum) or nil
    return lnum and math.max(1, lnum) or nil
  end

  local function preview_allowed(path, item)
    if not path or vim.fn.filereadable(path) ~= 1 then return false, "No preview" end
    local size = vim.fn.getfsize(path)
    if size < 0 or size > (opts.preview_max_bytes or 300000) then return false, "Preview skipped: file too large" end
    local target_lnum = preview_target_lnum(item)
    local line_limit = math.max(opts.preview_lines or 120, target_lnum and (target_lnum + 60) or 0)
    local ok, lines = pcall(vim.fn.readfile, path, "", line_limit)
    if not ok then return false, "Preview failed" end
    for _, line in ipairs(lines) do
      if line:find("%z") then return false, "Preview skipped: binary file" end
    end
    return true, lines
  end

  local function preview_match(item, lines)
    if type(opts.preview_match) ~= "function" then return nil end
    local ok, match = pcall(opts.preview_match, item, lines)
    return ok and type(match) == "table" and match or nil
  end

  local function open_candidates_picker(candidates, query)
    close_candidates_window()

    local current_query = vim.trim(query or "")
    local current_candidates = candidates
    local current_filter_label = nil
    local current_quick_filter = nil
    local current_regex_pattern = nil
    local choosing_quick_filter = false
    local page_start = 1
    local columns = math.max(vim.o.columns, 20)
    local rows = math.max(vim.o.lines - vim.o.cmdheight - 2, 5)
    local has_preview = type(opts.preview) == "function" or type(opts.preview_lines) == "function"
    local preview_enabled = has_preview and opts.preview_open == true
    local preview_maximized = false
    local show_descriptions = false
    local picker_layout = opts.layout or (intellij_grep and "intellij_grep" or "default")
    local width, height, row, col, preview_width, preview_height, preview_row, preview_col

    local function calculate_layout()
      columns = math.max(vim.o.columns, 20)
      rows = math.max(vim.o.lines - vim.o.cmdheight - 2, 5)

      if has_preview and picker_layout == "intellij_grep" then
        width = math.max(40, columns - 4)
        height = math.min(max_results + 3, math.max(8, math.floor(rows * 0.34)))
        row = math.max(1, rows - height)
        col = 2
        preview_width = width
        preview_height = math.max(5, row - 2)
        preview_row = 1
        preview_col = col
        return
      end

      local total_width = has_preview and math.min(math.max(90, math.floor(columns * 0.9)), columns - 4) or nil
      width = has_preview and math.min(math.max(50, math.floor(total_width * 0.55)), total_width - 32)
        or math.min(math.max(60, math.floor(columns * 0.72)), columns - 4)
      preview_width = has_preview and math.max(30, total_width - width - 2) or 0
      height = math.min(max_results + 3, rows - 2)
      row = math.max(1, math.floor((rows - height) / 2))
      col = math.max(2, math.floor((columns - (has_preview and total_width or width)) / 2))
      preview_height = height
      preview_row = row
      preview_col = col + width + 2

      if opts.position == "top" then
        row = 1
        col = 2
        preview_row = row
        preview_col = col + width + 2
      end
    end

    calculate_layout()

    local function preview_config()
      if preview_maximized then
        return {
          relative = "editor",
          row = 1,
          col = 2,
          width = math.max(20, columns - 4),
          height = math.max(5, rows - 2),
          style = "minimal",
          border = "single",
          zindex = 80,
          focusable = false,
          noautocmd = true,
        }
      end

      return {
        relative = "editor",
        row = preview_row,
        col = preview_col,
        width = preview_width,
        height = preview_height,
        style = "minimal",
        border = "single",
        zindex = 60,
        focusable = false,
        noautocmd = true,
      }
    end

    candidates_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[candidates_buf].bufhidden = "wipe"
    local ok, win = pcall(vim.api.nvim_open_win, candidates_buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      style = "minimal",
      border = "single",
      zindex = 50,
      focusable = true,
      noautocmd = true,
    })

    if not ok then
      close_candidates_window()
      vim.ui.select(candidates, opts, on_choice)
      return
    end

    candidates_win = win
    vim.wo[candidates_win].wrap = false
    vim.wo[candidates_win].cursorline = true

    local function status_segments(filters, total, group_help)
      if choosing_quick_filter then
        return "FileType " .. picker_filter.quick_filter_menu(filters) .. "  Esc=cancel"
      end

      local layout_label = has_preview and (picker_layout == "intellij_grep" and "intellij" or "side") or "list"
      if show_descriptions then
        local filter_help = picker_filter.has_filters(filters) and "  F=types  C=clear-type  R=regex" or ""
        return string.format("Enter=open  C-q=qf  /=filter%s  1-9=open  Tab=preview  A-p=focus  A-l=layout:%s  z=zoom  C-u/C-d=page  C-f/C-b=scroll%s  ?=keys  q=close  (%d total)", filter_help, layout_label, group_help, total)
      end

      local parts = { "Enter", "C-q", "/" }
      if picker_filter.has_filters(filters) then
        vim.list_extend(parts, { "F", "C", "R" })
      end
      vim.list_extend(parts, { "1-9", "Tab", "A-p", "A-l:" .. layout_label, "z", "C-u/d", "C-f/b" })
      if opts.group_item then
        vim.list_extend(parts, { "[g", "]g" })
      end
      vim.list_extend(parts, { "?", "q", string.format("%d total", total) })
      return table.concat(parts, "  ")
    end

    local function highlight_status_line(line)
      picker_display.define_highlights()
      vim.api.nvim_buf_clear_namespace(candidates_buf, picker_namespace, 0, 2)
      vim.api.nvim_buf_add_highlight(candidates_buf, picker_namespace, "NativePickerTitle", 0, 0, -1)
      vim.api.nvim_buf_add_highlight(candidates_buf, picker_namespace, "NativePickerStatus", 1, 0, -1)
      for key in line:gmatch("[%w%-%[%]/?<:]+") do
        local start = 1
        while true do
          local from, to = line:find(vim.pesc(key), start)
          if not from then
            break
          end
          vim.api.nvim_buf_add_highlight(candidates_buf, picker_namespace, "NativePickerKey", 1, from - 1, to)
          start = to + 1
        end
      end
    end

    local function render()
      local total = #current_candidates
      if page_start > total then
        page_start = math.max(1, total - max_results + 1)
      end
      local visible_limit = math.max(1, height - 3)
      local page_end = math.min(total, page_start + visible_limit - 1)
      local title = prompt
        .. (current_query ~= "" and (' /' .. current_query) or "")
        .. (current_filter_label and (" [" .. current_filter_label .. "]") or "")
      local group_help = opts.group_item and "  [g/]g=group" or ""
      local filters = opts.filters or opts.quick_filters
      local status_line = status_segments(filters, total, group_help)
      local lines = {
        picker_display.padded_line(title, width),
        picker_display.padded_line(status_line, width),
      }

      for index = page_start, page_end do
        local visible_index = index - page_start + 1
        local shortcut = visible_index <= 9 and string.format("[%d]", visible_index) or "   "
        lines[#lines + 1] = string.format("%4d %s  %s", index, shortcut, picker_filter.item_label(current_candidates[index], opts))
      end

      if total > visible_limit then
        lines[#lines + 1] = string.format("... showing %d-%d of %d", page_start, page_end, total)
      end

      vim.bo[candidates_buf].modifiable = true
      vim.api.nvim_buf_set_lines(candidates_buf, 0, -1, false, lines)
      vim.bo[candidates_buf].modifiable = false
      highlight_status_line(status_line)

      if vim.api.nvim_win_is_valid(candidates_win) then
        vim.api.nvim_win_set_cursor(candidates_win, { math.min(3, #lines), 0 })
      end
    end

    local function active_filter_label()
      local labels = {}
      if current_quick_filter then
        labels[#labels + 1] = current_quick_filter.label or current_quick_filter.key
      end
      if current_regex_pattern then
        labels[#labels + 1] = "regex:" .. current_regex_pattern
      end
      return #labels > 0 and table.concat(labels, " ") or nil
    end

    local function current_item()
      if not candidates_win or not vim.api.nvim_win_is_valid(candidates_win) then return nil end
      local row = vim.api.nvim_win_get_cursor(candidates_win)[1]
      return current_candidates[page_start + row - 3]
    end

    local function close_preview()
      if preview_win and vim.api.nvim_win_is_valid(preview_win) then pcall(vim.api.nvim_win_close, preview_win, true) end
      if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
      end
      preview_win, preview_buf = nil, nil
    end

    local function update_preview()
      if not preview_enabled then return end
      local item = current_item()
      local path = preview_path(item)
      local ok_preview, fallback, preview_syntax, preview_highlights
      local next_preview_config = preview_config()
      local content_ok, content_lines, content_syntax, content_highlights = preview_content(item, next_preview_config.width)
      if content_ok ~= nil then
        ok_preview, fallback, preview_syntax, preview_highlights = content_ok, content_lines, content_syntax, content_highlights
      else
        ok_preview, fallback = preview_allowed(path, item)
      end
      if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        pcall(vim.api.nvim_buf_delete, preview_buf, { force = true })
      end
      preview_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[preview_buf].bufhidden = "wipe"
      vim.bo[preview_buf].buftype = "nofile"
      vim.bo[preview_buf].swapfile = false
      vim.bo[preview_buf].modifiable = true
      if ok_preview then
        local lines = fallback
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
        if preview_syntax then
          vim.bo[preview_buf].syntax = preview_syntax
        elseif path then
          preview.set_syntax(preview_buf, path)
        end
        preview.apply_ansi_highlights(preview_buf, preview_highlights)
        local match = preview_match(item, lines)
        if match and match.lnum and match.lnum <= #lines then
          vim.api.nvim_set_hl(0, "NativePickerPreviewLine", { link = "CursorLine", default = true })
          vim.api.nvim_set_hl(0, "NativePickerPreviewMatch", { link = "Search", default = true })
          vim.api.nvim_buf_set_extmark(preview_buf, preview_namespace, match.lnum - 1, 0, {
            line_hl_group = "NativePickerPreviewLine",
            hl_eol = true,
          })
          if match.col and match.length and match.length > 0 then
            local preview_line = lines[match.lnum] or ""
            local start_col = math.min(math.max(match.col - 1, 0), #preview_line)
            local end_col = math.min(start_col + match.length, #preview_line)
            if end_col > start_col then
              vim.api.nvim_buf_set_extmark(preview_buf, preview_namespace, match.lnum - 1, start_col, {
                end_col = end_col,
                hl_group = "NativePickerPreviewMatch",
              })
            end
          end
        end
      else
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { fallback })
      end
      vim.bo[preview_buf].modifiable = false
      if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
        local ok_p, win_p = pcall(vim.api.nvim_open_win, preview_buf, false, next_preview_config)
        if ok_p then
          preview_win = win_p
          vim.wo[preview_win].wrap = false
          vim.wo[preview_win].number = true
          vim.wo[preview_win].relativenumber = false
          vim.wo[preview_win].cursorline = true
        end
      else
        vim.api.nvim_win_set_buf(preview_win, preview_buf)
        pcall(vim.api.nvim_win_set_config, preview_win, next_preview_config)
      end
      if ok_preview then
        local lnum = preview_target_lnum(item)
        if lnum then
          pcall(vim.api.nvim_win_set_cursor, preview_win, { math.min(lnum, vim.api.nvim_buf_line_count(preview_buf)), 0 })
          vim.api.nvim_win_call(preview_win, function() pcall(vim.cmd, "normal! zz") end)
        end
      end
    end

    local function select_index(index)
      local actual_index = index and (page_start + index - 1) or nil
      if actual_index and current_candidates[actual_index] then
        local choice = current_candidates[actual_index]
        close_candidates_window()
        on_choice(choice)
      end
    end

    local function select_cursor()
      if not candidates_win or not vim.api.nvim_win_is_valid(candidates_win) then
        return
      end
      local row = vim.api.nvim_win_get_cursor(candidates_win)[1]
      select_index(row - 2)
    end

    local function open_split(command)
      local item = current_item()
      local path = preview_path(item)
      if path then
        close_candidates_window()
        vim.cmd(command .. " " .. vim.fn.fnameescape(path))
        if item and item.lnum then
          vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
        end
      end
    end

    local function open_quickfix()
      local qf_items = picker_quickfix.items(current_candidates, opts)

      if #qf_items == 0 then
        notify(prompt .. ": no quickfix-compatible results", vim.log.levels.WARN)
        return
      end

      close_candidates_window()
      local title = (opts.quickfix_title or prompt) .. (current_query ~= "" and (" /" .. current_query) or "")
      vim.fn.setqflist({}, " ", { title = title, items = qf_items })
      last_qf_title = title
      vim.cmd("copen")
    end

    local function scroll_preview(delta)
      if preview_win and vim.api.nvim_win_is_valid(preview_win) then
        vim.api.nvim_win_call(preview_win, function()
          vim.cmd("normal! " .. math.abs(delta) .. (delta > 0 and "\5" or "\25"))
        end)
      end
    end

    local function move_cursor(delta)
      local cursor = vim.api.nvim_win_get_cursor(candidates_win)
      local last = math.min(#current_candidates - page_start + 3, math.max(3, height - 1))
      vim.api.nvim_win_set_cursor(candidates_win, { math.max(3, math.min(cursor[1] + delta, last)), 0 })
      update_preview()
    end

    local function filtered_items_from_state()
      local next_candidates = current_query == "" and items or picker_filter.items(items, opts, current_query)
      if current_quick_filter then
        next_candidates = picker_filter.by_predicate(next_candidates, current_quick_filter.predicate)
      end
      if current_regex_pattern then
        next_candidates = picker_filter.by_regex(next_candidates, opts, current_regex_pattern)
      end
      return next_candidates
    end

    local function apply_filter_state(empty_message)
      local next_candidates = filtered_items_from_state()
      if #next_candidates == 0 then
        notify(empty_message or (prompt .. ": no results"), vim.log.levels.WARN)
        return false
      end

      current_filter_label = active_filter_label()
      current_candidates = next_candidates
      choosing_quick_filter = false
      page_start = 1
      if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
        vim.api.nvim_set_current_win(candidates_win)
      end
      render()
      update_preview()
      return true
    end

    local function ask_filter()
      vim.ui.input({
        prompt = prompt .. " / ",
        default = current_query,
        scope = opts.scope or "project",
      }, function(input)
        if input == nil then
          return
        end

        local next_query = vim.trim(input)
        local previous_query = current_query
        current_query = next_query
        if not apply_filter_state(prompt .. ": no results for " .. next_query) then
          current_query = previous_query
          return
        end
      end)
    end

    local function apply_quick_filter(filter)
      if type(filter) ~= "table" or type(filter.predicate) ~= "function" then
        return
      end

      local previous_filter = current_quick_filter
      current_quick_filter = filter
      if not apply_filter_state(prompt .. ": no " .. (filter.label or "filtered") .. " results") then
        current_quick_filter = previous_filter
        return
      end
    end

    local function clear_active_filters()
      if not current_quick_filter then
        return
      end
      current_quick_filter = nil
      apply_filter_state()
    end

    local function select_quick_filter_key(key)
      local filters = opts.filters or opts.quick_filters or {}
      for _, filter in ipairs(filters) do
        if filter.key == key then
          apply_quick_filter(filter)
          return true
        end
      end
      notify("Unknown filter: " .. key .. " (" .. picker_filter.quick_filter_menu(filters) .. ")", vim.log.levels.WARN)
      choosing_quick_filter = false
      render()
      return true
    end

    local function ask_quick_filter()
      local filters = opts.filters or opts.quick_filters or {}
      if vim.tbl_isempty(filters) then
        return
      end
      choosing_quick_filter = true
      render()
    end

    local function ask_regex_filter()
      vim.ui.input({
        prompt = prompt .. " regex / ",
        scope = opts.scope or "project",
      }, function(pattern)
        pattern = vim.trim(pattern or "")
        if pattern == "" then
          return
        end

        local previous_pattern = current_regex_pattern
        current_regex_pattern = pattern
        if not apply_filter_state(prompt .. ": no regex results for " .. pattern) then
          current_regex_pattern = previous_pattern
          return
        end
      end)
    end

    local function page(delta)
      local total = #current_candidates
      local visible_limit = math.max(1, height - 3)
      if total <= visible_limit then
        return
      end
      local max_start = math.floor((total - 1) / visible_limit) * visible_limit + 1
      page_start = math.max(1, math.min(page_start + delta * visible_limit, max_start))
      render()
      update_preview()
      vim.cmd("normal! zz")
    end

    local function page_up_or_top()
      if not candidates_win or not vim.api.nvim_win_is_valid(candidates_win) then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(candidates_win)
      if cursor[1] > 3 then
        vim.api.nvim_win_set_cursor(candidates_win, { 3, 0 })
        update_preview()
        vim.cmd("normal! zz")
        return
      end
      page(-1)
    end

    local function jump_group(delta)
      if type(opts.group_item) ~= "function" then return end
      local current_index = page_start + (vim.api.nvim_win_get_cursor(candidates_win)[1] - 3)
      local current_group = picker_filter.item_group(current_candidates[current_index], opts)
      local index = current_index
      while index >= 1 and index <= #current_candidates do
        index = index + delta
        local group = picker_filter.item_group(current_candidates[index], opts)
        if group and group ~= current_group then
          local visible_limit = math.max(1, height - 3)
          page_start = math.floor((index - 1) / visible_limit) * visible_limit + 1
          render()
          vim.api.nvim_win_set_cursor(candidates_win, { index - page_start + 3, 0 })
          update_preview()
          return
        end
      end
    end

    local function toggle_preview()
      if not has_preview then return end
      preview_enabled = not preview_enabled
      if preview_enabled then
        update_preview()
      else
        preview_maximized = false
        close_preview()
      end
    end

    local function toggle_preview_zoom()
      if not has_preview then return end
      if not preview_enabled then
        preview_enabled = true
      end
      preview_maximized = not preview_maximized
      update_preview()
    end

    local function focus_preview()
      if not has_preview then return end
      if not preview_enabled then
        preview_enabled = true
        update_preview()
      end
      if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then return end
      vim.api.nvim_win_set_config(preview_win, vim.tbl_extend("force", vim.api.nvim_win_get_config(preview_win), {
        focusable = true,
      }))
      vim.api.nvim_set_current_win(preview_win)

      local preview_map_opts = { buffer = preview_buf, silent = true }
      vim.keymap.set("n", "<A-p>", function()
        if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
          vim.api.nvim_set_current_win(candidates_win)
        end
      end, preview_map_opts)
      vim.keymap.set("n", "q", function()
        if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
          vim.api.nvim_set_current_win(candidates_win)
        end
      end, preview_map_opts)
      vim.keymap.set("n", "<Esc>", function()
        if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
          vim.api.nvim_set_current_win(candidates_win)
        end
      end, preview_map_opts)
    end

    local function toggle_picker_layout()
      if not has_preview then return end
      picker_layout = picker_layout == "intellij_grep" and "default" or "intellij_grep"
      intellij_grep = picker_layout == "intellij_grep"
      preview_maximized = false
      calculate_layout()

      if candidates_win and vim.api.nvim_win_is_valid(candidates_win) then
        pcall(vim.api.nvim_win_set_config, candidates_win, {
          relative = "editor",
          row = row,
          col = col,
          width = width,
          height = height,
          style = "minimal",
          border = "single",
          zindex = 50,
          focusable = true,
          noautocmd = true,
        })
      end

      render()
      update_preview()
    end

    local function toggle_descriptions()
      show_descriptions = not show_descriptions
      render()
    end

    local function cancel_or_close()
      if choosing_quick_filter then
        choosing_quick_filter = false
        render()
        return
      end
      close_candidates_window()
    end

    local function run_or_select_quick_filter(key, action)
      return function()
        if choosing_quick_filter then
          select_quick_filter_key(key)
          return
        end
        action()
      end
    end

    local map_opts = { buffer = candidates_buf, silent = true }
    vim.keymap.set("n", "<CR>", select_cursor, map_opts)
    vim.keymap.set("n", "<C-q>", open_quickfix, map_opts)
    vim.keymap.set("n", "<C-v>", function() open_split("vsplit") end, map_opts)
    vim.keymap.set("n", "<C-x>", function() open_split("split") end, map_opts)
    vim.keymap.set("n", "/", run_or_select_quick_filter("/", ask_filter), map_opts)
    vim.keymap.set("n", "F", ask_quick_filter, map_opts)
    vim.keymap.set("n", "C", run_or_select_quick_filter("C", clear_active_filters), map_opts)
    vim.keymap.set("n", "R", run_or_select_quick_filter("R", ask_regex_filter), map_opts)
    vim.keymap.set("n", "<Tab>", toggle_preview, map_opts)
    vim.keymap.set("n", "<A-p>", focus_preview, map_opts)
    vim.keymap.set("n", "<A-l>", toggle_picker_layout, map_opts)
    vim.keymap.set("n", "?", toggle_descriptions, map_opts)
    vim.keymap.set("n", "z", toggle_preview_zoom, vim.tbl_extend("force", map_opts, { nowait = true }))
    vim.keymap.set("n", "j", run_or_select_quick_filter("j", function() move_cursor(1) end), map_opts)
    vim.keymap.set("n", "k", run_or_select_quick_filter("k", function() move_cursor(-1) end), map_opts)
    vim.keymap.set("n", "<C-n>", function() move_cursor(1) end, map_opts)
    vim.keymap.set("n", "<C-p>", function() move_cursor(-1) end, map_opts)
    vim.keymap.set("n", "<C-u>", page_up_or_top, map_opts)
    vim.keymap.set("n", "<C-d>", function() page(1) end, map_opts)
    vim.keymap.set("n", "<C-f>", function() scroll_preview(height) end, map_opts)
    vim.keymap.set("n", "<C-b>", function() scroll_preview(-height) end, map_opts)
    vim.keymap.set("n", "]g", function() jump_group(1) end, map_opts)
    vim.keymap.set("n", "[g", function() jump_group(-1) end, map_opts)
    vim.keymap.set("n", "q", cancel_or_close, map_opts)
    vim.keymap.set("n", "<Esc>", cancel_or_close, map_opts)
    local reserved_filter_keys = { j = true, k = true, q = true, ["/"] = true, R = true, F = true, C = true }
    for _, filter in ipairs(opts.filters or opts.quick_filters or {}) do
      if filter.key and not reserved_filter_keys[filter.key] then
        vim.keymap.set("n", filter.key, function()
          if choosing_quick_filter then
            select_quick_filter_key(filter.key)
            return
          end
          apply_quick_filter(filter)
        end, map_opts)
      end
    end
    for index = 1, 9 do
      vim.keymap.set("n", tostring(index), function()
        select_index(index)
      end, map_opts)
    end

    render()
    update_preview()
  end

  local function choose(candidates, query)
    query = vim.trim(query or "")
    if #candidates == 0 then
      notify(prompt .. ": no results", vim.log.levels.WARN)
      return
    end

    if (not supports_filter or has_initial_query) and #candidates == 1 and opts.auto_select_single ~= false then
      on_choice(candidates[1])
      return
    end

    if supports_filter then
      open_candidates_picker(candidates, query)
      return
    end

    vim.ui.select(candidates, opts, on_choice)
  end

  if has_initial_query then
    choose(picker_filter.items(items, opts, opts.query), opts.query)
    return
  end

  choose(items, "")
end

function M.with_layout(opts)
  if intellij_grep then
    return vim.tbl_extend("force", opts, { layout = "intellij_grep" })
  end
  return opts
end

function M.is_intellij_grep_enabled()
  return intellij_grep
end

function M.set_intellij_grep(v)
  intellij_grep = v and true or false
end

function M.resume()
  if last_qf_title then
    vim.cmd("copen")
  else
    notify("No native search to resume", vim.log.levels.WARN)
  end
end

return M
