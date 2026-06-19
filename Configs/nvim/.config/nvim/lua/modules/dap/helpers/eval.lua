local M = {}

local session_helpers = require("modules.dap.helpers.session")
local view_helpers = require("modules.dap.helpers.view")

function M.flatten_expr(text)
  if not text or text == "" then return "" end
  local cleaned = {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    cleaned[#cleaned + 1] = line:gsub("//[^\n]*$", "")
  end
  local joined = table.concat(cleaned, " ")
  joined = joined:gsub("%s+", " ")
  return vim.trim(joined)
end

local function eval_or_set(dap, expr)
  expr = M.flatten_expr(expr)
  if expr == "" then return end

  local session = dap.session()
  if not session or not session.stopped_thread_id then
    vim.notify("Debugger must be stopped to eval/set expression", vim.log.levels.INFO)
    return
  end

  local caps = session_helpers.capabilities(session)
  local lhs, rhs = expr:match("^([%w_%.$%[%]%(%)]+)%s*=%s*(.+)$")

  if lhs and rhs and caps.supportsSetExpression then
    session_helpers.request(session, "setExpression", {
      expression = vim.trim(lhs),
      value = vim.trim(rhs),
      frameId = session_helpers.current_frame_id(session),
    })
  else
    session_helpers.eval_in_repl(dap, session, expr)
  end
  view_helpers.open_repl_view(dap)
end

function M.open_floating(dap, initial_lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  if ft and ft ~= "" then
    pcall(function() vim.bo[buf].filetype = ft end)
  end
  if initial_lines and #initial_lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, initial_lines)
  end

  local width = math.min(100, math.floor(vim.o.columns * 0.8))
  local height = math.min(15, math.max(6, math.floor(vim.o.lines * 0.35)))
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Debug · Evaluate  (<C-CR>/<C-s> submit · q close) ",
    title_pos = "center",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    close()
    eval_or_set(dap, table.concat(lines, "\n"))
  end

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set({ "n", "i" }, "<C-CR>", submit, opts)
  vim.keymap.set({ "n", "i" }, "<C-s>", submit, opts)
  vim.keymap.set({ "n", "i" }, "<D-CR>", submit, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
end

function M.eval_expression_prompt(dap)
  M.open_floating(dap, nil, vim.bo.filetype)
end

function M.set_expression_prompt(dap)
  vim.ui.input({ prompt = "Set expression (name=value): ", scope = "cursor" }, function(expr)
    if not expr or vim.trim(expr) == "" then return end

    local session = dap.session()
    if not session or not session.stopped_thread_id then
      vim.notify("Debugger must be stopped to set variable", vim.log.levels.INFO)
      return
    end

    local trimmed = vim.trim(expr)
    local lhs, rhs = trimmed:match("^([%w_%.$%[%]%(%)]+)%s*=%s*(.+)$")
    if not lhs or not rhs then
      vim.notify("Use format: variable=value", vim.log.levels.WARN)
      return
    end

    local caps = session_helpers.capabilities(session)
    if caps.supportsSetExpression then
      session_helpers.request(session, "setExpression", {
        expression = vim.trim(lhs),
        value = vim.trim(rhs),
        frameId = session_helpers.current_frame_id(session),
      })
      return
    end

    session_helpers.eval_in_repl(dap, session, string.format("%s = %s", vim.trim(lhs), vim.trim(rhs)))
  end)
end

function M.visual_selection_text()
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  if start_row == 0 or end_row == 0 then return nil end
  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then return nil end
  lines[1] = string.sub(lines[1], start_col + 1)
  lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
  return vim.trim(table.concat(lines, "\n"))
end

function M.eval_visual_selection_in_repl(dap)
  local raw = M.visual_selection_text()
  if not raw or raw == "" then return end

  if raw:find("\n") then
    M.open_floating(dap, vim.split(raw, "\n", { plain = true }), vim.bo.filetype)
  else
    eval_or_set(dap, raw)
  end
end

return M
