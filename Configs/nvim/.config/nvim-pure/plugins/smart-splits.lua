local ok, ss = pcall(require, "smart-splits")
if not ok then return end

-- ── Config ─────────────────────────────────────────────────────────────────

local config = {
  zoom_state_dir = "/tmp", -- must match nav_config.zoom_state_dir in .wezterm.lua
  dir_map = {
    left  = "Left",  h = "Left",
    right = "Right", l = "Right",
    up    = "Up",    k = "Up",
    down  = "Down",  j = "Down",
  },
}

-- ── Zoom state ─────────────────────────────────────────────────────────────
--
-- WezTerm writes /tmp/wezterm_zoom_<pane_id> on every zoom toggle and on
-- update-status. Format: "<zoomed> <tab_id> <pane_id1>,<pane_id2>,..."
-- Reading the file is < 1ms — no subprocess, no CLI call.

local function read_zoom_state(pane_id)
  local path = config.zoom_state_dir .. "/wezterm_zoom_" .. pane_id
  local f = io.open(path, "r")
  if not f then return false, nil end
  local content = f:read("*a"); f:close()

  local zoomed, _, pane_list = content:match("^(%d+) (%d+) (.+)")
  if zoomed ~= "1" then return false, nil end

  -- For 2-pane tabs the target is unambiguous; return it pre-resolved.
  local ids = {}
  for id in pane_list:gmatch("(%d+)") do ids[#ids + 1] = id end
  if #ids ~= 2 then return true, nil end -- zoomed, but 3+ panes: caller decides

  for _, id in ipairs(ids) do
    if id ~= pane_id then return true, id end
  end
  return true, nil
end

-- ── Navigation actions ─────────────────────────────────────────────────────

local function navigate_zoomed(target)
  -- Activate the target pane (WezTerm unzooms implicitly) then re-zoom it.
  -- Two async CLI calls; neovim is not blocked.
  vim.fn.jobstart({
    "sh", "-c",
    "wezterm cli activate-pane --pane-id " .. target
      .. " && wezterm cli zoom-pane --pane-id " .. target .. " --zoom",
  })
end

local function navigate_normal(pane_id, direction)
  vim.fn.jobstart({
    "wezterm", "cli", "activate-pane-direction",
    "--pane-id", pane_id, direction,
  })
end

-- ── Setup ──────────────────────────────────────────────────────────────────

ss.setup({
  multiplexer_integration = nil,

  at_edge = function(ctx)
    local direction = config.dir_map[ctx.direction]
    local pane_id   = os.getenv("WEZTERM_PANE")
    if not direction or not pane_id then return end

    local is_zoomed, target = read_zoom_state(pane_id)

    if is_zoomed and target then
      navigate_zoomed(target)
    else
      navigate_normal(pane_id, direction)
    end
  end,
})
