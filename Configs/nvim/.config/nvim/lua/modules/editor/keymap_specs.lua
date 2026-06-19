local M = {}

local function search_module()
  return require("modules.editor.search")
end

local function editor_module()
  return require("modules.editor")
end

local function ui_module()
  return require("modules.ui.toggles")
end

local function zen_module()
  return require("modules.ui.zen")
end

local function split_nav_module()
  return require("modules.ui.split_nav")
end

local function lsp_lists_module()
  return require("modules.editor.lsp_lists")
end

local function lsp_buf_call(method, ...)
  local args = { ... }
  local unpack_args = unpack or table.unpack
  return function()
    local ok, lsp = pcall(function()
      return vim.lsp
    end)
    if not ok or type(lsp) ~= "table" or type(lsp.buf) ~= "table" then
      return
    end

    local fn = lsp.buf[method]
    if type(fn) ~= "function" then
      return
    end

    fn(unpack_args(args))
  end
end

local function peek(method)
  return function()
    require("modules.editor.peek").request("textDocument/" .. method)
  end
end

local motion_edit_specs = {
  { mode = { "n", "x" }, lhs = "j", desc = "Down", group = "Motion", rhs = "v:count == 0 ? 'gj' : 'j'", opts = { expr = true, silent = true } },
  { mode = { "n", "x" }, lhs = "k", desc = "Up", group = "Motion", rhs = "v:count == 0 ? 'gk' : 'k'", opts = { expr = true, silent = true } },
  { mode = "n", lhs = "L", desc = "End of line", group = "Motion", rhs = "$" },
  { mode = "n", lhs = "H", desc = "Start of line", group = "Motion", rhs = "^" },
  { mode = "n", lhs = "dw", desc = "Delete word backward", group = "Editing", rhs = "vb_d" },
  { mode = "n", lhs = "<C-i>", desc = "Jump forward", group = "Motion", rhs = "<C-I>", opts = { noremap = true } },
  { mode = "n", lhs = "z1", desc = "Fold level 1", group = "Folds/View", rhs = "<cmd>set foldlevel=1<CR>" },
  { mode = "n", lhs = "z2", desc = "Fold level 2", group = "Folds/View", rhs = "<cmd>set foldlevel=2<CR>" },
  { mode = "n", lhs = "z3", desc = "Fold level 3", group = "Folds/View", rhs = "<cmd>set foldlevel=3<CR>" },
  { mode = "n", lhs = "n", desc = "Next Search Result", group = "Search", rhs = "'Nn'[v:searchforward].'zv'", opts = { expr = true } },
  { mode = "x", lhs = "n", desc = "Next Search Result", group = "Search", rhs = "'Nn'[v:searchforward]", opts = { expr = true } },
  { mode = "o", lhs = "n", desc = "Next Search Result", group = "Search", rhs = "'Nn'[v:searchforward]", opts = { expr = true } },
  { mode = "n", lhs = "N", desc = "Prev Search Result", group = "Search", rhs = "'nN'[v:searchforward].'zv'", opts = { expr = true } },
  { mode = "x", lhs = "N", desc = "Prev Search Result", group = "Search", rhs = "'nN'[v:searchforward]", opts = { expr = true } },
  { mode = "o", lhs = "N", desc = "Prev Search Result", group = "Search", rhs = "'nN'[v:searchforward]", opts = { expr = true } },
  { mode = "n", lhs = "<C-d>", desc = "Scroll half-page down", group = "Motion", rhs = "<C-d>zz" },
  { mode = "n", lhs = "<C-u>", desc = "Scroll half-page up", group = "Motion", rhs = "<C-u>zz" },
  { mode = "n", lhs = "*", desc = "Search word forward (highlight on)", group = "Search", opts = { expr = true, silent = true }, action = function() return editor_module().enable_search_highlight_and_return("*") end },
  { mode = "n", lhs = "#", desc = "Search word backward (highlight on)", group = "Search", opts = { expr = true, silent = true }, action = function() return editor_module().enable_search_highlight_and_return("#") end },
  { mode = "n", lhs = "<A-j>", desc = "Move Line Down", group = "Editing", rhs = "<cmd>execute 'move .+' . v:count1<cr>==" },
  { mode = "n", lhs = "<A-k>", desc = "Move Line Up", group = "Editing", rhs = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==" },
  { mode = "i", lhs = "<A-j>", desc = "Move Line Down", group = "Editing", rhs = "<esc><cmd>m .+1<cr>==gi" },
  { mode = "i", lhs = "<A-k>", desc = "Move Line Up", group = "Editing", rhs = "<esc><cmd>m .-2<cr>==gi" },
  { mode = "v", lhs = "<A-j>", desc = "Move Selection Down", group = "Editing", rhs = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv" },
  { mode = "v", lhs = "<A-k>", desc = "Move Selection Up", group = "Editing", rhs = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv" },
  { mode = "v", lhs = "J", desc = "Move selection down", group = "Editing", rhs = "<cmd>m '>+1<CR>gv=gv" },
  { mode = "v", lhs = "K", desc = "Move selection up", group = "Editing", rhs = "<cmd>m '<-2<CR>gv=gv" },
  { mode = { "i", "x", "n", "s" }, lhs = "<C-s>", desc = "Save File", group = "Editing", rhs = "<cmd>w<cr><esc>" },
  { mode = "x", lhs = "<", desc = "Indent left", group = "Editing", rhs = "<gv" },
  { mode = "x", lhs = ">", desc = "Indent right", group = "Editing", rhs = ">gv" },
  { mode = "n", lhs = "<A-d>", desc = "Duplicate line", group = "Editing", action = function() editor_module().duplicate_line_or_selection() end },
  { mode = "i", lhs = "<A-d>", desc = "Duplicate line", group = "Editing", action = function() editor_module().duplicate_line_or_selection() end },
  { mode = "x", lhs = "<A-d>", desc = "Duplicate selection", group = "Editing", action = function() editor_module().duplicate_line_or_selection(true) end },
  { mode = "i", lhs = ",", group = "Editing", rhs = ",<c-g>u" },
  { mode = "i", lhs = ".", group = "Editing", rhs = ".<c-g>u" },
  { mode = "i", lhs = ";", group = "Editing", rhs = ";<c-g>u" },
  { mode = "i", lhs = "<Space>", desc = "Insert space immediately", group = "Editing", rhs = "<Space>", opts = { nowait = true } },
  { mode = "n", lhs = "gco", desc = "Add Comment Below", group = "Comment", rhs = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>" },
  { mode = "n", lhs = "gcO", desc = "Add Comment Above", group = "Comment", rhs = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>" },
}

local code_lsp_specs = {
  { mode = "n", lhs = "gpc", desc = "Peek: close all", group = "Quick Preview", action = function() require("modules.editor.peek").close_all() end },
  { mode = "n", lhs = "gpd", desc = "Peek Definition", group = "Quick Preview", action = peek("definition") },
  { mode = "n", lhs = "gpt", desc = "Peek Type Definition", group = "Quick Preview", action = peek("typeDefinition") },
  { mode = "n", lhs = "gpi", desc = "Peek Implementation", group = "Quick Preview", action = peek("implementation") },
  { mode = "n", lhs = "gpD", desc = "Peek Declaration", group = "Quick Preview", action = peek("declaration") },
  { mode = "n", lhs = "gpr", desc = "Peek References (picker)", group = "Quick Preview", action = function() require("modules.editor.peek").references() end },
  {
    mode = "n",
    lhs = "<leader>cd",
    desc = "Line Diagnostics",
    group = "Code",
    action = function()
      require("modules.lsp.diagnostics").open_float({ scope = "line" })
    end,
  },
  { mode = { "n", "x" }, lhs = "<leader>cf", desc = "Format", group = "Code", action = function() editor_module().format() end },
  { mode = "n", lhs = "<leader>ch", desc = "Call Hierarchy", group = "Code", action = function() editor_module().call_hierarchy() end },
  { mode = "n", lhs = "<leader>ci", desc = "Incoming Calls", group = "Code", action = function() editor_module().call_hierarchy_incoming() end },
  { mode = "n", lhs = "<leader>co", desc = "Outgoing Calls", group = "Code", action = function() editor_module().call_hierarchy_outgoing() end },
  { mode = "n", lhs = "gd", desc = "Go to Definition", group = "g-prefix/LSP", action = lsp_buf_call("definition") },
  { mode = "n", lhs = "gD", desc = "Go to Declaration", group = "g-prefix/LSP", action = lsp_buf_call("declaration") },
  { mode = "n", lhs = "grt", desc = "Go to Type Definition", group = "g-prefix/LSP", action = lsp_buf_call("type_definition") },
  { mode = "n", lhs = "gri", desc = "Go to Implementation", group = "g-prefix/LSP", action = lsp_buf_call("implementation") },
  { mode = { "n", "x" }, lhs = "gra", desc = "Code Action", group = "g-prefix/LSP", action = lsp_buf_call("code_action") },
  { mode = "n", lhs = "grn", desc = "Rename Symbol", group = "g-prefix/LSP", action = lsp_buf_call("rename") },
  { mode = "n", lhs = "grr", desc = "References", group = "g-prefix/LSP", action = function() lsp_lists_module().references() end },
  { mode = "n", lhs = "gO", desc = "Document Symbols", group = "g-prefix/LSP", action = function() lsp_lists_module().document_symbols() end },
  { mode = "n", lhs = "gW", desc = "Workspace Symbols", group = "g-prefix/LSP", action = function() lsp_lists_module().workspace_symbols() end },
  { mode = "n", lhs = "<leader>ss", desc = "LSP Symbols (doc)", group = "Search", action = function() lsp_lists_module().document_symbols() end },
  { mode = "n", lhs = "<leader>sS", desc = "LSP Symbols (workspace)", group = "Search", action = function() lsp_lists_module().workspace_symbols() end },
  { mode = "n", lhs = "K", desc = "Hover Documentation", group = "g-prefix/LSP", action = lsp_buf_call("hover") },
  { mode = "n", lhs = "gK", desc = "Signature Help", group = "g-prefix/LSP", action = lsp_buf_call("signature_help") },
  {
    mode = "n",
    lhs = "gV",
    desc = "Vsplit & goto definition",
    group = "g-prefix/LSP",
    opts = { silent = true },
    action = function()
      vim.cmd("vsplit")
      lsp_buf_call("definition")()
    end,
  },
  { mode = "n", lhs = "]]", desc = "Next Reference", group = "Bracket Navigation", action = function() editor_module().jump_word_reference(vim.v.count1) end },
  { mode = "n", lhs = "[[", desc = "Prev Reference", group = "Bracket Navigation", action = function() editor_module().jump_word_reference(-vim.v.count1) end },
  { mode = "i", lhs = "<C-k>", desc = "Signature Help", group = "g-prefix/LSP", action = lsp_buf_call("signature_help") },
  {
    mode = "n",
    lhs = "<leader>cm",
    desc = "Mason",
    group = "Code",
    action = function()
      require("modules.core.runtime").load_config("mason")
      vim.cmd("Mason")
    end,
  },
  { mode = "n", lhs = "<leader>K", desc = "Keywordprg", group = "Code", rhs = "<cmd>norm! K<cr>" },
  { mode = "n", lhs = "<leader>rs", desc = "Refactor (all actions)", group = "Refactor", action = lsp_buf_call("code_action") },
  {
    mode = "x",
    lhs = "<leader>rx",
    desc = "Extract Variable",
    group = "Refactor",
    action = lsp_buf_call("code_action", { context = { only = { "refactor.extract.variable" } }, apply = true }),
  },
  {
    mode = "x",
    lhs = "<leader>rf",
    desc = "Extract Function",
    group = "Refactor",
    action = lsp_buf_call("code_action", { context = { only = { "refactor.extract.function" } }, apply = true }),
  },
  {
    mode = "n",
    lhs = "<leader>ri",
    desc = "Inline Variable",
    group = "Refactor",
    action = lsp_buf_call("code_action", { context = { only = { "refactor.inline" } }, apply = true }),
  },
  {
    mode = "n",
    lhs = "<leader>ro",
    desc = "Organize Imports",
    group = "Refactor",
    action = lsp_buf_call("code_action", { context = { only = { "source.organizeImports" } }, apply = true }),
  },
  { mode = "n", lhs = "<leader>rr", desc = "Replace all occurrences", group = "Refactor", rhs = [[:%s/\V<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>]] },
  { mode = "v", lhs = "<leader>rr", desc = "Replace all occurrences", group = "Refactor", rhs = [["vy:%s/\V<C-r>=escape(@v, '/\')<CR>/<C-r>v/gI<Left><Left><Left>]] },
  { mode = "n", lhs = "<leader>cp", desc = "Copy path to clipboard", group = "Code", action = function() editor_module().copy_path() end },
  { mode = "n", lhs = "<leader>cN", desc = "Rename file", group = "Code", action = function() editor_module().rename_file() end },
  { mode = "n", lhs = "<leader>cB", desc = "Diff current buffer vs clipboard", group = "Code", action = function() editor_module().compare_with_clipboard() end },
}

local search_specs = {
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
      native.find_files({ cwd = native.root(), title = "Find Files (root)" })
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
      search_module().find_files({ title = "Find Files (cwd)" })
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
    desc = "Grep Literal (root)",
    group = "Search",
    action = function()
      local native = search_module()
      native.grep({ cwd = native.root(), regex = false, title = "Grep Literal (root)" })
    end,
  },
  {
    mode = "n",
    lhs = "<leader>sg",
    desc = "Grep Literal (cwd)",
    group = "Search",
    action = function()
      search_module().grep({ regex = false, title = "Grep Literal (cwd)" })
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

local global_specs = {
  { mode = "n", lhs = "<leader>us", desc = "Toggle statusline", group = "UI", action = function() ui_module().toggle_statusline() end },
  { mode = "n", lhs = "<leader>ut", desc = "Toggle tabline", group = "UI", action = function() ui_module().toggle_tabline() end },
  { mode = "n", lhs = "<leader>um", desc = "Cycle tabline mode", group = "UI", action = function() ui_module().cycle_tabline_mode() end },
  { mode = "n", lhs = "<leader>uW", desc = "Toggle winbar", group = "UI", action = function() ui_module().toggle_winbar() end },
  { mode = "n", lhs = "<leader>uo", desc = "Toggle spelling", group = "UI", action = function() ui_module().toggle_option("spell", "Spelling") end },
  { mode = "n", lhs = "<leader>uw", desc = "Toggle wrap", group = "UI", action = function() ui_module().toggle_option("wrap", "Wrap") end },
  { mode = "n", lhs = "<leader>uL", desc = "Toggle relative number", group = "UI", action = function() ui_module().toggle_window_option("relativenumber", "Relative Number") end },
  { mode = "n", lhs = "<leader>ul", desc = "Toggle line number", group = "UI", action = function() ui_module().toggle_window_option("number", "Line Number") end },
  { mode = "n", lhs = "<leader>ud", desc = "Toggle diagnostics", group = "UI", action = function() ui_module().toggle_diagnostics() end },
  { mode = "n", lhs = "<leader>uT", desc = "Toggle treesitter", group = "UI", action = function() ui_module().toggle_treesitter() end },
  { mode = "n", lhs = "<leader>uC", desc = "Select colorscheme", group = "UI", action = function() require("modules.theme.colorschemes").select() end },
  { mode = "n", lhs = "<leader>ub", desc = "Toggle dark background", group = "UI", action = function() ui_module().toggle_dark_background() end },
  { mode = "n", lhs = "<leader>uA", desc = "Toggle transparent background", group = "UI", action = function() ui_module().toggle_transparent_background() end },
  { mode = "n", lhs = "<leader>uD", desc = "Toggle dim", group = "UI", action = function() ui_module().toggle_dim() end },
  { mode = "n", lhs = "<leader>uZ", desc = "Toggle zoom", group = "UI", action = function() ui_module().toggle_zoom() end },
  { mode = "n", lhs = "<leader>wm", desc = "Toggle zoom", group = "Windows", action = function() ui_module().toggle_zoom() end },
  { mode = "n", lhs = "<leader>uh", desc = "Toggle inlay hints", group = "UI", action = function() ui_module().toggle_inlay_hints() end },
  { mode = "n", lhs = "<leader>uf", desc = "Toggle format on save (global)", group = "UI", action = function() ui_module().toggle_format_global() end },
  { mode = "n", lhs = "<leader>uF", desc = "Toggle format on save (buffer)", group = "UI", action = function() ui_module().toggle_format_buffer() end },
  { mode = "n", lhs = "<leader>ui", desc = "Toggle cmdline info", group = "UI", action = function() ui_module().toggle_cmdline_info() end },
  { mode = "n", lhs = "<leader>uV", desc = "Reload Neovim config", group = "UI", action = function() ui_module().reload_config() end },
  { mode = "n", lhs = "<leader>ug", desc = "Toggle grep layout", group = "UI", action = function() ui_module().toggle_intellij_grep() end },
  { mode = "n", lhs = "<leader>uX", desc = "Toggle treesitter context", group = "UI", action = function() ui_module().toggle_treesitter_context() end },
  { mode = "n", lhs = "<leader>uM", desc = "Toggle render markdown", group = "UI", action = function() ui_module().toggle_render_markdown() end },
  { mode = "n", lhs = "<leader>uS", desc = "Toggle SonarLint", group = "UI", action = function() require("modules.lsp.sonarlint").toggle() end },
  { mode = "n", lhs = "<leader>uP", desc = "Workflow mode", group = "UI", action = function() require("modules.ui.workflow_modes").select() end },
  { mode = "n", lhs = "<leader>uz", desc = "Toggle Zen Mode", group = "UI", opts = { nowait = true }, action = function() editor_module().toggle_zen_mode() end },
  { mode = "n", lhs = "<leader>uzz", desc = "Toggle Zen Mode", group = "UI", opts = { nowait = true }, action = function() editor_module().toggle_zen_mode() end },
  { mode = "n", lhs = "<leader>uzn", desc = "Cycle Zen Width (110/120/130)", group = "UI", action = function() editor_module().cycle_zen_width() end },
  { mode = "n", lhs = "<leader>np", desc = "No Neck Pain: toggle", group = "No Neck Pain", action = function() editor_module().toggle_zen_mode() end },
  { mode = "n", lhs = "<leader>n=", desc = "No Neck Pain: width up", group = "No Neck Pain", action = function() zen_module().adjust_zen_width(5) end },
  { mode = "n", lhs = "<leader>n-", desc = "No Neck Pain: width down", group = "No Neck Pain", action = function() zen_module().adjust_zen_width(-5) end },
  { mode = "n", lhs = "<leader>nql", desc = "No Neck Pain: toggle left side", group = "No Neck Pain", action = function() zen_module().toggle_side("left") end },
  { mode = "n", lhs = "<leader>nqr", desc = "No Neck Pain: toggle right side", group = "No Neck Pain", action = function() zen_module().toggle_side("right") end },
  { mode = "n", lhs = "<leader>ns", desc = "No Neck Pain: scratch pad", group = "No Neck Pain", action = function() zen_module().toggle_scratch_pad() end },
  { mode = "n", lhs = "<leader>nd", desc = "No Neck Pain: debug", group = "No Neck Pain", action = function() zen_module().toggle_debug() end },
  { mode = "n", lhs = "<leader>uR", desc = "Toggle diff profile (review/focused)", group = "UI", action = function() editor_module().toggle_diff_profile() end },
  { mode = "n", lhs = "<leader>uq", desc = "Toggle LSP in diff buffer", group = "UI", rhs = "<cmd>DiffLspToggle<cr>" },
  {
    mode = "n",
    lhs = "<leader>ur",
    desc = "Redraw / Clear search highlights / Diff Update",
    group = "UI",
    action = function()
      editor_module().clear_search_highlights()
      vim.cmd("diffupdate")
      vim.cmd("redraw!")
    end,
  },
  {
    mode = "n",
    lhs = "<Esc>",
    desc = "Clear search highlights",
    group = "Search",
    opts = { expr = true, silent = true },
    action = function()
      editor_module().clear_search_highlights()
      return "<Esc>"
    end,
  },
  { mode = "n", lhs = "<leader>qq", desc = "Quit All", group = "Quit", rhs = "<cmd>qa<cr>" },
  { mode = "n", lhs = "<leader>pH", desc = "Open Quickfix Playbook", group = "Project/Sessions", action = function() editor_module().open_quickfix_playbook() end },
  { mode = "n", lhs = "<leader>pT", desc = "Task Runner", group = "Project/Sessions", action = function() require("modules.editor.task_runner").select() end },
  { mode = "n", lhs = "<leader>ue", desc = "Toggle diff mode", group = "UI", action = function() editor_module().toggle_diff_mode() end },
  { mode = "i", lhs = "<C-]>", desc = "Line completion (close + semicolon + newline)", group = "Editing", action = function() editor_module().line_completion() end },
  { mode = "n", lhs = "<C-h>", desc = "Move to left window/tmux pane", group = "Windows", action = function() split_nav_module().move("h") end },
  { mode = "n", lhs = "<C-j>", desc = "Move to lower window/tmux pane", group = "Windows", action = function() split_nav_module().move("j") end },
  { mode = "n", lhs = "<C-k>", desc = "Move to upper window/tmux pane", group = "Windows", action = function() split_nav_module().move("k") end },
  { mode = "n", lhs = "<C-l>", desc = "Move to right window/tmux pane", group = "Windows", action = function() split_nav_module().move("l") end },
  { mode = "n", lhs = "<leader><space>", desc = "Command Center", group = "Command Center", action = function() require("modules.editor.command_center").select() end },
  { mode = "n", lhs = "<leader>xC", desc = "Quickfix Cockpit", group = "Lists", action = function() require("modules.editor.quickfix_cockpit").select() end },
  { mode = "n", lhs = "<leader>?", desc = "Keymaps", group = "Search", action = function() require("modules.editor.keymap_docs").select() end },
}

local window_list_tab_specs = {
  { mode = "n", lhs = "<leader>w", desc = "Windows", group = "Windows", rhs = "<C-W>", opts = { remap = true } },
  { mode = "n", lhs = "<leader>ww", desc = "Other Window", group = "Windows", rhs = "<C-W>w", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wd", desc = "Delete Window", group = "Windows", rhs = "<C-W>c", opts = { remap = true } },
  { mode = "n", lhs = "<leader>ws", desc = "Split Below", group = "Windows", rhs = "<C-W>s", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wv", desc = "Split Right", group = "Windows", rhs = "<C-W>v", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wh", desc = "Go to Left Window", group = "Windows", rhs = "<C-W>h", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wj", desc = "Go to Below Window", group = "Windows", rhs = "<C-W>j", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wk", desc = "Go to Above Window", group = "Windows", rhs = "<C-W>k", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wl", desc = "Go to Right Window", group = "Windows", rhs = "<C-W>l", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wo", desc = "Close Other Windows", group = "Windows", rhs = "<C-W>o", opts = { remap = true } },
  { mode = "n", lhs = "<leader>w=", desc = "Equal Window Sizes", group = "Windows", rhs = "<C-W>=", opts = { remap = true } },
  { mode = "n", lhs = "<leader>wT", desc = "Window to Tab", group = "Windows", rhs = "<C-W>T", opts = { remap = true } },
  { mode = "n", lhs = "<leader>-", desc = "Split Below", group = "Windows", rhs = "<C-W>s", opts = { remap = true } },
  { mode = "n", lhs = "<leader>|", desc = "Split Right", group = "Windows", rhs = "<C-W>v", opts = { remap = true } },
  { mode = "n", lhs = "<M-Up>", desc = "Increase Window Height", group = "Windows", rhs = "<cmd>resize +2<cr>" },
  { mode = "n", lhs = "<M-Down>", desc = "Decrease Window Height", group = "Windows", rhs = "<cmd>resize -2<cr>" },
  { mode = "n", lhs = "<M-Left>", desc = "Decrease Window Width", group = "Windows", rhs = "<cmd>vertical resize -2<cr>" },
  { mode = "n", lhs = "<M-Right>", desc = "Increase Window Width", group = "Windows", rhs = "<cmd>vertical resize +2<cr>" },
  {
    mode = "n",
    lhs = "<leader>xl",
    desc = "Location List",
    group = "Lists",
    action = function()
      local success, err = pcall(function()
        if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
          vim.cmd.lclose()
        else
          vim.cmd.lopen()
        end
      end)
      if not success then vim.notify(tostring(err), vim.log.levels.ERROR) end
    end,
  },
  {
    mode = "n",
    lhs = "<leader>xq",
    desc = "Quickfix List",
    group = "Lists",
    action = function()
      local success, err = pcall(function()
        if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
          vim.cmd.cclose()
        else
          vim.cmd.copen()
        end
      end)
      if not success then vim.notify(tostring(err), vim.log.levels.ERROR) end
    end,
  },
  { mode = "n", lhs = "<leader><tab>l", desc = "Last Tab", group = "Tabs", rhs = "<cmd>tablast<cr>" },
  { mode = "n", lhs = "<leader><tab>o", desc = "Close Other Tabs", group = "Tabs", rhs = "<cmd>tabonly<cr>" },
  { mode = "n", lhs = "<leader><tab>f", desc = "First Tab", group = "Tabs", rhs = "<cmd>tabfirst<cr>" },
  { mode = "n", lhs = "<leader><tab><tab>", desc = "New Tab", group = "Tabs", rhs = "<cmd>tabnew<cr>" },
  { mode = "n", lhs = "<leader><tab>]", desc = "Next Tab", group = "Tabs", rhs = "<cmd>tabnext<cr>" },
  { mode = "n", lhs = "<leader><tab>d", desc = "Close Tab", group = "Tabs", rhs = "<cmd>tabclose<cr>" },
  { mode = "n", lhs = "<leader><tab>[", desc = "Prev Tab", group = "Tabs", rhs = "<cmd>tabprevious<cr>" },
}

function M.search_specs()
  return search_specs
end

function M.motion_edit_specs()
  return motion_edit_specs
end

function M.code_lsp_specs()
  return code_lsp_specs
end

function M.global_specs()
  return global_specs
end

function M.window_list_tab_specs()
  return window_list_tab_specs
end

function M.all_specs()
  local specs = {}
  vim.list_extend(specs, motion_edit_specs)
  vim.list_extend(specs, code_lsp_specs)
  vim.list_extend(specs, search_specs)
  vim.list_extend(specs, window_list_tab_specs)
  vim.list_extend(specs, global_specs)
  return specs
end

function M.apply(specs)
  for _, spec in ipairs(specs) do
    if spec.condition == nil or spec.condition() then
      local opts = vim.tbl_extend("force", spec.opts or {}, { desc = spec.desc })
      vim.keymap.set(spec.mode, spec.lhs, spec.rhs or spec.action, opts)
    end
  end
end

function M.expand(specs)
  local expanded = {}
  for _, spec in ipairs(specs) do
    local modes = type(spec.mode) == "table" and spec.mode or { spec.mode }
    for _, mode in ipairs(modes) do
      local copy = vim.tbl_extend("force", spec, { mode = mode })
      expanded[#expanded + 1] = copy
    end
  end
  return expanded
end

function M.docs()
  local docs = {}
  for _, spec in ipairs(M.expand(M.all_specs())) do
    docs[#docs + 1] = {
      source = "spec",
      mode = spec.mode,
      keys = spec.lhs,
      desc = spec.desc,
      group = spec.group,
    }
  end
  return docs
end

return M
