local M = {}

local data = require("modules.dap.breakpoints.picker.data")
local hooks = require("modules.dap.breakpoints.hooks")
local keymaps = require("modules.dap.breakpoints.picker.keymaps")
local layout_mod = require("modules.dap.breakpoints.picker.layout")
local persistence = require("modules.dap.breakpoints.persistence")
local state = require("modules.dap.breakpoints.state")
local storage = require("modules.dap.breakpoints.storage")

function M.open()
  local ok_dap, _ = pcall(require, "dap")
  if not ok_dap then return end

  hooks.setup({ load = false })

  local items = data.collect()
  if #items == 0 and data.has_saved_project() then
    persistence.load()
    items = data.collect()
  end

  if #items == 0 then
    vim.notify("No breakpoints in this project", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local ns = vim.api.nvim_create_namespace("dap_breakpoint_manager")
  local preview_ns = vim.api.nvim_create_namespace("dap_breakpoint_preview")
  local selected = 1
  local fullscreen = true
  local preview_enabled = true
  local show_descriptions = false
  local breakpoint_layout = "intellij"
  local layout
  local preview_height, list_width

  local function calculate_layout()
    layout = layout_mod.calculate({
      fullscreen = fullscreen,
      item_count = #items,
      layout = breakpoint_layout,
      preview_enabled = preview_enabled,
    })
    preview_height = layout.preview_height
    list_width = layout.list_width
  end

  calculate_layout()

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dap_breakpoints"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].swapfile = false

  local win = vim.api.nvim_open_win(buf, true, layout_mod.list_config(layout, breakpoint_layout, fullscreen))
  local preview_win = vim.api.nvim_open_win(preview_buf, false, layout_mod.preview_config(layout))

  layout_mod.apply_list_options(win)
  layout_mod.apply_preview_options(preview_win)

  local function ensure_preview_buffer()
    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
      return
    end

    preview_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[preview_buf].bufhidden = "wipe"
    vim.bo[preview_buf].buftype = "nofile"
    vim.bo[preview_buf].swapfile = false
  end

  local function close_preview()
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
      vim.api.nvim_win_close(preview_win, true)
    end
    preview_win = nil
  end

  local function ensure_preview_window()
    if not preview_enabled or (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
      return
    end

    ensure_preview_buffer()
    preview_win = vim.api.nvim_open_win(preview_buf, false, layout_mod.preview_config(layout))
    layout_mod.apply_preview_options(preview_win)
  end

  local function close()
    close_preview()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function apply_layout()
    calculate_layout()

    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_config, win, layout_mod.list_config(layout, breakpoint_layout, fullscreen))
    end

    if not preview_enabled then
      close_preview()
      return
    end

    ensure_preview_window()
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
      pcall(vim.api.nvim_win_set_config, preview_win, layout_mod.preview_config(layout))
    end
  end

  local function current_item()
    local rownum = vim.api.nvim_win_get_cursor(win)[1]
    return items[rownum - 2]
  end

  local function update_preview(item)
    if not preview_enabled then
      return
    end

    ensure_preview_window()
    if not item or vim.fn.filereadable(item.filename) ~= 1 then
      return
    end

    local start_line = math.max(1, item.line - math.floor((preview_height - 2) / 2))
    local end_line = item.line + math.floor((preview_height - 2) / 2)
    local ok_lines, lines = pcall(vim.fn.readfile, item.filename, "", end_line)
    if not ok_lines or type(lines) ~= "table" then
      lines = { "Preview unavailable" }
      start_line = 1
    else
      local clipped = {}
      for line = start_line, math.min(end_line, #lines) do
        clipped[#clipped + 1] = lines[line]
      end
      lines = #clipped > 0 and clipped or { "Preview unavailable" }
    end

    vim.bo[preview_buf].modifiable = true
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(preview_buf, preview_ns, 0, -1)
    vim.bo[preview_buf].filetype = vim.filetype.match({ filename = item.filename }) or ""
    vim.bo[preview_buf].modifiable = false

    local target = math.min(math.max(item.line - start_line + 1, 1), #lines)
    vim.api.nvim_set_hl(0, "DapBreakpointPreviewLine", { link = "CursorLine", default = true })
    vim.api.nvim_buf_set_extmark(preview_buf, preview_ns, target - 1, 0, {
      line_hl_group = "DapBreakpointPreviewLine",
      hl_eol = true,
    })
    pcall(vim.api.nvim_win_set_cursor, preview_win, { target, 0 })
  end

  local function status_line()
    if show_descriptions then
      return string.format("Enter/o=jump  n=normal  c=condition  l=logpoint  h=hit  G=move-group  R=rename-group  d=delete  s=save  Tab=preview  A-l=layout:%s  A-f=fullscreen  ?=keys  q=close", breakpoint_layout)
    end
    return string.format("Enter/o  n  c  l  h  G  R  d  s  Tab  A-l:%s  A-f  ?  q", breakpoint_layout)
  end

  local function render(preferred_key)
    items = data.collect()
    if #items == 0 then
      close()
      vim.notify("No breakpoints in this project", vim.log.levels.INFO)
      return
    end

    if preferred_key then
      for index, item in ipairs(items) do
        if item.key == preferred_key then
          selected = index
          break
        end
      end
    end

    local lines = {
      status_line(),
      string.rep("─", list_width - 2),
    }

    for _, item in ipairs(items) do
      local rel = vim.fn.fnamemodify(item.filename, ":~:.")
      local meta = ""
      if item.condition and item.condition ~= "" then
        meta = "  if " .. item.condition
      elseif item.log_message and item.log_message ~= "" then
        meta = "  log " .. item.log_message
      elseif item.hit_condition and item.hit_condition ~= "" then
        meta = "  hit " .. item.hit_condition
      end
      lines[#lines + 1] = string.format("%-10s %s  %s:%d%s", item.group, item.icon, rel, item.line, meta)
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 1, 0, -1)
    for index, item in ipairs(items) do
      local hl = item.log_message and item.log_message ~= "" and "DapLogPoint"
        or item.condition and item.condition ~= "" and "DapBreakpointCondition"
        or "DapBreakpoint"
      vim.api.nvim_buf_add_highlight(buf, ns, hl, index + 1, 11, 12)
    end
    vim.bo[buf].modifiable = false

    selected = math.min(math.max(selected, 1), #items)
    pcall(vim.api.nvim_win_set_cursor, win, { selected + 2, 0 })
    update_preview(items[selected])
  end

  local function jump()
    local item = current_item()
    if not item then return end
    close()
    vim.cmd("edit " .. vim.fn.fnameescape(item.filename))
    vim.api.nvim_win_set_cursor(0, { item.line, 0 })
  end

  local function remove_current()
    local item = current_item()
    if not item then return end
    require("dap.breakpoints").remove(item.bufnr, item.line)
    persistence.mark_dirty()
    persistence.save({ force = true })
    render()
  end

  local function move_cursor(delta)
    selected = math.min(math.max(selected + delta, 1), #items)
    pcall(vim.api.nvim_win_set_cursor, win, { selected + 2, 0 })
    update_preview(items[selected])
  end

  local function toggle_fullscreen()
    fullscreen = not fullscreen
    apply_layout()
    render()
  end

  local function toggle_layout()
    breakpoint_layout = breakpoint_layout == "intellij" and "side" or "intellij"
    apply_layout()
    render()
  end

  local function toggle_preview()
    preview_enabled = not preview_enabled
    apply_layout()
    render()
  end

  local function toggle_descriptions()
    show_descriptions = not show_descriptions
    render()
  end

  local function update_condition()
    local item = current_item()
    if not item then return end
    vim.ui.input({ prompt = "Condition: ", default = item.condition or "", scope = "line" }, function(value)
      if value == nil then return end
      data.set_breakpoint(item, {
        condition = vim.trim(value) ~= "" and value or nil,
      })
      render(item.key)
    end)
  end

  local function update_normal()
    local item = current_item()
    if not item then return end
    data.set_breakpoint(item, {})
    render(item.key)
  end

  local function update_logpoint()
    local item = current_item()
    if not item then return end
    vim.ui.input({ prompt = "Log message: ", default = item.log_message or "", scope = "line" }, function(value)
      if value == nil then return end
      data.set_breakpoint(item, {
        log_message = vim.trim(value) ~= "" and value or nil,
      })
      render(item.key)
    end)
  end

  local function update_hit_condition()
    local item = current_item()
    if not item then return end
    vim.ui.input({ prompt = "Hit condition: ", default = item.hit_condition or "", scope = "line" }, function(value)
      if value == nil then return end
      data.set_breakpoint(item, {
        hit_condition = vim.trim(value) ~= "" and value or nil,
      })
      render(item.key)
    end)
  end

  local function update_group()
    local item = current_item()
    if not item then return end
    vim.ui.input({ prompt = "Move to group (empty=Default): ", default = item.group ~= "Default" and item.group or "", scope = "line" }, function(value)
      if value == nil then return end
      local meta = storage.load_meta(state.active_project_key)
      local group = vim.trim(value)
      if group == "" then
        meta[item.key] = nil
      else
        meta[item.key] = group
      end
      storage.save_meta(meta, state.active_project_key)
      render(item.key)
    end)
  end

  local function rename_group()
    local item = current_item()
    if not item then return end
    local old_group = item.group
    vim.ui.input({ prompt = "Rename group to (empty=Default): ", default = old_group ~= "Default" and old_group or "", scope = "project" }, function(value)
      if value == nil then return end
      local new_group = vim.trim(value)
      local meta = storage.load_meta(state.active_project_key)
      for _, bp in ipairs(items) do
        if bp.group == old_group then
          if new_group == "" or new_group == "Default" then
            meta[bp.key] = nil
          else
            meta[bp.key] = new_group
          end
        end
      end
      storage.save_meta(meta, state.active_project_key)
      render(item.key)
    end)
  end

  keymaps.setup(buf, {
    close = close,
    jump = jump,
    move_cursor = move_cursor,
    remove_current = remove_current,
    rename_group = rename_group,
    save = function()
      persistence.save({ force = true })
      vim.notify("Breakpoints saved", vim.log.levels.INFO)
    end,
    toggle_descriptions = toggle_descriptions,
    toggle_fullscreen = toggle_fullscreen,
    toggle_layout = toggle_layout,
    toggle_preview = toggle_preview,
    update_condition = update_condition,
    update_group = update_group,
    update_hit_condition = update_hit_condition,
    update_logpoint = update_logpoint,
    update_normal = update_normal,
  })

  render()
end

return M
