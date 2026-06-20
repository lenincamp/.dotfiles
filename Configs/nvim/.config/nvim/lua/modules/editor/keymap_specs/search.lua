local M = {}

local function search_module()
  return require("modules.editor.search")
end

local function editor_module()
  return require("modules.editor")
end

function M.specs()
  return {
    {
      mode = "n",
      lhs = "<leader>E",
      desc = "File Explorer",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.open_explorer(native.root(), vim.api.nvim_buf_get_name(0))
      end,
    },
    {
      mode = "n",
      lhs = "<leader>e",
      desc = "File Explorer (cwd)",
      group = "Files/Terminal",
      action = function()
        search_module().open_explorer(nil, vim.api.nvim_buf_get_name(0))
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fF",
      desc = "Find Files (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), title = "Find Files (root)", input_mode = true, preview = false })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sF",
      desc = "Search Files (root)",
      group = "Search",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), title = "Search Files (root)", input_mode = true, preview = false })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fc",
      desc = "Config Files",
      group = "Files/Terminal",
      action = function()
        search_module().find_files({ cwd = vim.fn.stdpath("config"), title = "Config Files" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>ff",
      desc = "Find Files (cwd)",
      group = "Files/Terminal",
      action = function()
        search_module().find_files({ title = "Find Files (cwd)", input_mode = true, preview = false })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sf",
      desc = "Search Files (cwd)",
      group = "Search",
      action = function()
        search_module().find_files({ title = "Search Files (cwd)", input_mode = true, preview = false })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fi",
      desc = "Find Ignored Files (cwd)",
      group = "Files/Terminal",
      action = function()
        search_module().find_files({ ignored = true, title = "Find Ignored Files (cwd)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fI",
      desc = "Find Ignored Files (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), ignored = true, title = "Find Ignored Files (root)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fg",
      desc = "Find Git Files",
      group = "Files/Terminal",
      action = function()
        search_module().git_files({ title = "Find Git Files" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fR",
      desc = "Recent Files (cwd)",
      group = "Files/Terminal",
      action = function()
        search_module().recent_files({ title = "Recent Files (cwd)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fn",
      desc = "New File",
      group = "Files/Terminal",
      rhs = "<cmd>enew<cr>",
    },
    {
      mode = "n",
      lhs = "<leader>fJ",
      desc = "Find Java Files (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), glob = { "*.java" }, title = "Java Files" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fj",
      desc = "Find JavaScript/TypeScript Files (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), glob = { "*.js", "*.ts" }, title = "JavaScript/TypeScript Files" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fx",
      desc = "Find React Files (JSX/TSX) (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.find_files({ cwd = native.root(), glob = { "*.jsx", "*.tsx" }, title = "React Components" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>ft",
      desc = "Terminal (cwd)",
      group = "Files/Terminal",
      action = function()
        search_module().open_terminal(vim.fn.getcwd())
      end,
    },
    {
      mode = "n",
      lhs = "<leader>fT",
      desc = "Terminal (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.open_terminal(native.root())
      end,
    },
    {
      mode = { "n", "t" },
      lhs = "<C-/>",
      desc = "Terminal (root)",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.open_terminal(native.root())
      end,
    },
    {
      mode = { "n", "t" },
      lhs = "<C-_>",
      desc = "which_key_ignore",
      group = "Files/Terminal",
      action = function()
        local native = search_module()
        native.open_terminal(native.root())
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sb",
      desc = "Search Buffers",
      group = "Search",
      action = function() search_module().buffers() end,
    },
    {
      mode = { "n", "i", "x" },
      lhs = "<leader>sy",
      desc = "Registers / Clipboard",
      group = "Search",
      action = function() search_module().registers() end,
    },
    {
      mode = "n",
      lhs = "<leader>sc",
      desc = "Command History",
      group = "Search",
      action = function() search_module().command_history() end,
    },
    {
      mode = "n",
      lhs = "<leader>sC",
      desc = "Commands",
      group = "Search",
      action = function() search_module().commands() end,
    },
    {
      mode = "n",
      lhs = "<leader>sd",
      desc = "Document Diagnostics",
      group = "Search",
      action = function() search_module().diagnostics({ buffer = true }) end,
    },
    {
      mode = "n",
      lhs = "<leader>sD",
      desc = "Workspace Diagnostics",
      group = "Search",
      action = function() search_module().diagnostics() end,
    },
    {
      mode = "n",
      lhs = "<leader>sG",
      desc = "Grep Regex (root)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep_picker({ cwd = native.root(), title = "Grep Regex (root)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sg",
      desc = "Grep Regex (cwd)",
      group = "Search",
      action = function()
        search_module().grep_picker({ title = "Grep Regex (cwd)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>s/",
      desc = "Grep Regex (root)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep({ cwd = native.root(), regex = true, title = "Grep Regex (root)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>si",
      desc = "Grep Ignored Literal (cwd)",
      group = "Search",
      action = function()
        search_module().grep({ ignored = true, regex = false, title = "Grep Ignored Literal (cwd)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sI",
      desc = "Grep Ignored Literal (root)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep({ cwd = native.root(), ignored = true, regex = false, title = "Grep Ignored Literal (root)" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sj",
      desc = "Search JS/TS text (cwd)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep({ cwd = native.root(), regex = false, glob = { "*.js", "*.ts" }, title = "JS/TS Text" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sx",
      desc = "Search JSX/TSX text (cwd)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep({ cwd = native.root(), regex = false, glob = { "*.jsx", "*.tsx" }, title = "JSX/TSX Text" })
      end,
    },
    {
      mode = "n",
      lhs = "<leader>sJ",
      desc = "Search Java text (cwd)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep({ cwd = native.root(), regex = false, glob = { "*.java" }, title = "Java Text" })
      end,
    },
    { mode = "n", lhs = "<leader>sh", desc = "Help", group = "Search", action = function() search_module().help() end },
    { mode = "n", lhs = "<leader>sk", desc = "Keymaps", group = "Search", action = function() search_module().keymaps() end },
    { mode = "n", lhs = "<leader>sl", desc = "Location List", group = "Search", action = function() search_module().loclist() end },
    { mode = "n", lhs = "<leader>sm", desc = "Marks", group = "Search", action = function() search_module().marks() end },
    { mode = "n", lhs = "<leader>sn", desc = "Notifications", group = "Search", action = function() search_module().notifications() end },
    { mode = "n", lhs = "<leader>sq", desc = "Quickfix List", group = "Search", action = function() search_module().qflist() end },
    { mode = "n", lhs = "<leader>sr", desc = "Resume Last Search", group = "Search", action = function() require("modules.editor.picker").resume() end },
    { mode = "n", lhs = "<leader>su", desc = "Undo History", group = "Search", action = function() search_module().undo_history() end },
    {
      mode = { "n", "x" },
      lhs = "<leader>sW",
      desc = "Search Word (root)",
      group = "Search",
      action = function()
        local native = search_module()
        native.grep_word({ cwd = native.root() })
      end,
    },
    { mode = { "n", "x" }, lhs = "<leader>sw", desc = "Search Word (cwd)", group = "Search", action = function() search_module().grep_word({}) end },
    { mode = "n", lhs = "<leader>bb", desc = "Switch to Other Buffer", group = "Buffers", rhs = "<cmd>e #<cr>" },
    { mode = "n", lhs = "<leader>bD", desc = "Delete Buffer and Window", group = "Buffers", rhs = "<cmd>bd<cr>" },
    { mode = "n", lhs = "<leader>bd", desc = "Delete Buffer", group = "Buffers", action = function() search_module().delete_buffer() end },
    { mode = "n", lhs = "<leader>bo", desc = "Delete Other Buffers", group = "Buffers", action = function() search_module().delete_other_buffers() end },
    {
      mode = "n",
      lhs = "<leader>gG",
      desc = "Lazygit (root)",
      group = "Git",
      condition = function() return vim.fn.executable("lazygit") == 1 end,
      action = function()
        local native = search_module()
        native.lazygit(native.root())
      end,
    },
    {
      mode = "n",
      lhs = "<leader>gg",
      desc = "Lazygit (cwd)",
      group = "Git",
      condition = function() return vim.fn.executable("lazygit") == 1 end,
      action = function() search_module().lazygit(vim.fn.getcwd()) end,
    },
    { mode = "n", lhs = "<leader>gl", desc = "Git Log (cwd)", group = "Git", action = function() search_module().git_log(vim.fn.getcwd()) end },
    { mode = "n", lhs = "<leader>gb", desc = "Git Blame Line", group = "Git", action = function() search_module().git_blame_line() end },
    { mode = "n", lhs = "<leader>gC", desc = "Git Compare (contextual: file vimdiff / repo compare-load)", group = "Git", action = function() editor_module().git_compare_load_prompt() end },
    { mode = "n", lhs = "<leader>gf", desc = "Git File History", group = "Git", action = function() search_module().git_file_history() end },
    { mode = "n", lhs = "<leader>gL", desc = "Git Log (root)", group = "Git", action = function() local native = search_module(); native.git_log(native.root()) end },
    { mode = { "n", "x" }, lhs = "<leader>gB", desc = "Git Browse (open)", group = "Git", action = function() search_module().git_browse(false) end },
    { mode = { "n", "x" }, lhs = "<leader>gY", desc = "Git Browse (copy URL)", group = "Git", action = function() search_module().git_browse(true) end },
  }
end

return M
