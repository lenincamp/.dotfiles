local M = {}

function M.line_completion()
  local line = vim.api.nvim_get_current_line()
  local ft = vim.bo.filetype

  local stack = {}
  local open_ch = { ["("] = ")", ["["] = "]", ["{"] = "}" }
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
  for i = #stack, 1, -1 do
    closes = closes .. stack[i]
  end

  local semi_fts = {
    java = true,
    javascript = true,
    typescript = true,
    javascriptreact = true,
    typescriptreact = true,
    css = true,
    scss = true,
  }
  local tail = vim.trim(line .. closes):sub(-1)
  local suffix = closes
  if semi_fts[ft] and tail ~= ";" and tail ~= "{" then
    suffix = suffix .. ";"
  end

  local keys = "<Esc>A" .. suffix .. "<CR>"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

function M.duplicate_line_or_selection(force_visual)
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

return M
