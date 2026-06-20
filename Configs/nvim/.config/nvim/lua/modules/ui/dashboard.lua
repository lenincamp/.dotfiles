local M = {}

local actions = require("modules.ui.dashboard.actions")
local content = require("modules.ui.dashboard.content")
local highlights = require("modules.ui.highlights")
local view = require("modules.ui.dashboard.view")
local window = require("modules.ui.dashboard.window")

M.header = content.header
M.buttons = content.buttons

function M.centered_header_lines()
  return content.centered_lines()
end

function M.effective_width()
  return content.effective_width()
end

local function cleanup_dashboard_shadow_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local bt = vim.bo[buf].buftype
      local modified = vim.bo[buf].modified
      if name == "" and bt == "" and not modified then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end

local function apply_dashboard_keymaps(bufnr)
  if vim.b[bufnr].pure_dashboard_keymaps_applied then
    return
  end

  for _, btn in ipairs(M.buttons) do
    vim.keymap.set("n", btn.key, function()
      actions.run(btn.action)
    end, {
      buffer = bufnr,
      silent = true,
      nowait = true,
      noremap = true,
      desc = "Dashboard: " .. btn.desc,
    })
  end

  vim.b[bufnr].pure_dashboard_keymaps_applied = true
end

local function setup_dashboard_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not window.is_dashboard_buffer(bufnr) then
    return
  end

  window.apply_options()
  apply_dashboard_keymaps(bufnr)

  if not vim.b[bufnr].pure_dashboard_cleanup_done then
    vim.b[bufnr].pure_dashboard_cleanup_done = true
    vim.schedule(cleanup_dashboard_shadow_buffers)
  end
end

function M.open()
  view.setup_highlights()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "snacks_dashboard"
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, M.centered_header_lines())
  vim.bo[bufnr].modifiable = false
  view.apply_highlights(bufnr)

  window.save_restore_state()
  window.apply_options()

  setup_dashboard_buffer(bufnr)
end

function M.setup()
  if M._setup_done then return end
  M._setup_done = true

  view.setup_highlights()

  vim.api.nvim_create_user_command("Dashboard", M.open, { desc = "Open native dashboard" })

  highlights.register("dashboard", view.setup_highlights)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PureDashboardBufferCleanup", { clear = true }),
    pattern = { "snacks_dashboard", "pure_dashboard" },
    callback = function(args) setup_dashboard_buffer(args.buf) end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("PureDashboardBufEnter", { clear = true }),
    callback = function(args)
      setup_dashboard_buffer(args.buf)
      if not window.is_dashboard_buffer(args.buf) and vim.w.pure_dashboard_restore_number ~= nil then
        window.restore_options(vim.api.nvim_get_current_win())
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("PureNativeDashboard", { clear = true }),
    callback = function()
      if window.should_open() then M.open() end
    end,
  })
end

return M
