local M = {}

local function file_actions()
  return require("modules.editor.file_actions")
end

local function search_words()
  return require("modules.editor.search_words")
end

local function text_actions()
  return require("modules.editor.text_actions")
end

local function diff_mode()
  return require("modules.editor.diff_mode")
end

local function picker()
  return require("picker")
end

local function explorer()
  return require("modules.editor.explorer")
end

local function ui_module()
  return require("config.ui")
end

local function split_nav_module()
  return require("pure-ui.split_nav")
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
  { mode = "n", lhs = "*", desc = "Search word forward (highlight on)", group = "Search", opts = { expr = true, silent = true }, action = function() return search_words().enable_search_highlight_and_return("*") end },
  { mode = "n", lhs = "#", desc = "Search word backward (highlight on)", group = "Search", opts = { expr = true, silent = true }, action = function() return search_words().enable_search_highlight_and_return("#") end },
  { mode = "n", lhs = "<A-j>", desc = "Move Line Down", group = "Editing", rhs = "<cmd>execute 'move .+' . v:count1<cr>==" },
  { mode = "n", lhs = "<A-k>", desc = "Move Line Up", group = "Editing", rhs = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==" },
  { mode = "i", lhs = "<A-j>", desc = "Move Line Down", group = "Editing", rhs = "<esc><cmd>m .+1<cr>==gi" },
  { mode = "i", lhs = "<A-k>", desc = "Move Line Up", group = "Editing", rhs = "<esc><cmd>m .-2<cr>==gi" },
  { mode = "v", lhs = "<A-j>", desc = "Move Selection Down", group = "Editing", rhs = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv" },
  { mode = "v", lhs = "<A-k>", desc = "Move Selection Up", group = "Editing", rhs = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv" },
  { mode = { "i", "x", "n", "s" }, lhs = "<C-s>", desc = "Save File", group = "Editing", rhs = "<cmd>w<cr><esc>" },
  { mode = "x", lhs = "<", desc = "Indent left", group = "Editing", rhs = "<gv" },
  { mode = "x", lhs = ">", desc = "Indent right", group = "Editing", rhs = ">gv" },
  { mode = "n", lhs = "<A-d>", desc = "Duplicate line", group = "Editing", action = function() text_actions().duplicate_line_or_selection() end },
  { mode = "i", lhs = "<A-d>", desc = "Duplicate line", group = "Editing", action = function() text_actions().duplicate_line_or_selection() end },
  { mode = "x", lhs = "<A-d>", desc = "Duplicate selection", group = "Editing", action = function() text_actions().duplicate_line_or_selection(true) end },
  { mode = "i", lhs = ",", desc = "Undo breakpoint", group = "Editing", rhs = ",<c-g>u" },
  { mode = "i", lhs = ".", desc = "Undo breakpoint", group = "Editing", rhs = ".<c-g>u" },
  { mode = "i", lhs = ";", desc = "Undo breakpoint", group = "Editing", rhs = ";<c-g>u" },
  { mode = "i", lhs = "<Space>", desc = "Insert space immediately", group = "Editing", rhs = "<Space>", opts = { nowait = true } },
  { mode = "n", lhs = "gco", desc = "Add Comment Below", group = "Comment", rhs = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>" },
  { mode = "n", lhs = "gcO", desc = "Add Comment Above", group = "Comment", rhs = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>" },
}

local code_lsp_specs = {
  {
    mode = "n",
    lhs = "<leader>cd",
    desc = "Line Diagnostics",
    group = "Code",
    action = function()
      require("modules.lsp.diagnostics").open_float({ scope = "line" })
    end,
  },
  { mode = { "n", "x" }, lhs = "<leader>cf", desc = "Format", group = "Code", action = function() file_actions().format() end },
  { mode = "n", lhs = "gd", desc = "Go to Definition", group = "g-prefix/LSP", action = lsp_buf_call("definition") },
  { mode = "n", lhs = "gD", desc = "Go to Declaration", group = "g-prefix/LSP", action = lsp_buf_call("declaration") },
  { mode = "n", lhs = "grt", desc = "Go to Type Definition", group = "g-prefix/LSP", action = lsp_buf_call("type_definition") },
  { mode = "n", lhs = "gri", desc = "Go to Implementation", group = "g-prefix/LSP", action = lsp_buf_call("implementation") },
  { mode = { "n", "x" }, lhs = "gra", desc = "Code Action", group = "g-prefix/LSP", action = lsp_buf_call("code_action") },
  { mode = "n", lhs = "grn", desc = "Rename Symbol", group = "g-prefix/LSP", action = lsp_buf_call("rename") },

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
  { mode = "n", lhs = "]]", desc = "Next Reference", group = "Bracket Navigation", action = function() search_words().jump_word_reference(vim.v.count1) end },
  { mode = "n", lhs = "[[", desc = "Prev Reference", group = "Bracket Navigation", action = function() search_words().jump_word_reference(-vim.v.count1) end },
  { mode = "i", lhs = "<C-k>", desc = "Signature Help", group = "g-prefix/LSP", action = lsp_buf_call("signature_help") },
  {
    mode = "n",
    lhs = "<leader>cm",
    desc = "Mason",
    group = "Code",
    action = function()
      vim.cmd("Mason")
    end,
  },
  { mode = "n", lhs = "<leader>K", desc = "Keywordprg", group = "Code", rhs = "<cmd>norm! K<cr>" },
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
  { mode = "n", lhs = "<leader>cp", desc = "Copy path to clipboard", group = "Code", action = function() file_actions().copy_path() end },
  { mode = "n", lhs = "<leader>cN", desc = "Rename file", group = "Code", action = function() file_actions().rename_file() end },
  { mode = "n", lhs = "<leader>cB", desc = "Diff current buffer vs clipboard", group = "Code", action = function() require("modules.editor.clipboard_diff").compare_with_clipboard() end },
}

local search_specs = {
    {
      mode = "n",
      lhs = "<leader>E",
      desc = "File Explorer",
      group = "Files/Terminal",
      action = function()
        local p = picker()
        explorer().open(p.root(), vim.api.nvim_buf_get_name(0))
      end,
    },
    {
      mode = "n",
      lhs = "<leader>e",
      desc = "File Explorer (cwd)",
      group = "Files/Terminal",
      action = function()
        explorer().open(nil, vim.api.nvim_buf_get_name(0))
      end,
    },
    { mode = "n", lhs = "<leader>bb", desc = "Switch to Other Buffer", group = "Buffers", rhs = "<cmd>e #<cr>" },
    { mode = "n", lhs = "<leader>bD", desc = "Delete Buffer and Window", group = "Buffers", rhs = "<cmd>bd<cr>" },
    { mode = "n", lhs = "<leader>gC", desc = "Git Compare (contextual: file vimdiff / repo compare-load)", group = "Git", action = function() require("modules.git.compare_context").prompt() end },
  }

local global_specs = {
  -- Frequent toggles (keymaps) — rare ones live only in Command Center
  { mode = "n", lhs = "<leader>ud", desc = "Toggle diagnostics", group = "UI", action = function() ui_module().toggle_diagnostics() end },
  { mode = "n", lhs = "<leader>uw", desc = "Toggle wrap", group = "UI", action = function() ui_module().toggle_option("wrap", "Wrap") end },
  { mode = "n", lhs = "<leader>uf", desc = "Toggle format on save (global)", group = "UI", action = function() ui_module().toggle_format_global() end },
  { mode = "n", lhs = "<leader>uF", desc = "Toggle format on save (buffer)", group = "UI", action = function() ui_module().toggle_format_buffer() end },
  { mode = "n", lhs = "<leader>uh", desc = "Toggle inlay hints", group = "UI", action = function() ui_module().toggle_inlay_hints() end },
  { mode = "n", lhs = "<leader>uC", desc = "Select colorscheme", group = "UI", action = function() require("colorscheme-sync").select() end },
  { mode = "n", lhs = "<leader>uz", desc = "Toggle Zen Mode", group = "UI", opts = { nowait = true }, action = function() require("config.ui").toggle_zen_mode() end },
  { mode = "n", lhs = "<leader>uZ", desc = "Toggle zoom", group = "UI", action = function() ui_module().toggle_zoom() end },
  { mode = "n", lhs = "<leader>wm", desc = "Toggle zoom", group = "Windows", action = function() ui_module().toggle_zoom() end },
  { mode = "n", lhs = "<leader>uR", desc = "Toggle diff profile (review/focused)", group = "UI", action = function() diff_mode().toggle_diff_profile() end },
  {
    mode = "n",
    lhs = "<leader>ur",
    desc = "Redraw / Clear search highlights / Diff Update",
    group = "UI",
    action = function()
      search_words().clear_search_highlights()
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
      search_words().clear_search_highlights()
      return "<Esc>"
    end,
  },
  { mode = "n", lhs = "<leader>qq", desc = "Quit All", group = "Quit", rhs = "<cmd>qa<cr>" },
  { mode = "n", lhs = "<leader>tn", desc = "Test: nearest", group = "Tests", action = function() require("config.test").run_nearest() end },
  { mode = "n", lhs = "<leader>tf", desc = "Test: file", group = "Tests", action = function() require("config.test").run_file() end },
  { mode = "n", lhs = "<leader>td", desc = "Test: debug", group = "Tests", action = function() require("config.test").run_debug() end },
  { mode = "n", lhs = "<leader>tl", desc = "Test: last", group = "Tests", action = function() require("config.test").run_last() end },
  { mode = "n", lhs = "<leader>tw", desc = "Test: watch", group = "Tests", action = function() require("config.test").toggle_watch() end },
  { mode = "n", lhs = "<leader>pH", desc = "Open Quickfix Playbook", group = "Project/Sessions", action = function() file_actions().open_quickfix_playbook() end },
  { mode = "n", lhs = "<leader>pT", desc = "Task Runner", group = "Project/Sessions", action = function() require("config.editor.task_runner").select() end },
  { mode = "n", lhs = "<leader>ue", desc = "Toggle diff mode", group = "UI", action = function() diff_mode().toggle_diff_mode() end },
  { mode = "i", lhs = "<C-]>", desc = "Line completion (close + semicolon + newline)", group = "Editing", action = function() text_actions().line_completion() end },
  { mode = "n", lhs = "<C-h>", desc = "Move to left window/tmux pane", group = "Windows", action = function() split_nav_module().move("h") end },
  { mode = "n", lhs = "<C-j>", desc = "Move to lower window/tmux pane", group = "Windows", action = function() split_nav_module().move("j") end },
  { mode = "n", lhs = "<C-k>", desc = "Move to upper window/tmux pane", group = "Windows", action = function() split_nav_module().move("k") end },
  { mode = "n", lhs = "<C-l>", desc = "Move to right window/tmux pane", group = "Windows", action = function() split_nav_module().move("l") end },
  { mode = "n", lhs = "<leader><space>", desc = "Command Center", group = "Command Center", action = function() require("config.editor.command_center").select() end },
}

local window_list_tab_specs = {
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

return M
