local wezterm = require("wezterm")
local act = wezterm.action

-- Build config object
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- ---------------------
-- Core appearance
-- ---------------------
config.font = wezterm.font_with_fallback({
	{ family = "0xProto", scale = 1.30 },
	{ family = "Maple Mono NF", scale = 1.30 },
})
config.harfbuzz_features = { "zero", "ss01", "cv05" }
config.line_height = 1.35

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 24
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"
config.default_cursor_style = "BlinkingBlock"

config.inactive_pane_hsb = {
	saturation = 0.95,
	brightness = 0.8,
}
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

-- ---------------------
-- Plugins (safe require)
-- ---------------------
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

-- ---------------------
-- Schemes
-- ---------------------
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
local builtin_schemes = wezterm.color.get_builtin_schemes()

local function get_current_scheme(window)
	local overrides = window:get_config_overrides() or {}
	local scheme_name = overrides.color_scheme or config.color_scheme
	return scheme_name, builtin_schemes[scheme_name]
end

local function set_window_color_scheme(window, scheme_name)
	local overrides = window:get_config_overrides() or {}
	overrides.color_scheme = scheme_name

	local s = builtin_schemes[scheme_name]
	if s then
		overrides.colors = overrides.colors or {}
		overrides.colors.tab_bar = {
			background = s.background,
			active_tab = {
				bg_color = s.ansi[5],
				fg_color = s.background,
				intensity = "Bold",
			},
			inactive_tab = {
				bg_color = s.background,
				fg_color = s.foreground,
			},
			inactive_tab_hover = {
				bg_color = s.ansi[1],
				fg_color = s.foreground,
				italic = true,
			},
			new_tab = {
				bg_color = s.background,
				fg_color = s.ansi[2],
			},
			new_tab_hover = {
				bg_color = s.ansi[4],
				fg_color = s.background,
				intensity = "Bold",
			},
		}
	end

	window:set_config_overrides(overrides)
end

-- Precompute color scheme choices once
local scheme_choices = (function()
	local choices = {}
	for name, _ in pairs(builtin_schemes) do
		table.insert(choices, { label = name, id = name })
	end
	table.sort(choices, function(a, b)
		return a.label:lower() < b.label:lower()
	end)
	return choices
end)()

local function choose_color_scheme(window, pane)
	window:perform_action(
		act.InputSelector({
			title = "Select Color Scheme",
			choices = scheme_choices,
			action = wezterm.action_callback(function(win, _, id)
				if id then
					set_window_color_scheme(win, id)
				end
			end),
		}),
		pane
	)
end

wezterm.on("choose-color-scheme", function(window, pane)
	choose_color_scheme(window, pane)
end)

-- ---------------------
-- Keybindings
-- ---------------------
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

config.keys = {
	-- Send C-a when pressing C-a twice
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Utility
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "t", mods = "LEADER", action = act.EmitEvent("choose-color-scheme") },

	-- Workspace (session)
	{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "session", one_shot = false }) },

	-- Tabs
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Move tab mode
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Panes
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	{ key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{
		key = "!",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_tab()
		end),
	},

	-- Resize mode
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

-- Quick tab index selection
for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end

config.key_tables = {
	resize_pane = {
		{ key = "<", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "-", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "+", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = ">", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	session = {
		{ key = "w", action = workspace_switch_action() },
		{ key = "s", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{ key = "[", action = act.SwitchWorkspaceRelative(1) },
		{ key = "]", action = act.SwitchWorkspaceRelative(-1) },
		{ key = "p", action = act.SwitchToWorkspace({ name = "main" }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- ---------------------
-- Tab bar
-- ---------------------
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.status_update_interval = 5000
config.hide_tab_bar_if_only_one_tab = true

-- ---------------------
-- Status helpers
-- ---------------------
local function basename(path)
	if not path or path == "" then
		return ""
	end
	return path:match("([^/\\]+)$") or path
end

local left_status_cache = {}
local right_status_cache = {}

-- Zoom detection
local function pane_is_zoomed(window)
	local tab = window:mux_window():active_tab()
	if not tab then
		return false
	end
	for _, pane_info in ipairs(tab:panes_with_info()) do
		if pane_info.is_active and pane_info.is_zoomed then
			return true
		end
	end
	return false
end

-- ---------------------
-- Git branch detection (cached per pane)
-- ---------------------
local git_cache_by_pane = {}
local last_cwd_by_pane = {}
local last_git_check_by_pane = {}

local function read_git_branch_head(base)
	-- Try .git/HEAD
	local f = io.open(base .. "/.git/HEAD", "r")
	if f then
		local head = f:read("*l")
		f:close()
		if head then
			local ref = head:match("^ref:%s*(.+)$")
			if ref then
				return ref:match("refs/heads/(.+)$") or ref
			end
			-- Detached HEAD -> skip for speed
			return nil
		end
	end

	-- .git may be a file pointing to the real git dir (worktrees/submodules)
	local dotgit = io.open(base .. "/.git", "r")
	if dotgit then
		local content = dotgit:read("*a")
		dotgit:close()
		local gitdir = content and content:match("gitdir:%s*(.-)%s*$")
		if gitdir then
			if not gitdir:match("^/") then
				gitdir = base .. "/" .. gitdir
			end
			local f2 = io.open(gitdir .. "/HEAD", "r")
			if f2 then
				local head = f2:read("*l")
				f2:close()
				if head then
					local ref = head:match("^ref:%s*(.+)$")
					if ref then
						return ref:match("refs/heads/(.+)$") or ref
					end
					return nil
				end
			end
		end
	end

	return nil
end

local function find_git_branch(cwd_path)
	local current = cwd_path
	local max_up = 3
	for _ = 1, max_up do
		if not current or current == "" then
			return nil
		end
		local branch = read_git_branch_head(current)
		if branch then
			return branch
		end
		local parent = current:match("^(.*)/[^/]+$")
		if not parent or parent == current then
			break
		end
		current = parent
	end
	return nil
end

local function get_git_branch_cached(cwd_path, pane)
	if not cwd_path or not pane then
		return nil
	end
	local pid = pane:pane_id()

	if last_cwd_by_pane[pid] ~= cwd_path then
		last_cwd_by_pane[pid] = cwd_path
		git_cache_by_pane[pid] = nil
	end

	-- Return cached value if available
	if git_cache_by_pane[pid] ~= nil then
		return git_cache_by_pane[pid]
	end

	-- Throttle reads to avoid bursts during rapid cd
	local now = os.time()
	if last_git_check_by_pane[pid] and (now - last_git_check_by_pane[pid] < 2) then
		return nil
	end
	last_git_check_by_pane[pid] = now

	local branch = find_git_branch(cwd_path)
	git_cache_by_pane[pid] = branch
	return branch
end

-- ---------------------
-- Status line rendering
-- ---------------------
local status_config = {
	show_zoom = true,
	show_dir = true,
	show_git = false,
	show_cmd = true,
	show_datetime = true,
	datetime_fmt = "%Y-%m-%d %H:%M",
}

wezterm.on("update-status", function(window, _)
	local scheme_name, scheme = get_current_scheme(window)
	local indicator = window:active_workspace()
	local indicator_color = scheme.ansi[6]

	if window:active_key_table() then
		indicator = window:active_key_table()
		indicator_color = scheme.ansi[5]
	end
	if window:leader_is_active() then
		indicator = "LDR"
		indicator_color = scheme.ansi[3]
	end

	local left = wezterm.format({
		{ Foreground = { Color = indicator_color } },
		{ Text = "  " },
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. indicator },
		{ Text = " |" },
	})
	local win_id = window:mux_window():window_id()
	if left_status_cache[win_id] ~= left then
		window:set_left_status(left)
		left_status_cache[win_id] = left
	end
end)

wezterm.on("update-right-status", function(window, pane)
	local _, scheme = get_current_scheme(window)

	local cwd_info = pane:get_current_working_dir()
	local cwd_path = cwd_info and cwd_info.file_path or nil
	local dir_name = basename(cwd_path)

	local cmd = basename(pane:get_foreground_process_name() or "")

	local segments = {}

	if status_config.show_zoom and pane_is_zoomed(window) then
		table.insert(segments, { Foreground = { Color = scheme.ansi[7] } })
		table.insert(segments, { Text = wezterm.nerdfonts.fa_window_maximize .. " MAX" })
		table.insert(segments, { Foreground = { Color = scheme.ansi[7] } })
		table.insert(segments, { Text = " | " })
	end

	if status_config.show_dir then
		table.insert(segments, { Foreground = { Color = scheme.ansi[7] } })
		table.insert(segments, { Text = wezterm.nerdfonts.md_folder .. " " .. dir_name })
	end

	if status_config.show_git then
		local git_branch = get_git_branch_cached(cwd_path, pane)
		if git_branch then
			table.insert(segments, { Text = " | " })
			table.insert(segments, { Text = wezterm.nerdfonts.pl_branch .. " " .. git_branch })
		end
	end

	if status_config.show_cmd then
		table.insert(segments, { Text = " | " })
		table.insert(segments, { Text = wezterm.nerdfonts.cod_terminal_bash .. " " .. cmd })
	end

	if status_config.show_datetime then
		local date = wezterm.strftime(status_config.datetime_fmt)
		table.insert(segments, { Text = " | " })
		table.insert(segments, { Text = date .. " " })
	end

	local formatted = wezterm.format(segments)
	local win_id = window:mux_window():window_id()
	if right_status_cache[win_id] ~= formatted then
		window:set_right_status(formatted)
		right_status_cache[win_id] = formatted
	end
end)

return config
