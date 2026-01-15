local wezterm = require("wezterm")
local act = wezterm.action
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

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

-- Dim inactive panes
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
-- load plugin
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
-- set path to zoxide
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"

config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
local builtin_schemes = wezterm.color.get_builtin_schemes()

-- shortcut_configuration
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
	-- Send C-a when pressing C-a twice
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "t", mods = "LEADER", action = act.EmitEvent("choose-color-scheme") },

	-- Workspace (similar to session in Tmux)
	{ key = "s", mods = "LEADER", action = act.ActivateKeyTable({ name = "session", one_shot = false }) },

	-- Tab (similar to window in Tmux)
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
	-- Key table for moving tabs around
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },
	-- Or shortcuts to move tab w/o move_tab table. SHIFT is for when caps lock is on
	--{ key = "{", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
	--{ key = "}", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },

	-- Pane
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
		mods = "LEADER | SHIFT",
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_tab()
		end),
	},
	-- We can make separate keybindings for resizing panes
	-- But Wezterm offers custom "mode" in the name of "KeyTable"
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
}

-- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
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
		{ key = "w", action = workspace_switcher.switch_workspace() },
		{ key = "s", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{ key = "[", action = act.SwitchWorkspaceRelative(1) },
		{ key = "]", action = act.SwitchWorkspaceRelative(-1) },
		{ key = "p", action = act.SwitchToWorkspace({ name = "main" }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- tab bar
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.status_update_interval = 5000
config.hide_tab_bar_if_only_one_tab = true

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

local function choose_color_scheme(window, pane)
	local choices = {}
	for name, _ in pairs(builtin_schemes) do
		table.insert(choices, { label = name, id = name })
	end
	table.sort(choices, function(a, b)
		return a.label:lower() < b.label:lower()
	end)

	window:perform_action(
		act.InputSelector({
			title = "Select Color Scheme",
			choices = choices,
			action = wezterm.action_callback(function(win, _, id, _)
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

local left_status_cache = {}
local right_status_cache = {}
wezterm.on("update-status", function(window, _)
	-- Resolve current scheme per-window (support dynamic changes)
	local overrides = window:get_config_overrides() or {}
	local scheme_name = overrides.color_scheme or config.color_scheme
	local scheme_colors = builtin_schemes[scheme_name]

	-- Workspace name
	local stat = window:active_workspace()
	local stat_color = scheme_colors.ansi[6]
	-- It's a little silly to have workspace name all the time
	-- Utilize this to display LDR or current key table name
	if window:active_key_table() then
		stat = window:active_key_table()
		stat_color = scheme_colors.ansi[5]
	end

	if window:leader_is_active() then
		stat = "LDR"
		stat_color = scheme_colors.ansi[3]
	end

	local left = wezterm.format({
		{ Foreground = { Color = stat_color } },
		{ Text = "  " },
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
		{ Text = " |" },
	})
	local win_id = window:mux_window():window_id()
	if left_status_cache[win_id] ~= left then
		window:set_left_status(left)
		left_status_cache[win_id] = left
	end
end)

local git_cache_by_pane = {}
local last_cwd_by_pane = {}
local last_git_check_by_pane = {}
local function read_git_branch_head(cwd_path)
	-- Try .git/HEAD first
	local head_path = cwd_path .. "/.git/HEAD"
	local f = io.open(head_path, "r")
	if not f then
		-- .git may be a file pointing to the real git dir (worktrees)
		local dotgit = io.open(cwd_path .. "/.git", "r")
		if dotgit then
			local content = dotgit:read("*a")
			dotgit:close()
			local gitdir = content and content:match("gitdir:%s*(.-)%s*$")
			if gitdir then
				head_path = gitdir .. "/HEAD"
				f = io.open(head_path, "r")
			end
		end
	end
	if not f then
		return nil
	end
	local head = f:read("*l")
	f:close()
	if not head then
		return nil
	end
	local ref = head:match("^ref:%s*(.+)$")
	if ref then
		local branch = ref:match("refs/heads/(.+)$") or ref
		return branch
	end
	-- Detached HEAD; skip for speed
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
	if git_cache_by_pane[pid] ~= nil then
		return git_cache_by_pane[pid]
	end
	-- Throttle initial read to avoid bursts during rapid cd
	local now = os.time()
	if last_git_check_by_pane[pid] and (now - last_git_check_by_pane[pid] < 2) then
		return nil
	end
	last_git_check_by_pane[pid] = now

	local branch = read_git_branch_head(cwd_path)
	git_cache_by_pane[pid] = branch
	return branch
end

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

wezterm.on("update-right-status", function(window, pane)
	local basename = function(s)
		return string.gsub(s, "(.*[/\\])(.*)", "%2")
	end
	-- Resolve current scheme per-window (support dynamic changes)
	local overrides = window:get_config_overrides() or {}
	local scheme_name = overrides.color_scheme or config.color_scheme
	local scheme_colors = builtin_schemes[scheme_name]

	local cwd_info = pane:get_current_working_dir()
	local cwd_path = cwd_info and cwd_info.file_path or nil
	local dir_name = cwd_path and basename(cwd_path) or ""

	local cmd = pane:get_foreground_process_name()
	cmd = cmd and basename(cmd) or ""

	local right = {}
	if pane_is_zoomed(window) then
		table.insert(right, { Foreground = { Color = scheme_colors.ansi[7] } })
		table.insert(right, { Text = wezterm.nerdfonts.fa_window_maximize .. " MAX" })
		table.insert(right, { Foreground = { Color = scheme_colors.ansi[7] } })
		table.insert(right, { Text = " | " })
	end
	table.insert(right, { Foreground = { Color = scheme_colors.ansi[7] } })
	table.insert(right, { Text = wezterm.nerdfonts.md_folder .. " " .. dir_name })
	local git_branch = get_git_branch_cached(cwd_path, pane)
	if git_branch then
		table.insert(right, { Text = " | " })
		table.insert(right, { Text = wezterm.nerdfonts.pl_branch .. " " .. git_branch })
	end
	table.insert(right, { Text = " | " })
	table.insert(right, { Text = wezterm.nerdfonts.cod_terminal_bash .. " " .. cmd })

	local date = wezterm.strftime("%Y-%m-%d %H:%M")
	table.insert(right, { Text = " | " })
	table.insert(right, { Text = date .. " " })

	local formatted = wezterm.format(right)
	local win_id = window:mux_window():window_id()
	if right_status_cache[win_id] ~= formatted then
		window:set_right_status(formatted)
		right_status_cache[win_id] = formatted
	end
end)

return config
