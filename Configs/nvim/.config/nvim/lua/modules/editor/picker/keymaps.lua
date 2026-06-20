local M = {}

local input_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.*/:@#$%^&+=,[]{}()\\!?|~"
local input_command_keys = { F = true, C = true, R = true }
local reserved_filter_keys = { j = true, k = true, q = true, ["/"] = true, R = true, F = true, C = true }

local function set(lhs, rhs, opts, extra)
  vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, extra or {}))
end

function M.setup(args)
  local opts = args.opts or {}
  local map_opts = { buffer = args.buffer, silent = true }
  local custom_actions = opts.actions or {}

  set("<CR>", args.select_cursor, map_opts)
  set("<C-q>", args.open_quickfix, map_opts)
  set("<C-v>", function() args.open_split("vsplit") end, map_opts)
  set("<C-x>", custom_actions["<C-x>"] and args.run_action(custom_actions["<C-x>"]) or function() args.open_split("split") end, map_opts)
  set("/", args.run_or_select_quick_filter("/", args.ask_filter), map_opts)
  set("F", args.ask_quick_filter, map_opts)
  set("C", args.run_or_select_quick_filter("C", args.clear_active_filters), map_opts)
  set("R", args.run_or_select_quick_filter("R", args.ask_regex_filter), map_opts)
  set("<Tab>", args.toggle_preview, map_opts)
  set("<C-o>", args.focus_preview, map_opts)
  set("<A-l>", args.toggle_picker_layout, map_opts)
  set("?", args.toggle_descriptions, map_opts)
  set("z", args.toggle_preview_zoom, map_opts, { nowait = true })
  set("j", args.run_or_select_quick_filter("j", function() args.move_cursor(1) end), map_opts)
  set("k", args.run_or_select_quick_filter("k", function() args.move_cursor(-1) end), map_opts)
  set("<C-n>", function() args.move_cursor(1) end, map_opts)
  set("<C-p>", function() args.move_cursor(-1) end, map_opts)
  set("<C-u>", args.page_up_or_top, map_opts)
  set("<C-d>", function() args.page(1) end, map_opts)
  set("<C-f>", args.scroll_preview_down, map_opts)
  set("<C-b>", args.scroll_preview_up, map_opts)
  set("]g", function() args.jump_group(1) end, map_opts)
  set("[g", function() args.jump_group(-1) end, map_opts)
  set("q", args.cancel_or_close, map_opts)
  set("<Esc>", args.cancel_or_close, map_opts)

  if opts.input_mode then
    set("<BS>", args.backspace_query, map_opts)
    set("<C-h>", args.backspace_query, map_opts)
    set("<C-w>", args.clear_query, map_opts)
    for _, char in ipairs(vim.split(input_chars, "", { plain = true, trimempty = true })) do
      if not input_command_keys[char] then
        set(char, args.append_query(char), map_opts)
      end
    end
    if not opts.multi_select then
      set(" ", args.append_query(" "), map_opts)
    end
  end

  if opts.multi_select then
    set(" ", args.toggle_selected, map_opts)
    set("m", args.toggle_selected, map_opts)
  end

  for lhs, action in pairs(custom_actions) do
    if lhs ~= "<C-x>" and type(action) == "table" and type(action.fn) == "function" then
      set(lhs, args.run_action(action), map_opts)
    end
  end

  for _, filter in ipairs(opts.filters or opts.quick_filters or {}) do
    if not opts.input_mode and filter.key and not reserved_filter_keys[filter.key] then
      set(filter.key, function()
        if args.is_choosing_quick_filter() then
          args.select_quick_filter_key(filter.key)
          return
        end
        args.apply_quick_filter(filter)
      end, map_opts)
    end
  end

  for index = 1, 9 do
    set(tostring(index), function()
      args.select_index(index)
    end, map_opts)
  end
end

return M
