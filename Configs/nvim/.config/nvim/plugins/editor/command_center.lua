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

local function sq()
  return require("modules.editor.search_qf")
end

local function gn()
  return require("modules.git.native")
end

function M.items()
  return {
    action("Find files (cwd)", "Files", function() vim.cmd("find<space>") end),
    action("Find files (root)", "Files", function() sq().find_files_root() end),
    action("Find git files", "Files", function() sq().git_files() end),
    action("Recent files", "Files", function() require("modules.editor.file_actions").quickfix_oldfiles_cwd() end),
    action("New file", "Files", command("enew")),

    action("Grep (cwd)", "Search", function() sq().grep_cwd() end),
    action("Grep (root)", "Search", function() sq().grep_root() end),
    action("Grep ignored (cwd)", "Search", function() sq().grep_ignored_cwd() end),
    action("Grep ignored (root)", "Search", function() sq().grep_ignored_root() end),
    action("Search word (cwd)", "Search", function() sq().grep_word_cwd() end),
    action("Search word (root)", "Search", function() sq().grep_word_root() end),
    action("Search buffer", "Search", function() sq().grep_buffer() end),
    action("Commands", "Search", function() sq().commands() end),
    action("Help", "Search", function() sq().help() end),

    action("Toggle dark background", "UI", function() require("config.ui").toggle_dark_background() end),
    action("Toggle transparency", "UI", function() require("config.ui").toggle_transparent_background() end),
    action("Toggle diagnostics", "UI", function() require("config.ui").toggle_diagnostics() end),
    action("Toggle Zen", "UI", function() require("config.ui").toggle_zen_mode() end),
    action("Toggle render markdown", "UI", function() require("config.ui").toggle_render_markdown() end),
    action("Toggle statusline", "UI", function() require("config.ui").toggle_statusline() end),
    action("Toggle tabline", "UI", function() require("config.ui").toggle_tabline() end),
    action("Toggle winbar", "UI", function() require("config.ui").toggle_winbar() end),
    action("Toggle spelling", "UI", function() require("config.ui").toggle_option("spell", "Spelling") end),
    action("Toggle relative number", "UI", function() require("config.ui").toggle_window_option("relativenumber", "Relative Number") end),
    action("Toggle line number", "UI", function() require("config.ui").toggle_window_option("number", "Line Number") end),
    action("Toggle treesitter", "UI", function() require("config.ui").toggle_treesitter() end),
    action("Toggle dim", "UI", function() require("config.ui").toggle_dim() end),
    action("Toggle cmdline info", "UI", function() require("config.ui").toggle_cmdline_info() end),
    action("Toggle grep layout", "UI", function() require("config.ui").toggle_intellij_grep() end),
    action("Toggle treesitter context", "UI", function() require("config.ui").toggle_treesitter_context() end),
    action("Toggle SonarLint", "UI", function() require("modules.lsp.sonarlint").toggle() end),
    action("Toggle LSP in diff buffer", "UI", function() vim.cmd("DiffLspToggle") end),
    action("Reload Neovim config", "UI", function() require("config.ui").reload_config() end),

    action("Save session", "Session", function() require("config.editor.sessions").save() end),
    action("Load session (cwd)", "Session", function() require("config.editor.sessions").load_cwd() end),
    action("Load last session", "Session", function() require("config.editor.sessions").load_last() end),
    action("Select session", "Session", function() require("config.editor.sessions").select() end),

    action("Lazygit (root)", "Git", function() gn().lazygit(gn().root) end),
    action("Git log (cwd)", "Git", function() gn().git_log_cwd() end),
    action("Git log (root)", "Git", function() gn().git_log_root() end),
    action("Git file history", "Git", function() gn().git_file_history() end),
    action("Git browse", "Git", function() gn().git_browse(false) end),

    action("Run nearest test", "Test", function() require("config.test").run_nearest() end),
    action("Run file test", "Test", function() require("config.test").run_file() end),
    action("Debug test", "Test", function() require("config.test").run_debug() end),
    action("Run last test", "Test", function() require("config.test").run_last() end),
    action("Toggle test watch", "Test", function() require("config.test").toggle_watch() end),
    action("Task runner", "Task", function() require("config.editor.task_runner").select() end),

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
  local items = M.items()
  vim.ui.select(items, {
    prompt = "Command Center",
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
