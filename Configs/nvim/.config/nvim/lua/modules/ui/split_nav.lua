local M = {}

local tmux_directions = {
  h = "L",
  j = "D",
  k = "U",
  l = "R",
}

local function select_tmux_pane(direction)
  local tmux_direction = tmux_directions[direction]
  if not tmux_direction or vim.env.TMUX == nil or vim.fn.executable("tmux") ~= 1 then
    return
  end

  pcall(vim.system, { "tmux", "select-pane", "-" .. tmux_direction }, { detach = true })
end

function M.move(direction)
  local before = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. direction)

  if vim.api.nvim_get_current_win() == before then
    select_tmux_pane(direction)
  end
end

return M
