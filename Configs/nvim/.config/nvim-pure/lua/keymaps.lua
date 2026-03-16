-- Keymaps: pure keymap bindings

local map = vim.keymap.set

-- ── Motion: wrapped-line aware j/k ───────────────────────────────────────────

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up" })
map("n", "L", "$", { desc = "End of line" })
map("n", "H", "^", { desc = "Start of line" })
map("n", "dw", "vb_d", { desc = "Delete word backward" })
map("n", "<C-i>", "<C-I>", { noremap = true, desc = "Jump forward" })

-- ── Search: saner n/N (open folds, keep direction consistent) ────────────────

map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]",       { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]",       { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]",       { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]",       { expr = true, desc = "Prev Search Result" })

local cmd = require("command_helpers")

map("n", "*", function() return cmd.enable_search_highlight_and_return("*") end,
  { expr = true, silent = true, desc = "Search word forward (highlight on)" })
map("n", "#", function() return cmd.enable_search_highlight_and_return("#") end,
  { expr = true, silent = true, desc = "Search word backward (highlight on)" })

-- ── Move lines (Alt-j/k, all modes) ──────────────────────────────────────────

map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==",                        { desc = "Move Line Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==",                 { desc = "Move Line Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi",                                        { desc = "Move Line Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi",                                        { desc = "Move Line Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",           { desc = "Move Selection Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv",    { desc = "Move Selection Up" })
map("v", "J", "<cmd>m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", "<cmd>m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- ── Editing ───────────────────────────────────────────────────────────────────

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("x", "<", "<gv", { desc = "Indent left" })
map("x", ">", ">gv", { desc = "Indent right" })

map("n", "<A-d>", function() cmd.duplicate_line_or_selection() end, { desc = "Duplicate line" })
map("x", "<A-d>", function() cmd.duplicate_line_or_selection(true) end, { desc = "Duplicate selection" })

-- Undo break-points on common punctuation (smaller undo chunks)
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Add comment on new line below / above
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- ── LSP ───────────────────────────────────────────────────────────────────────

map("n", "gd",  vim.lsp.buf.definition,      { desc = "Go to Definition" })
map("n", "gD",  vim.lsp.buf.declaration,      { desc = "Go to Declaration" })
map("n", "gy",  vim.lsp.buf.type_definition,  { desc = "Go to Type Definition" })
map("n", "K",   vim.lsp.buf.hover,            { desc = "Hover Documentation" })

-- Vertical split + goto definition
map("n", "gV", ":vsplit<CR><cmd>lua vim.lsp.buf.definition()<CR>",
  { silent = true, desc = "Vsplit & goto definition" })

-- ── Peek preview (floating window, chainable definitions) ─────────────────────

local function peek(method)
  return function() require("peek").request("textDocument/" .. method) end
end

map("n", "gpc", function() require("peek").close_all() end, { desc = "Peek: close all" })
map("n", "gpd", peek("definition"),      { desc = "Peek Definition" })
map("n", "gpt", peek("typeDefinition"),  { desc = "Peek Type Definition" })
map("n", "gpi", peek("implementation"),  { desc = "Peek Implementation" })
map("n", "gpD", peek("declaration"),     { desc = "Peek Declaration" })
map("n", "gpr", function() require("peek").references() end, { desc = "Peek References (picker)" })

-- Line diagnostics float
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

-- ── Format ────────────────────────────────────────────────────────────────────

map({ "n", "x" }, "<leader>cf", function() cmd.format() end, { desc = "Format" })

-- Code actions / rename / signature
map("n", "<leader>ca", vim.lsp.buf.code_action,    { desc = "Code Action" })
map("x", "<leader>ca", vim.lsp.buf.code_action,    { desc = "Code Action" })
map("n", "<leader>cr", vim.lsp.buf.rename,         { desc = "Rename Symbol" })

-- ── References & symbols (via Snacks picker) ──────────────────────────────────

local function snacks_pick(method)
  return function()
    local ok_s, Snacks = pcall(require, "snacks")
    if ok_s and Snacks.picker then Snacks.picker[method]() end
  end
end

map("n", "<leader>cR", snacks_pick("lsp_references"),        { desc = "References (picker)" })
map("n", "]]",         function() cmd.jump_word_reference(vim.v.count1) end,  { desc = "Next Reference" })
map("n", "[[",         function() cmd.jump_word_reference(-vim.v.count1) end, { desc = "Prev Reference" })
map("n", "<leader>cs", snacks_pick("lsp_symbols"),            { desc = "LSP Symbols" })
map("n", "<leader>cS", snacks_pick("lsp_workspace_symbols"), { desc = "Workspace Symbols" })

map("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
map("n", "gK",    vim.lsp.buf.signature_help, { desc = "Signature Help" })
map("n", "<leader>cm", "<cmd>Mason<cr>",      { desc = "Mason" })
map("n", "<leader>K",  "<cmd>norm! K<cr>",    { desc = "Keywordprg" })

-- ── Refactoring (<leader>r) ──────────────────────────────────────────────────

map("n", "<leader>rs", vim.lsp.buf.code_action, { desc = "Refactor (all actions)" })

map("x", "<leader>rx", function()
  vim.lsp.buf.code_action({ context = { only = { "refactor.extract.variable" } }, apply = true })
end, { desc = "Extract Variable" })

map("x", "<leader>rf", function()
  vim.lsp.buf.code_action({ context = { only = { "refactor.extract.function" } }, apply = true })
end, { desc = "Extract Function" })

map("n", "<leader>ri", function()
  vim.lsp.buf.code_action({ context = { only = { "refactor.inline" } }, apply = true })
end, { desc = "Inline Variable" })

map("n", "<leader>ro", function()
  vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
end, { desc = "Organize Imports" })

-- ── Replace ───────────────────────────────────────────────────────────────────

map("n", "<leader>rr", [[:%s/\V<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace all occurrences" })
map("v", "<leader>rr", [[\"vy:%s/\V<C-r>=escape(@v, '/\')<CR>/<C-r>v/gI<Left><Left><Left>]],
  { desc = "Replace all occurrences" })

-- ── Clipboard ─────────────────────────────────────────────────────────────────

map("n", "<leader>cp", function() cmd.copy_path() end,   { desc = "Copy path to clipboard" })
map("n", "<leader>cN", function() cmd.rename_file() end, { desc = "Rename file" })

-- ── Buffers ───────────────────────────────────────────────────────────────────

-- map("n", "<S-TAB>", "<cmd>bp<CR>", { desc = "Prev buffer" })
map("n", "[b",      "<cmd>bp<CR>", { desc = "Prev buffer" })
map("n", "]b",      "<cmd>bn<CR>", { desc = "Next buffer" })

-- ── Windows (<leader>w) ──────────────────────────────────────────────────────

map("n", "<leader>w",  "<C-W>",  { desc = "Windows", remap = true })
map("n", "<leader>ww", "<C-W>w", { desc = "Other Window",        remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window",       remap = true })
map("n", "<leader>wq", "<C-W>c", { desc = "Close Window",        remap = true })
map("n", "<leader>ws", "<C-W>s", { desc = "Split Below",         remap = true })
map("n", "<leader>wv", "<C-W>v", { desc = "Split Right",         remap = true })
map("n", "<leader>wh", "<C-W>h", { desc = "Go to Left Window",   remap = true })
map("n", "<leader>wj", "<C-W>j", { desc = "Go to Below Window",  remap = true })
map("n", "<leader>wk", "<C-W>k", { desc = "Go to Above Window",  remap = true })
map("n", "<leader>wl", "<C-W>l", { desc = "Go to Right Window",  remap = true })
map("n", "<leader>wo", "<C-W>o", { desc = "Close Other Windows", remap = true })
map("n", "<leader>w=", "<C-W>=", { desc = "Equal Window Sizes",  remap = true })
map("n", "<leader>wT", "<C-W>T", { desc = "Window to Tab",       remap = true })
map("n", "<leader>-",  "<C-W>s", { desc = "Split Below",         remap = true })
map("n", "<leader>|",  "<C-W>v", { desc = "Split Right",         remap = true })


-- Resize with Alt-arrows
map("n", "<M-Up>",    "<cmd>resize +2<cr>",          { desc = "Increase Window Height" })
map("n", "<M-Down>",  "<cmd>resize -2<cr>",          { desc = "Decrease Window Height" })
map("n", "<M-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<M-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- ── Lists ─────────────────────────────────────────────────────────────────────

map("n", "<leader>xl", function()
  local success, err = pcall(function()
    if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
      vim.cmd.lclose()
    else
      vim.cmd.lopen()
    end
  end)
  if not success then vim.notify(tostring(err), vim.log.levels.ERROR) end
end, { desc = "Location List" })

map("n", "<leader>xq", function()
  local success, err = pcall(function()
    if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
      vim.cmd.cclose()
    else
      vim.cmd.copen()
    end
  end)
  if not success then vim.notify(tostring(err), vim.log.levels.ERROR) end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Prev Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- ── Tabs ──────────────────────────────────────────────────────────────────────

map("n", "<leader><tab>l",    "<cmd>tablast<cr>",    { desc = "Last Tab" })
map("n", "<leader><tab>o",    "<cmd>tabonly<cr>",    { desc = "Close Other Tabs" })
map("n", "<leader><tab>f",    "<cmd>tabfirst<cr>",   { desc = "First Tab" })
map("n", "<leader><tab><tab>","<cmd>tabnew<cr>",     { desc = "New Tab" })
map("n", "<leader><tab>]",    "<cmd>tabnext<cr>",    { desc = "Next Tab" })
map("n", "<leader><tab>d",    "<cmd>tabclose<cr>",   { desc = "Close Tab" })
map("n", "<leader><tab>[",    "<cmd>tabprevious<cr>",{ desc = "Prev Tab" })

-- ── UI utilities ──────────────────────────────────────────────────────────────

map("n", "<leader>ur", function()
  cmd.clear_search_highlights()
  vim.cmd("diffupdate")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-l>", true, false, true), "n", false)
end, { desc = "Redraw / Clear search highlights / Diff Update" })

map("n", "<Esc>", function()
  cmd.clear_search_highlights()
  return "<Esc>"
end, { expr = true, silent = true, desc = "Clear search highlights" })

map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- Diff mode toggle
map("n", "<leader>ue", function() cmd.enable_diff_mode() end,  { desc = "Enable diff mode" })
map("n", "<leader>uE", function() cmd.disable_diff_mode() end, { desc = "Disable diff mode" })

-- ── Line completion (close brackets + semicolon + newline) ──────────────────

map("i", "<C-]>", function() cmd.line_completion() end,
  { desc = "Line completion (close + semicolon + newline)" })

local ok_ss, ss = pcall(require, "smart-splits")
if ok_ss then
  map("n", "<C-h>", ss.move_cursor_left, { desc = "Smart move left" })
  map("n", "<C-j>", ss.move_cursor_down, { desc = "Smart move down" })
  map("n", "<C-k>", ss.move_cursor_up, { desc = "Smart move up" })
  map("n", "<C-l>", ss.move_cursor_right, { desc = "Smart move right" })
end
