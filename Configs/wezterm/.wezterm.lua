local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ── Helpers ────────────────────────────────────────────────────────────────

local function basename(path)
	if not path or path == "" then return "" end
	return path:match("([^/\\]+)$") or path
end

-- ── Core appearance ────────────────────────────────────────────────────────

config.font = wezterm.font_with_fallback({
	{ family = "0xProto",     scale = 1.30 },
	{ family = "Maple Mono NF", scale = 1.30 },
})
config.harfbuzz_features        = { "zero", "ss01", "cv05" }
config.line_height               = 1.35
config.window_decorations        = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 24
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines          = 3000
config.default_workspace         = "main"
config.default_cursor_style      = "BlinkingBlock"
config.inactive_pane_hsb         = { saturation = 0.95, brightness = 0.8 }
config.window_padding            = { left = 0, right = 0, top = 0, bottom = 0 }

-- ── Plugins (safe require) ─────────────────────────────────────────────────

local ok_ws, workspace_switcher =
	pcall(wezterm.plugin.require, "https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
if ok_ws and workspace_switcher then
	workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"
end

local function workspace_switch_action()
	if ok_ws and workspace_switcher and workspace_switcher.switch_workspace then
		return workspace_switcher.switch_workspace()
	end
	return act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" })
end

-- ── Colour schemes ─────────────────────────────────────────────────────────

local function scheme_for_appearance(appearance)
	return appearance:find("Dark") and "Catppuccin Mocha" or "Catppuccin Latte"
end

config.color_scheme  = scheme_for_appearance(wezterm.gui.get_appearance())
local builtin_schemes = wezterm.color.get_builtin_schemes()

local function get_current_scheme(window)
	local overrides = window:get_config_overrides() or {}
	local name = overrides.color_scheme or config.color_scheme
	return name, builtin_schemes[name]
end

local function set_window_color_scheme(window, name)
	local overrides = window:get_config_overrides() or {}
	overrides.color_scheme = name
	local s = builtin_schemes[name]
	if s then
		overrides.colors = overrides.colors or {}
		overrides.colors.tab_bar = {
			background = s.background,
			active_tab        = { bg_color = s.ansi[5], fg_color = s.background, intensity = "Bold" },
			inactive_tab      = { bg_color = s.background, fg_color = s.foreground },
			inactive_tab_hover = { bg_color = s.ansi[1], fg_color = s.foreground, italic = true },
			new_tab           = { bg_color = s.background, fg_color = s.ansi[2] },
			new_tab_hover     = { bg_color = s.ansi[4], fg_color = s.background, intensity = "Bold" },
		}
	end
	window:set_config_overrides(overrides)
end

local scheme_choices = (function()
	local choices = {}
	for name in pairs(builtin_schemes) do
		choices[#choices + 1] = { label = name, id = name }
	end
	table.sort(choices, function(a, b) return a.label:lower() < b.label:lower() end)
	return choices
end)()

wezterm.on("choose-color-scheme", function(window, pane)
	window:perform_action(
		act.InputSelector({
			title   = "Select Color Scheme",
			choices = scheme_choices,
			action  = wezterm.action_callback(function(win, _, id)
				if id then set_window_color_scheme(win, id) end
			end),
		}),
		pane
	)
end)

-- ── Navigation ─────────────────────────────────────────────────────────────
--
-- Design:
--   • vim pane  → forward key to smart-splits; at_edge handles cross-pane
--     (zoom-aware: reads /tmp/wezterm_zoom_<id> written by write_zoom_state)
--   • zoomed, not vim → act.Multiple (atomic, 1 frame, no flicker)
--   • not zoomed, not vim → ActivatePaneDirection
--
-- write_zoom_state is called from the zoom keybinding and update-status so
-- the file stays current; neovim reads it to avoid a blocking CLI call.

local nav_config = {
	vim_processes    = { nvim = true, vim = true }, -- foreground process names treated as vim
	zoom_state_dir   = "/tmp",                      -- directory for per-pane zoom state files
}

local function write_zoom_state(window)
	local tab = window:active_tab()
	if not tab then return end
	local tid   = tab:tab_id()
	local panes = tab:panes_with_info()
	local ids   = {}
	for _, p in ipairs(panes) do ids[#ids + 1] = tostring(p.pane:pane_id()) end
	local id_list = table.concat(ids, ",")
	for _, p in ipairs(panes) do
		local path = nav_config.zoom_state_dir .. "/wezterm_zoom_" .. tostring(p.pane:pane_id())
		local f = io.open(path, "w")
		if f then
			f:write(string.format("%s %d %s", p.is_zoomed and "1" or "0", tid, id_list))
			f:close()
		end
	end
end

local function is_vim(pane)
	return nav_config.vim_processes[basename(pane:get_foreground_process_name() or "")] == true
end

local function is_tab_zoomed(window)
	local tab = window:active_tab()
	if tab then
		for _, p in ipairs(tab:panes_with_info()) do
			if p.is_active then return p.is_zoomed end
		end
	end
	return false
end

local dir_to_key = { Left = "h", Down = "j", Up = "k", Right = "l" }

local function move_pane_key(direction)
	return wezterm.action_callback(function(window, pane)
		if is_vim(pane) then
			window:perform_action(act.SendKey({ key = dir_to_key[direction], mods = "CTRL" }), pane)
		elseif is_tab_zoomed(window) then
			window:perform_action(
				act.Multiple({ act.TogglePaneZoomState, act.ActivatePaneDirection(direction), act.TogglePaneZoomState }),
				pane
			)
			write_zoom_state(window)
		else
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		end
	end)
end

-- ── Session actions ─────────────────────────────────────────────────────────

local function prompt_action(label, callback)
	return act.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { AnsiColor = "Fuchsia" } },
			{ Text = label },
		}),
		action = wezterm.action_callback(callback),
	})
end

local function create_workspace(window, pane)
	window:perform_action(act.PopKeyTable, pane)
	window:perform_action(
		prompt_action("New workspace name:", function(win, p, line)
			if line and line ~= "" then
				win:perform_action(act.SwitchToWorkspace({ name = line }), p)
			end
		end),
		pane
	)
end

local function rename_workspace(window, pane)
	window:perform_action(act.PopKeyTable, pane)
	local current = window:active_workspace()
	window:perform_action(
		prompt_action("Rename '" .. current .. "' to:", function(_, _, line)
			if line and line ~= "" then
				wezterm.mux.rename_workspace(current, line)
			end
		end),
		pane
	)
end

-- ── Keybindings ────────────────────────────────────────────────────────────

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

config.keys = {
	-- Leader passthrough
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Utility
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "t", mods = "LEADER", action = act.EmitEvent("choose-color-scheme") },

	-- Workspaces / sessions
	{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "session", one_shot = false }) },

	-- Tabs
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{
		key = ",", mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, _, line)
				if line then window:active_tab():set_title(line) end
			end),
		}),
	},
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab",  one_shot = false }) },

	-- Panes
	{ key = "-",          mods = "LEADER",       action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|",          mods = "LEADER",       action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h",          mods = "LEADER",       action = act.AdjustPaneSize({ "Left",  15 }) },
	{ key = "j",          mods = "LEADER",       action = act.AdjustPaneSize({ "Down",  15 }) },
	{ key = "k",          mods = "LEADER",       action = act.AdjustPaneSize({ "Up",    15 }) },
	{ key = "l",          mods = "LEADER",       action = act.AdjustPaneSize({ "Right", 15 }) },
	{ key = "phys:Space", mods = "LEADER",       action = act.RotatePanes("Clockwise") },
	{ key = "x",          mods = "LEADER",       action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "r",          mods = "LEADER",       action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{ key = "m",          mods = "LEADER|CTRL",  action = act.ActivateKeyTable({ name = "move_pane",   one_shot = false }) },
	{
		key = "!", mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(_, pane) pane:move_to_new_tab() end),
	},
	-- Zoom (also writes state file for neovim's fast zoom detection)
	{
		key = "m", mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act.TogglePaneZoomState, pane)
			write_zoom_state(window)
		end),
	},

	-- Smart navigation (vim-aware, zoom-aware)
	{ key = "h", mods = "CTRL", action = move_pane_key("Left") },
	{ key = "j", mods = "CTRL", action = move_pane_key("Down") },
	{ key = "k", mods = "CTRL", action = move_pane_key("Up") },
	{ key = "l", mods = "CTRL", action = move_pane_key("Right") },
}

for i = 1, 9 do
	config.keys[#config.keys + 1] = { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) }
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left",  5 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down",  5 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up",    5 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter",  action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter",  action = "PopKeyTable" },
	},
	session = {
		{ key = "w",      action = workspace_switch_action() },
		{ key = "s",      action = wezterm.action_callback(create_workspace) },
		{ key = "r",      action = wezterm.action_callback(rename_workspace) },
		{ key = "[",      action = act.SwitchWorkspaceRelative(1) },
		{ key = "]",      action = act.SwitchWorkspaceRelative(-1) },
		{ key = "p",      action = act.SwitchToWorkspace({ name = "main" }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter",  action = "PopKeyTable" },
	},
	move_pane = {
		{ key = "h",      action = act.RotatePanes("CounterClockwise") },
		{ key = "l",      action = act.RotatePanes("Clockwise") },
		{ key = "s",      action = act.PaneSelect({ mode = "SwapWithActive", alphabet = "adfghjklqwertyuiopzxcvbnm" }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter",  action = "PopKeyTable" },
	},
}

-- ── Tab bar ────────────────────────────────────────────────────────────────

config.tab_bar_at_bottom        = true
config.use_fancy_tab_bar        = false
config.status_update_interval   = 5000
config.hide_tab_bar_if_only_one_tab = true

-- ── Status line ────────────────────────────────────────────────────────────

local status_config = {
	show_zoom     = true,
	show_dir      = true,
	show_git      = true,
	show_cmd      = true,
	show_datetime = true,
	datetime_fmt  = "%Y-%m-%d %H:%M",
}

local left_status_cache  = {}
local right_status_cache = {}

local function pane_is_zoomed(window)
	local tab = window:mux_window():active_tab()
	if not tab then return false end
	for _, p in ipairs(tab:panes_with_info()) do
		if p.is_active and p.is_zoomed then return true end
	end
	return false
end

-- Git branch — reads .git/HEAD directly (no subprocess). Supports worktrees.
local git_cache        = {}
local git_last_cwd     = {}
local git_last_checked = {}

local function read_git_head(base)
	local f = io.open(base .. "/.git/HEAD", "r")
	if f then
		local head = f:read("*l"); f:close()
		if head then
			local ref = head:match("^ref:%s*(.+)$")
			return ref and (ref:match("refs/heads/(.+)$") or ref)
		end
	end
	-- .git may be a pointer file (worktrees / submodules)
	local pf = io.open(base .. "/.git", "r")
	if pf then
		local content = pf:read("*a"); pf:close()
		local gitdir  = content and content:match("gitdir:%s*(.-)%s*$")
		if gitdir then
			if not gitdir:match("^/") then gitdir = base .. "/" .. gitdir end
			local f2 = io.open(gitdir .. "/HEAD", "r")
			if f2 then
				local head = f2:read("*l"); f2:close()
				if head then
					local ref = head:match("^ref:%s*(.+)$")
					return ref and (ref:match("refs/heads/(.+)$") or ref)
				end
			end
		end
	end
end

local function find_git_branch(cwd)
	local dir, max_up = cwd, 3
	for _ = 1, max_up do
		if not dir or dir == "" then break end
		local b = read_git_head(dir)
		if b then return b end
		local parent = dir:match("^(.*)/[^/]+$")
		if not parent or parent == dir then break end
		dir = parent
	end
end

local function git_branch_cached(cwd, pane)
	if not cwd or not pane then return end
	local pid = pane:pane_id()
	if git_last_cwd[pid] ~= cwd then
		git_last_cwd[pid], git_cache[pid] = cwd, nil
	end
	if git_cache[pid] ~= nil then return git_cache[pid] end
	local now = os.time()
	if git_last_checked[pid] and (now - git_last_checked[pid] < 2) then return end
	git_last_checked[pid] = now
	git_cache[pid] = find_git_branch(cwd)
	return git_cache[pid]
end

wezterm.on("update-status", function(window, _)
	local _, scheme    = get_current_scheme(window)
	local indicator    = window:active_workspace()
	local color        = scheme.ansi[6]

	if window:active_key_table() then indicator, color = window:active_key_table(), scheme.ansi[5] end
	if window:leader_is_active()  then indicator, color = "LDR",                   scheme.ansi[3] end

	local left   = wezterm.format({
		{ Foreground = { Color = color } },
		{ Text = "  " .. wezterm.nerdfonts.oct_table .. "  " .. indicator .. " |" },
	})
	local win_id = window:mux_window():window_id()
	if left_status_cache[win_id] ~= left then
		window:set_left_status(left)
		left_status_cache[win_id] = left
	end

	-- Keep zoom-state files current for neovim's fast zoom detection
	write_zoom_state(window)
end)

wezterm.on("update-right-status", function(window, pane)
	local _, scheme  = get_current_scheme(window)
	local cwd_info   = pane:get_current_working_dir()
	local cwd        = cwd_info and cwd_info.file_path or nil
	local segments   = {}

	local function push(text, color)
		if color then segments[#segments + 1] = { Foreground = { Color = color } } end
		segments[#segments + 1] = { Text = text }
	end

	if status_config.show_zoom and pane_is_zoomed(window) then
		push(wezterm.nerdfonts.fa_window_maximize .. " MAX | ", scheme.ansi[7])
	end
	if status_config.show_dir  then push(wezterm.nerdfonts.md_folder .. " " .. basename(cwd)) end
	if status_config.show_git  then
		local branch = git_branch_cached(cwd, pane)
		if branch then push(" | " .. wezterm.nerdfonts.pl_branch .. " " .. branch) end
	end
	if status_config.show_cmd  then push(" | " .. wezterm.nerdfonts.cod_terminal_bash .. " " .. basename(pane:get_foreground_process_name() or "")) end
	if status_config.show_datetime then push(" | " .. wezterm.strftime(status_config.datetime_fmt) .. " ") end

	local formatted = wezterm.format(segments)
	local win_id    = window:mux_window():window_id()
	if right_status_cache[win_id] ~= formatted then
		window:set_right_status(formatted)
		right_status_cache[win_id] = formatted
	end
end)

return config
