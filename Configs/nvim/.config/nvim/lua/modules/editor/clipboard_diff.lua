local M = {}
local registry = require("modules.bootstrap.registry")

local CLIPBOARD_BUF_MARK = "clipboard_diff_buffer"

local function get_clipboard_lines()
  local lines = vim.fn.getreg("+", 1, true)
  if type(lines) ~= "table" then
    lines = { tostring(lines or "") }
  end
  if #lines == 0 then
    lines = { "" }
  end
  return lines
end

local function write_buffer_to_clipboard(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  vim.fn.setreg("+", lines)
  vim.notify("Clipboard updated from diff buffer", vim.log.levels.INFO)
end

local function setup_clipboard_buffer(bufnr, source_buf)
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].filetype = vim.bo[source_buf].filetype

  vim.b[bufnr][CLIPBOARD_BUF_MARK] = true

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function(args)
      write_buffer_to_clipboard(args.buf)
      vim.bo[args.buf].modified = false
    end,
  })

  vim.keymap.set("n", "<leader>cW", function()
    write_buffer_to_clipboard(bufnr)
    vim.bo[bufnr].modified = false
  end, { buffer = bufnr, desc = "Clipboard: write from diff buffer" })
end

function M.compare_with_clipboard()
  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_get_current_buf()

  vim.cmd("rightbelow vnew")

  local clip_win = vim.api.nvim_get_current_win()
  local clip_buf = vim.api.nvim_get_current_buf()

  setup_clipboard_buffer(clip_buf, source_buf)

  local clipboard_lines = get_clipboard_lines()
  vim.api.nvim_buf_set_lines(clip_buf, 0, -1, false, clipboard_lines)
  vim.api.nvim_buf_set_name(clip_buf, "[Clipboard Diff]")
  vim.bo[clip_buf].modified = false

  vim.api.nvim_win_call(source_win, function()
    vim.cmd("diffthis")
    registry.setup_diff_mappings()
  end)

  vim.api.nvim_win_call(clip_win, function()
    vim.cmd("diffthis")
    registry.setup_diff_mappings()
  end)

  vim.api.nvim_set_current_win(source_win)
  vim.notify("Clipboard diff opened. Use do/dp to move changes. In clipboard window use :write or <leader>cW to sync back.", vim.log.levels.INFO)
end

return M
