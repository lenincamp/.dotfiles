local M = {}

local function action(label, category, run)
  return { label = label, category = category, run = run }
end

local function command(name)
  return function()
    vim.cmd(name)
  end
end

local function feed(lhs)
  return function()
    local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
  end
end

local function picker()
  return require("picker")
end

function M.items()
  local p = picker()
  local sessions = require("config.editor.sessions")
  local task_runner = require("config.editor.task_runner")
  local ui = require("config.ui")

  return {
    action("Find files", "Files", function() p.find_files({ title = "Find Files" }) end),
    action("Find files (root)", "Files", function() p.find_files({ cwd = p.root(), title = "Find Files (root)" }) end),
    action("Find ignored files", "Files", function() p.find_files({ ignored = true, title = "Find Ignored Files" }) end),
    action("Find ignored files (root)", "Files", function() p.find_files({ cwd = p.root(), ignored = true, title = "Find Ignored Files (root)" }) end),
    action("Recent files", "Files", function() p.recent_files({ title = "Recent Files (cwd)" }) end),
    action("Recent files (global)", "Files", function() p.recent_files({ global = true, title = "Recent Files (global)" }) end),
    action("Git files", "Files", function() p.git_files({ title = "Git Files" }) end),
    action("New file", "Files", command("enew")),

    action("Grep literal (cwd)", "Search", function() p.grep({ regex = false, title = "Grep Literal (cwd)" }) end),
    action("Grep literal (root)", "Search", function() p.grep({ cwd = p.root(), regex = false, title = "Grep Literal (root)" }) end),
    action("Grep regex (cwd)", "Search", function() p.grep_picker({ title = "Grep Regex (cwd)" }) end),
    action("Grep regex (root)", "Search", function() p.grep_picker({ cwd = p.root(), title = "Grep Regex (root)" }) end),
    action("Grep ignored literal (cwd)", "Search", function() p.grep({ ignored = true, regex = false, title = "Grep Ignored Literal (cwd)" }) end),
    action("Grep ignored literal (root)", "Search", function() p.grep({ cwd = p.root(), ignored = true, regex = false, title = "Grep Ignored Literal (root)" }) end),
    action("Search word (cwd)", "Search", function() p.grep_word({}) end),
    action("Search word (root)", "Search", function() p.grep_word({ cwd = p.root() }) end),
    action("Commands", "Search", function() p.commands() end),
    action("Help", "Search", function() p.help() end),

    action("Toggle dark background", "UI", function() ui.toggle_dark_background() end),
    action("Toggle transparency", "UI", function() ui.toggle_transparent_background() end),
    action("Toggle diagnostics", "UI", function() ui.toggle_diagnostics() end),
    action("Toggle Zen", "UI", function() require("config.ui").toggle_zen_mode() end),
    action("Toggle render markdown", "UI", function() ui.toggle_render_markdown() end),
    action("Toggle statusline", "UI", function() ui.toggle_statusline() end),
    action("Toggle tabline", "UI", function() ui.toggle_tabline() end),
    action("Toggle winbar", "UI", function() ui.toggle_winbar() end),
    action("Toggle spelling", "UI", function() ui.toggle_option("spell", "Spelling") end),
    action("Toggle relative number", "UI", function() ui.toggle_window_option("relativenumber", "Relative Number") end),
    action("Toggle line number", "UI", function() ui.toggle_window_option("number", "Line Number") end),
    action("Toggle treesitter", "UI", function() ui.toggle_treesitter() end),
    action("Toggle dim", "UI", function() ui.toggle_dim() end),
    action("Toggle cmdline info", "UI", function() ui.toggle_cmdline_info() end),
    action("Toggle grep layout", "UI", function() ui.toggle_intellij_grep() end),
    action("Toggle treesitter context", "UI", function() ui.toggle_treesitter_context() end),
    action("Toggle SonarLint", "UI", function() require("modules.lsp.sonarlint").toggle() end),
    action("Toggle LSP in diff buffer", "UI", function() vim.cmd("DiffLspToggle") end),
    action("Reload Neovim config", "UI", function() ui.reload_config() end),
    action("Dashboard", "UI", function() require("picker.dashboard").open() end),

    action("Save session", "Session", function() sessions.save() end),
    action("Load session (cwd)", "Session", function() sessions.load_cwd() end),
    action("Load last session", "Session", function() sessions.load_last() end),
    action("Select session", "Session", function() sessions.select() end),

    action("Lazygit (root)", "Git", function() p.lazygit(p.root()) end),
    action("Git log (root)", "Git", function() p.git_log(p.root()) end),
    action("Git file history", "Git", function() p.git_file_history() end),
    action("Git browse", "Git", function() p.git_browse(false) end),

    action("Run nearest test", "Test", function() require("config.test").run_nearest() end),
    action("Run file test", "Test", function() require("config.test").run_file() end),
    action("Debug test", "Test", function() require("config.test").run_debug() end),
    action("Run last test", "Test", function() require("config.test").run_last() end),
    action("Toggle test watch", "Test", function() require("config.test").toggle_watch() end),
    action("Task runner", "Task", function() task_runner.select() end),

    action("DAP continue", "Debug", feed("<leader>dc")),
    action("DAP toggle breakpoint", "Debug", feed("<leader>db")),
    action("DAP toggle view", "Debug", feed("<leader>du")),

    action("Avante ask", "AI", feed("<leader>aa")),
    action("Avante provider", "AI", feed("<leader>aP")),
    action("Minuet predict", "AI", feed("<leader>amp")),

    action("Dadbod UI", "Database", feed("<leader>Du")),
    action("MyBatis Java to mapper statement", "MyBatis", feed("<leader>mx")),

    action("Open quickfix", "Lists", command("copen")),
    action("Open location list", "Lists", command("lopen")),
  }
end

function M.select()
  require("picker").select_items(M.items(), {
    prompt = "Command Center",
    scope = "global",
    search_threshold = 0,
    max_results = 12,
    input_mode = true,
    format_item = function(item)
      return string.format("%-10s  %s", item.category, item.label)
    end,
  }, function(item)
    if item and type(item.run) == "function" then
      item.run()
    end
  end)
end

vim.api.nvim_create_user_command("CommandCenter", M.select, { desc = "Open native command center" })

return M
