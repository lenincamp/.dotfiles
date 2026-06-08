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
-- Reading the first byte is < 1ms — no subprocess, no CLI call.

local function pane_is_zoomed(pane_id)
  local path = config.zoom_state_dir .. "/wezterm_zoom_" .. pane_id
  local f = io.open(path, "r")
  if not f then return false end
  local first = f:read(1)
  f:close()
  return first == "1"
end

-- ── Navigation ─────────────────────────────────────────────────────────────
--
-- For zoomed panes: send an OSC 1337 user-var to WezTerm (WEZTERM_ZOOM_NAV).
-- WezTerm handles zoom via act.Multiple (toggle → navigate → toggle) using
-- its native API, which correctly targets the destination pane.
--
-- Why not wezterm-cli? Every `wezterm cli zoom-pane` call uses $WEZTERM_PANE
-- (or the TTY-associated pane as fallback), which is always the Neovim pane —
-- so the second toggle re-zooms Neovim instead of the destination pane.

-- Pre-computed base64 of the four direction strings (avoids subprocess).
local dir_base64 = {
  Left  = "TGVmdA==",
  Right = "UmlnaHQ=",
  Up    = "VXA=",
  Down  = "RG93bg==",
}

local function wezterm_navigate(wez_dir, zoomed)
  if zoomed then
    local encoded = dir_base64[wez_dir]
    if not encoded then return end
    -- OSC 1337 SetUserVar — WezTerm fires user-var-changed and handles zoom.
    io.write("\x1b]1337;SetUserVar=WEZTERM_ZOOM_NAV=" .. encoded .. "\x07")
    io.flush()
  else
    vim.fn.jobstart({ "wezterm", "cli", "activate-pane-direction", wez_dir })
  end
end

-- ── Setup ──────────────────────────────────────────────────────────────────

ss.setup({
  multiplexer_integration = nil,

  at_edge = function(ctx)
    local wez_dir = config.dir_map[ctx.direction]
    local pane_id = os.getenv("WEZTERM_PANE")
    if not wez_dir or not pane_id then return end

    wezterm_navigate(wez_dir, pane_is_zoomed(pane_id))
  end,
})
