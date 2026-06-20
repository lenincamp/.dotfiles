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

function M.items()
  local search = require("modules.editor.search")
  local sessions = require("modules.editor.sessions")
  local ui = require("modules.ui.toggles")
  local editor = require("modules.editor")

  return {
    action("Find files", "Files", function() search.find_files({ title = "Find Files" }) end),
    action("Find files (root)", "Files", function() search.find_files({ cwd = search.root(), title = "Find Files (root)" }) end),
    action("Find ignored files", "Files", function() search.find_files({ ignored = true, title = "Find Ignored Files" }) end),
    action("Find ignored files (root)", "Files", function() search.find_files({ cwd = search.root(), ignored = true, title = "Find Ignored Files (root)" }) end),
    action("Recent files", "Files", function() search.recent_files({ title = "Recent Files" }) end),
    action("Recent files (cwd)", "Files", function() search.recent_files({ cwd = vim.fn.getcwd(), title = "Recent Files (cwd)" }) end),
    action("Git files", "Files", function() search.git_files({ title = "Git Files" }) end),
    action("New file", "Files", command("enew")),

    action("Grep literal (root)", "Search", function() search.grep({ cwd = search.root(), regex = false, title = "Grep Literal (root)" }) end),
    action("Grep regex (root)", "Search", function() search.grep({ cwd = search.root(), regex = true, title = "Grep Regex (root)" }) end),
    action("Grep ignored literal", "Search", function() search.grep({ ignored = true, regex = false, title = "Grep Ignored Literal" }) end),
    action("Grep ignored literal (root)", "Search", function() search.grep({ cwd = search.root(), ignored = true, regex = false, title = "Grep Ignored Literal (root)" }) end),
    action("Search word (root)", "Search", function() search.grep_word({ cwd = search.root() }) end),
    action("Keymaps", "Search", function() require("modules.editor.keymap_docs").select() end),
    action("Commands", "Search", function() search.commands() end),
    action("Help", "Search", function() search.help() end),

    action("Colorscheme", "UI", function() require("modules.theme.colorschemes").select() end),
    action("Workflow mode", "UI", function() require("modules.ui.workflow_modes").select() end),
    action("Toggle dark background", "UI", function() ui.toggle_dark_background() end),
    action("Toggle transparency", "UI", function() ui.toggle_transparent_background() end),
    action("Toggle diagnostics", "UI", function() ui.toggle_diagnostics() end),
    action("Toggle Zen", "UI", function() editor.toggle_zen_mode() end),
    action("Toggle render markdown", "UI", function() ui.toggle_render_markdown() end),
    action("Dashboard", "UI", function() require("modules.ui.dashboard").open() end),

    action("Save session", "Session", function() sessions.save() end),
    action("Load session (cwd)", "Session", function() sessions.load_cwd() end),
    action("Load last session", "Session", function() sessions.load_last() end),
    action("Select session", "Session", function() sessions.select() end),

    action("Lazygit (root)", "Git", function() search.lazygit(search.root()) end),
    action("Git log (root)", "Git", function() search.git_log(search.root()) end),
    action("Git file history", "Git", function() search.git_file_history() end),
    action("Git browse", "Git", function() search.git_browse(false) end),

    action("Run nearest test", "Test", feed("<leader>tn")),
    action("Run file test", "Test", feed("<leader>tf")),
    action("Run last test", "Test", feed("<leader>tl")),
    action("Task runner", "Task", function() require("modules.editor.task_runner").select() end),

    action("DAP continue", "Debug", feed("<leader>dc")),
    action("DAP toggle breakpoint", "Debug", feed("<leader>db")),
    action("DAP toggle view", "Debug", feed("<leader>du")),

    action("Avante ask", "AI", feed("<leader>aa")),
    action("Avante provider", "AI", feed("<leader>aP")),
    action("Minuet predict", "AI", feed("<leader>amp")),

    action("Dadbod UI", "Database", feed("<leader>Du")),
    action("MyBatis Java to mapper statement", "MyBatis", feed("<leader>mx")),

    action("Quickfix cockpit", "Lists", function() require("modules.editor.quickfix_cockpit").select() end),
    action("Open quickfix", "Lists", command("copen")),
    action("Open location list", "Lists", command("lopen")),
  }
end

function M.select()
  require("modules.editor.picker").select_items(M.items(), {
    prompt = "Command Center",
    scope = "global",
    search_threshold = 0,
    max_results = 12,
    format_item = function(item)
      return string.format("%-10s  %s", item.category, item.label)
    end,
  }, function(item)
    if item and type(item.run) == "function" then
      item.run()
    end
  end)
end

function M.setup()
  if M._setup_done then
    return
  end
  M._setup_done = true
  vim.api.nvim_create_user_command("CommandCenter", M.select, { desc = "Open native command center" })
end

return M
