-- Keymaps migrated from ~/.config/nvim (isolated VSCode/Cursor layer).
-- Native Neovim plugins (picker, gitsigns, mason, avante, etc.) are mapped to
-- equivalent VSCode/Cursor commands where possible.

local H = require("helpers")
local action = H.action
local notify = H.notify
local notify_range = H.notify_range
local apply = H.apply_specs
local map_both = H.map_both

local map = vim.keymap.set

-- ── Motion & editing (keymap_specs.motion_edit_specs) ────────────────────────

apply({
  {
    mode = { "n", "x" },
    lhs = "j",
    desc = "Down (gj when wrap)",
    rhs = "v:count == 0 ? 'gj' : 'j'",
    opts = { expr = true, silent = true },
  },
  {
    mode = { "n", "x" },
    lhs = "k",
    desc = "Up (gk when wrap)",
    rhs = "v:count == 0 ? 'gk' : 'k'",
    opts = { expr = true, silent = true },
  },
  { mode = "n", lhs = "L", desc = "End of line", rhs = "$" },
  { mode = "n", lhs = "H", desc = "Start of line", rhs = "^" },
  { mode = "n", lhs = "dw", desc = "Delete word backward", rhs = "vb_d" },
  { mode = "n", lhs = "<C-i>", desc = "Jump forward", rhs = "<C-I>", opts = { noremap = true } },
  {
    mode = "n",
    lhs = "n",
    desc = "Next search result",
    rhs = "'Nn'[v:searchforward].'zv'",
    opts = { expr = true },
  },
  {
    mode = "x",
    lhs = "n",
    desc = "Next search result",
    rhs = "'Nn'[v:searchforward]",
    opts = { expr = true },
  },
  {
    mode = "n",
    lhs = "N",
    desc = "Prev search result",
    rhs = "'nN'[v:searchforward].'zv'",
    opts = { expr = true },
  },
  {
    mode = "x",
    lhs = "N",
    desc = "Prev search result",
    rhs = "'nN'[v:searchforward]",
    opts = { expr = true },
  },
  { mode = "n", lhs = "<C-d>", desc = "Scroll half-page down", rhs = "<C-d>zz" },
  { mode = "n", lhs = "<C-u>", desc = "Scroll half-page up", rhs = "<C-u>zz" },
  { mode = "n", lhs = "Y", desc = "Yank to EOL", rhs = "y$" },
  { mode = "n", lhs = "]<leader>", desc = "Add blank line below", rhs = "o<Esc>k" },
  { mode = "n", lhs = "[<leader>", desc = "Add blank line above", rhs = "O<Esc>j" },
  { mode = "v", lhs = "p", desc = "Paste without overwriting", rhs = "P" },
  { mode = "x", lhs = "<", desc = "Indent left", rhs = "<gv" },
  { mode = "x", lhs = ">", desc = "Indent right", rhs = ">gv" },
  { mode = "i", lhs = ",", desc = "Undo breakpoint", rhs = ",<c-g>u" },
  { mode = "i", lhs = ".", desc = "Undo breakpoint", rhs = ".<c-g>u" },
  { mode = "i", lhs = ";", desc = "Undo breakpoint", rhs = ";<c-g>u" },
  { mode = "i", lhs = "<Space>", desc = "Insert space immediately", rhs = "<Space>", opts = { nowait = true } },
})

-- Move lines (Neovim: Alt-j/k only — NOT Ctrl-j/k; passthrough in Cursor keybindings.json)
local move_down = action("editor.action.moveLinesDownAction")
local move_up = action("editor.action.moveLinesUpAction")
for _, spec in ipairs({
  { mode = "n", lhs = "<A-j>", desc = "Move line down" },
  { mode = "n", lhs = "<A-k>", desc = "Move line up" },
  { mode = "n", lhs = "<M-j>", desc = "Move line down (meta)" },
  { mode = "n", lhs = "<M-k>", desc = "Move line up (meta)" },
  { mode = "i", lhs = "<A-j>", desc = "Move line down" },
  { mode = "i", lhs = "<A-k>", desc = "Move line up" },
  { mode = "i", lhs = "<M-j>", desc = "Move line down (meta)" },
  { mode = "i", lhs = "<M-k>", desc = "Move line up (meta)" },
  { mode = "v", lhs = "<A-j>", desc = "Move selection down" },
  { mode = "v", lhs = "<A-k>", desc = "Move selection up" },
  { mode = "v", lhs = "<M-j>", desc = "Move selection down (meta)" },
  { mode = "v", lhs = "<M-k>", desc = "Move selection up (meta)" },
}) do
  map(spec.mode, spec.lhs, spec.lhs:find("j") and move_down or move_up, { desc = spec.desc, silent = true })
end

-- Duplicate line/selection
local function duplicate_selection()
  H.vscode().action("editor.action.copyLinesDownAction")
end
map("n", "<A-d>", duplicate_selection, { desc = "Duplicate line", silent = true })
map("i", "<A-d>", duplicate_selection, { desc = "Duplicate line", silent = true })
map("x", "<A-d>", duplicate_selection, { desc = "Duplicate selection", silent = true })

-- Save
map({ "n", "i", "x", "s" }, "<C-s>", action("workbench.action.files.saveAll"), { desc = "Save all", silent = true, noremap = true })
map_both("<leader>w", action("workbench.action.files.save"), { desc = "Save file" })

-- Comments (Neovim: gcc/gb; VSCode comment actions)
map({ "n", "v" }, "gcc", notify_range("editor.action.commentLine"), { desc = "Toggle line comment" })
map("v", "gb", notify_range("editor.action.blockComment"), { desc = "Toggle block comment" })
map("n", "gco", action("editor.action.insertLineAfter"), { desc = "Add comment below" })
map("n", "gcO", action("editor.action.insertLineBefore"), { desc = "Add comment above" })

-- Folds (Neovim z* → VSCode fold commands)
apply({
  { mode = "n", lhs = "za", desc = "Toggle fold", action = notify("editor.toggleFold") },
  { mode = "n", lhs = "zo", desc = "Open fold", action = notify("editor.unfold") },
  { mode = "n", lhs = "zO", desc = "Open fold recursive", action = notify("editor.unfoldRecursively") },
  { mode = "n", lhs = "zc", desc = "Close fold", action = notify("editor.fold") },
  { mode = "n", lhs = "zm", desc = "Fold all", action = notify("editor.foldAll") },
  { mode = "n", lhs = "zr", desc = "Unfold all", action = notify("editor.unfoldAll") },
  { mode = "n", lhs = "zb", desc = "Fold block comments", action = notify("editor.foldAllBlockComments") },
  { mode = "n", lhs = "zg", desc = "Fold marker regions", action = notify("editor.foldAllMarkerRegions") },
  { mode = "n", lhs = "zG", desc = "Unfold marker regions", action = notify("editor.unfoldAllMarkerRegions") },
  { mode = "n", lhs = "z1", desc = "Fold level 1", action = notify("editor.foldLevel1") },
  { mode = "n", lhs = "z2", desc = "Fold level 2", action = notify("editor.foldLevel2") },
  { mode = "n", lhs = "z3", desc = "Fold level 3", action = notify("editor.foldLevel3") },
})

-- ── LSP / code (keymap_specs.code_lsp_specs) ─────────────────────────────────

apply({
  { mode = "n", lhs = "gd", desc = "Go to definition", action = action("editor.action.revealDefinition") },
  { mode = "n", lhs = "gD", desc = "Go to declaration", action = action("editor.action.revealDeclaration") },
  { mode = "n", lhs = "gf", desc = "Go to declaration", action = action("editor.action.revealDeclaration") },
  { mode = "n", lhs = "grt", desc = "Go to type definition", action = action("editor.action.goToTypeDefinition") },
  { mode = "n", lhs = "gri", desc = "Go to implementation", action = action("editor.action.goToImplementation") },
  { mode = { "n", "x" }, lhs = "gra", desc = "Code action", action = action("editor.action.quickFix") },
  { mode = "n", lhs = "grn", desc = "Rename symbol", action = action("editor.action.rename") },
  { mode = "n", lhs = "K", desc = "Hover documentation", action = action("editor.action.showHover") },
  { mode = "n", lhs = "gK", desc = "Signature help", action = action("editor.action.parameterHints.trigger") },
  { mode = "i", lhs = "<C-k>", desc = "Signature help", action = action("editor.action.parameterHints.trigger") },
  { mode = "n", lhs = "gV", desc = "Vsplit goto definition", action = function()
    H.vscode().action("editor.action.revealDefinitionAside")
  end },
  { mode = { "n", "x" }, lhs = "<leader>ca", desc = "Code action", action = action("editor.action.quickFix") },
  { mode = { "n", "x" }, lhs = "<leader>cf", desc = "Format", action = action("editor.action.formatDocument") },
  { mode = "n", lhs = "<leader>cd", desc = "Line diagnostics", action = action("editor.action.showDiagnostics") },
  { mode = "n", lhs = "<leader>K", desc = "Keywordprg", rhs = "<cmd>norm! K<cr>" },
  { mode = "n", lhs = "<leader>o", desc = "Organize imports", action = action("editor.action.organizeImports") },
  { mode = "n", lhs = "<leader>ro", desc = "Organize imports", action = action("editor.action.organizeImports") },
  { mode = "n", lhs = "<leader>rr", desc = "Replace all occurrences", action = action("editor.action.startFindReplaceAction") },
  { mode = "v", lhs = "<leader>rr", desc = "Replace all occurrences", action = action("editor.action.startFindReplaceAction") },
  { mode = "v", lhs = "<leader>r", desc = "Refactor menu", action = action("editor.action.refactor") },
  { mode = "v", lhs = "<leader>rx", desc = "Extract variable", action = action("editor.action.refactor") },
  { mode = "v", lhs = "<leader>rf", desc = "Extract function", action = action("editor.action.refactor") },
  { mode = "n", lhs = "<leader>ri", desc = "Inline variable", action = action("editor.action.refactor") },
  { mode = "n", lhs = "<leader>rp", desc = "Refactor preview", action = action("editor.action.refactor.preview") },
  { mode = "n", lhs = "<leader>cp", desc = "Copy path", action = action("copyRelativeFilePath") },
  { mode = "n", lhs = "<leader>cN", desc = "Rename file", action = function()
    notify("workbench.files.action.showActiveFileInExplorer")()
    notify("renameFile")()
  end },
  { mode = "n", lhs = "<leader>cB", desc = "Diff buffer vs clipboard", action = action("workbench.action.compareEditorWithClipboard") },
  { mode = "n", lhs = "<leader>i", desc = "Toggle bool", action = notify("extension.toggleBool") },
})

-- Peek preview (lsp-nav gp* → VSCode peek widget)
apply({
  { mode = { "n", "x" }, lhs = "gpd", desc = "Peek definition", action = action("editor.action.peekDefinition") },
  { mode = { "n", "x" }, lhs = "gpt", desc = "Peek type definition", action = action("editor.action.peekTypeDefinition") },
  { mode = { "n", "x" }, lhs = "gpi", desc = "Peek implementation", action = action("editor.action.peekImplementation") },
  { mode = { "n", "x" }, lhs = "gpD", desc = "Peek declaration", action = action("editor.action.peekDeclaration") },
  { mode = { "n", "x" }, lhs = "gpr", desc = "Peek references", action = action("editor.action.referenceSearch.trigger") },
  { mode = "n", lhs = "gpc", desc = "Peek close", action = action("closeReferenceSearch") },
  { mode = { "n", "x" }, lhs = "<leader>pd", desc = "Peek definition", action = action("editor.action.peekDefinition") },
  { mode = { "n", "x" }, lhs = "<leader>pt", desc = "Peek type definition", action = action("editor.action.peekTypeDefinition") },
  { mode = { "n", "x" }, lhs = "<leader>pi", desc = "Peek implementation", action = action("editor.action.peekImplementation") },
  { mode = { "n", "x" }, lhs = "<leader>pD", desc = "Peek declaration", action = action("editor.action.peekDeclaration") },
  { mode = { "n", "x" }, lhs = "<leader>pr", desc = "Peek references", action = action("editor.action.referenceSearch.trigger") },
  { mode = { "n", "x" }, lhs = "<leader>pl", desc = "Peek locations", action = action("editor.action.peekLocations") },
  { mode = "n", lhs = "<leader>pc", desc = "Peek close", action = action("closeReferenceSearch") },
})

-- References / symbols
map("n", "]]", action("editor.action.wordHighlight.next"), { desc = "Next reference", silent = true })
map("n", "[[", action("editor.action.wordHighlight.prev"), { desc = "Prev reference", silent = true })
map("n", "grr", action("editor.action.referenceSearch.trigger"), { desc = "Find references", silent = true })
map("n", "<leader>sR", action("references-view.find"), { desc = "References sidebar", silent = true })
map("n", "<leader>ds", action("workbench.action.showAllSymbols"), { desc = "Workspace symbols", silent = true })
map("n", "<leader>ss", action("workbench.action.gotoSymbol"), { desc = "Document symbols", silent = true })
map("n", "<leader>sS", action("workbench.action.showAllSymbols"), { desc = "Workspace symbols", silent = true })
map("n", "gO", action("workbench.action.gotoSymbol"), { desc = "Document symbols", silent = true })
map("n", "gW", action("workbench.action.showAllSymbols"), { desc = "Workspace symbols", silent = true })
map("n", "<C-w>gd", action("editor.action.revealDefinitionAside"), { desc = "Definition aside", silent = true })
map("n", "<C-w>gf", action("editor.action.revealDeclaration"), { desc = "Declaration aside", silent = true })

-- ── Search / files (picker user_keymaps → VSCode/find-it-faster) ─────────────

local find_files = notify("find-it-faster.findFiles")
local find_within = notify("find-it-faster.findWithinFiles")
local find_within_type = notify("find-it-faster.findWithinFilesWithType")

apply({
  { mode = "n", lhs = "<leader>ff", desc = "Find files (cwd)", action = find_files },
  { mode = "n", lhs = "<leader>fF", desc = "Find files (root)", action = notify("workbench.action.quickOpen") },
  { mode = "n", lhs = "<leader>fc", desc = "Config files", action = function()
    vim.fn.VSCodeNotify("workbench.action.quickOpen", vim.fn.stdpath("config"))
  end },
  { mode = "n", lhs = "<leader>fg", desc = "Git files", action = notify("workbench.action.quickOpen") },
  { mode = "n", lhs = "<leader>fR", desc = "Recent files", action = notify("workbench.action.openRecent") },
  { mode = "n", lhs = "<leader>fn", desc = "New file", action = function()
    notify("workbench.explorer.fileView.focus")()
    notify("explorer.newFile")()
  end },
  { mode = "n", lhs = "<leader>f", desc = "Find files", action = find_files },
  { mode = "n", lhs = "<leader>pf", desc = "Quick open", action = notify("workbench.action.quickOpen") },
  { mode = "n", lhs = "<leader>pp", desc = "Switch project", action = notify("workbench.action.openRecent") },
  { mode = "n", lhs = "<leader>sg", desc = "Grep regex (cwd)", action = find_within },
  { mode = "n", lhs = "<leader>sG", desc = "Grep regex (root)", action = find_within_type },
  { mode = "n", lhs = "<leader>s/", desc = "Grep regex (root)", action = find_within },
  { mode = "n", lhs = "<leader>sw", desc = "Search word (cwd)", action = function()
    notify("editor.action.addSelectionToNextFindMatch")()
    find_within()
  end },
  { mode = { "n", "x" }, lhs = "<leader>sW", desc = "Search word (root)", action = function()
    notify("editor.action.addSelectionToNextFindMatch")()
    find_within_type()
  end },
  { mode = "n", lhs = "<leader>/", desc = "Search in file", action = action("actions.find") },
  { mode = "n", lhs = "<leader>st", desc = "Search TODO", action = notify("workbench.action.findInFiles") },
  { mode = "n", lhs = "<leader>sT", desc = "Search TODO/FIXME", action = notify("workbench.action.findInFiles") },
  { mode = "n", lhs = "<leader>sp", desc = "Search project", action = function()
    notify("editor.action.addSelectionToNextFindMatch")()
    notify("workbench.action.findInFiles")()
  end },
  { mode = "n", lhs = "<leader>sr", desc = "Resume last search", action = notify("rerunSearchEditorAction") },
  { mode = "n", lhs = "<leader>sh", desc = "Help", action = notify("workbench.action.showCommands") },
  { mode = "n", lhs = "<leader>sk", desc = "Keymaps", action = notify("whichkey.searchBindings") },
  { mode = "n", lhs = "<leader>sc", desc = "Command history", action = notify("workbench.action.showCommands") },
  { mode = "n", lhs = "<leader>sC", desc = "Commands", action = notify("workbench.action.showCommands") },
  { mode = "n", lhs = "<leader>sd", desc = "Document diagnostics", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>sD", desc = "Workspace diagnostics", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>sf", desc = "Show in explorer", action = notify("workbench.files.action.showActiveFileInExplorer") },
  { mode = "n", lhs = "<leader>fr", desc = "Rename file", action = function()
    notify("workbench.files.action.showActiveFileInExplorer")()
    notify("renameFile")()
  end },
  { mode = "n", lhs = ",f", desc = "Find within files (typed)", action = find_within_type },
  { mode = "n", lhs = ",r", desc = "Find within files", action = find_within },
})

-- Explorer / buffers (keymap_specs.search_specs)
apply({
  { mode = "n", lhs = "<leader>e", desc = "File explorer (cwd)", action = notify("workbench.explorer.fileView.focus") },
  { mode = "n", lhs = "<leader>E", desc = "Reveal in explorer", action = notify("workbench.files.action.showActiveFileInExplorer") },
  { mode = "n", lhs = "<leader>bb", desc = "Alternate buffer", action = notify("workbench.action.openPreviousRecentlyUsedEditor") },
  { mode = "n", lhs = "<leader>bD", desc = "Delete buffer", action = notify("workbench.action.closeActiveEditor") },
  { mode = "n", lhs = "<leader>bd", desc = "Delete buffer", action = notify("workbench.action.closeActiveEditor") },
  { mode = "n", lhs = "<leader>bo", desc = "Close other editors", action = notify("workbench.action.closeOtherEditors") },
})

-- ── Windows / tabs / lists (keymap_specs.window_list_tab_specs) ────────────────

apply({
  { mode = "n", lhs = "<leader>ww", desc = "Other window", action = notify("workbench.action.focusNextGroup") },
  { mode = "n", lhs = "<leader>wd", desc = "Delete window", action = notify("workbench.action.closeActiveEditor") },
  { mode = "n", lhs = "<leader>ws", desc = "Split below", action = notify("workbench.action.splitEditorDown") },
  { mode = "n", lhs = "<leader>wv", desc = "Split right", action = notify("workbench.action.splitEditorRight") },
  { mode = "n", lhs = "<leader>wh", desc = "Window left", action = notify("workbench.action.navigateLeft") },
  { mode = "n", lhs = "<leader>wj", desc = "Window down", action = notify("workbench.action.navigateDown") },
  { mode = "n", lhs = "<leader>wk", desc = "Window up", action = notify("workbench.action.navigateUp") },
  { mode = "n", lhs = "<leader>wl", desc = "Window right", action = notify("workbench.action.navigateRight") },
  { mode = "n", lhs = "<leader>wo", desc = "Close other editors", action = notify("workbench.action.closeOtherEditors") },
  { mode = "n", lhs = "<leader>w=", desc = "Equalize editor groups", action = notify("workbench.action.evenEditorWidths") },
  { mode = "n", lhs = "<leader>wT", desc = "Move editor to new window", action = notify("workbench.action.moveEditorToNewWindow") },
  { mode = "n", lhs = "<leader>-", desc = "Split below", action = notify("workbench.action.splitEditorDown") },
  { mode = "n", lhs = "<leader>|", desc = "Split right", action = notify("workbench.action.splitEditorRight") },
  { mode = "n", lhs = "<leader>q", desc = "Close editor", action = notify("workbench.action.closeActiveEditor") },
  -- Window navigation (Neovim: Ctrl-h/j/k/l — NOT move line; use Alt-j/k for that)
  { mode = "n", lhs = "<C-h>", desc = "Navigate left", action = notify("workbench.action.navigateLeft") },
  { mode = "n", lhs = "<C-j>", desc = "Navigate down", action = notify("workbench.action.navigateDown") },
  { mode = "n", lhs = "<C-k>", desc = "Navigate up", action = notify("workbench.action.navigateUp") },
  { mode = "n", lhs = "<C-l>", desc = "Navigate right", action = notify("workbench.action.navigateRight") },
  { mode = "n", lhs = "<M-Up>", desc = "Increase editor height", action = notify("workbench.action.increaseViewHeight") },
  { mode = "n", lhs = "<M-Down>", desc = "Decrease editor height", action = notify("workbench.action.decreaseViewHeight") },
  { mode = "n", lhs = "<M-Left>", desc = "Decrease editor width", action = notify("workbench.action.decreaseViewWidth") },
  { mode = "n", lhs = "<M-Right>", desc = "Increase editor width", action = notify("workbench.action.increaseViewWidth") },
  { mode = "n", lhs = "<leader>xl", desc = "Location list", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>xq", desc = "Quickfix list", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>sq", desc = "Quickfix list", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>sl", desc = "Location list", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>el", desc = "Problems panel", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>en", desc = "Next diagnostic", action = notify("editor.action.marker.next") },
  { mode = "n", lhs = "<leader>ep", desc = "Prev diagnostic", action = notify("editor.action.marker.prev") },
  { mode = "n", lhs = "<leader><tab>]", desc = "Next tab", action = notify("workbench.action.nextEditor") },
  { mode = "n", lhs = "<leader><tab>[", desc = "Prev tab", action = notify("workbench.action.previousEditor") },
  { mode = "n", lhs = "<leader><tab>d", desc = "Close tab", action = notify("workbench.action.closeActiveEditor") },
  { mode = "n", lhs = "<leader><tab>o", desc = "Close other tabs", action = notify("workbench.action.closeOtherEditors") },
  { mode = "n", lhs = "<leader><tab><tab>", desc = "New tab", action = notify("workbench.action.newGroupBelow") },
  { mode = "n", lhs = "<leader><tab>f", desc = "First tab", action = notify("workbench.action.firstEditorInGroup") },
  { mode = "n", lhs = "<leader><tab>l", desc = "Last tab", action = notify("workbench.action.lastEditorInGroup") },
})

-- Editor tabs (legacy vscode-nvim maps kept)
map_both("<leader>h", notify("workbench.action.previousEditor"), { desc = "Previous editor" })
map_both("<leader>l", notify("workbench.action.nextEditor"), { desc = "Next editor" })
map("n", "\\\\", action("workbench.action.showAllEditors"), { desc = "All editors", silent = true })

-- ── Git (gitsigns + picker user_keymaps) ─────────────────────────────────────

local git_hunk_next = function()
  pcall(function() H.vscode().action("gitlens.nextHunk") end)
  H.vscode().action("workbench.action.editor.nextChange")
end
local git_hunk_prev = function()
  pcall(function() H.vscode().action("gitlens.previousHunk") end)
  H.vscode().action("workbench.action.editor.previousChange")
end

apply({
  { mode = "n", lhs = "]h", desc = "Next git hunk", action = git_hunk_next },
  { mode = "n", lhs = "[h", desc = "Prev git hunk", action = git_hunk_prev },
  { mode = "n", lhs = "<leader>gs", desc = "Stage hunk", action = notify("git.stageSelectedRanges") },
  { mode = "n", lhs = "<leader>gr", desc = "Reset hunk", action = notify("git.revertSelectedRanges") },
  { mode = "n", lhs = "<leader>gS", desc = "Stage file", action = notify("git.stageAll") },
  { mode = "n", lhs = "<leader>gR", desc = "Reset file", action = notify("git.unstageAll") },
  { mode = "n", lhs = "<leader>gp", desc = "Preview hunk", action = notify("gitlens.showQuickCommitDetails") },
  { mode = "n", lhs = "<leader>gt", desc = "Toggle line blame", action = notify("gitlens.toggleLineBlame") },
  { mode = "n", lhs = "<leader>gd", desc = "Diff file", action = notify("git.openChange") },
  { mode = "n", lhs = "<leader>gD", desc = "Diff HEAD~", action = notify("gitlens.diffWithPrevious") },
  { mode = "n", lhs = "<leader>gb", desc = "Git blame line", action = notify("gitlens.showLineCommit") },
  { mode = "n", lhs = "<leader>gf", desc = "Git file history", action = notify("gitlens.showFileHistory") },
  { mode = "n", lhs = "<leader>gl", desc = "Git log (cwd)", action = notify("gitlens.showQuickCommitDetails") },
  { mode = "n", lhs = "<leader>gL", desc = "Git log (root)", action = notify("gitlens.showQuickCommitDetails") },
  { mode = "n", lhs = "<leader>gg", desc = "Git graph", action = notify("gitlens.showGraphPage") },
  { mode = "n", lhs = "<leader>gC", desc = "Git compare", action = notify("gitlens.compareWith") },
  { mode = "n", lhs = "<leader>gB", desc = "Git browse", action = notify("gitlens.openFileOnRemote") },
  { mode = "n", lhs = "<leader>gY", desc = "Copy git URL", action = notify("gitlens.copyRemoteFileUrl") },
})

-- ── UI / toggles / command center (keymap_specs.global_specs) ────────────────

apply({
  { mode = "n", lhs = "<leader><space>", desc = "Command center", action = notify("workbench.action.showCommands") },
  { mode = { "n", "v" }, lhs = "<leader> ", desc = "Command palette", action = notify("workbench.action.showCommands") },
  { mode = "n", lhs = "<leader>ud", desc = "Toggle diagnostics", action = notify("workbench.actions.view.problems") },
  { mode = "n", lhs = "<leader>uw", desc = "Toggle word wrap", action = notify("editor.action.toggleWordWrap") },
  { mode = "n", lhs = "<leader>uh", desc = "Toggle inlay hints", action = notify("editor.action.inlayHints.toggle") },
  { mode = "n", lhs = "<leader>uz", desc = "Toggle Zen mode", action = notify("workbench.action.toggleZenMode") },
  { mode = "n", lhs = "<leader>uZ", desc = "Toggle zoom", action = notify("workbench.action.maximizeEditor") },
  { mode = "n", lhs = "<leader>wm", desc = "Toggle zoom", action = notify("workbench.action.maximizeEditor") },
  { mode = "n", lhs = "<leader>uC", desc = "Select theme", action = notify("workbench.action.selectTheme") },
  { mode = "n", lhs = "<leader>tt", desc = "Select theme", action = notify("workbench.action.selectTheme") },
  { mode = "n", lhs = "<leader>ta", desc = "Toggle activity bar", action = notify("workbench.action.toggleActivityBarVisibility") },
  { mode = "n", lhs = "<leader>ts", desc = "Toggle sidebar", action = notify("workbench.action.toggleSidebarVisibility") },
  { mode = "n", lhs = "<leader>tz", desc = "Toggle Zen mode", action = notify("workbench.action.toggleZenMode") },
  { mode = "n", lhs = "<leader>tb", desc = "Toggle breakpoint", action = notify("editor.debug.action.toggleBreakpoint") },
  { mode = "n", lhs = "<leader>ur", desc = "Clear search highlights", action = function() vim.cmd("noh") end },
  { mode = "n", lhs = "<Esc>", desc = "Clear search highlights", action = function() vim.cmd("noh") end },
  { mode = "n", lhs = "<leader>qq", desc = "Quit window", action = notify("workbench.action.closeWindow") },
  { mode = "n", lhs = "<leader>ve", desc = "Focus editor", action = notify("workbench.action.focusActiveEditorGroup") },
  { mode = "n", lhs = "<leader>vl", desc = "Sidebar left", action = notify("workbench.action.moveSideBarLeft") },
  { mode = "n", lhs = "<leader>vr", desc = "Sidebar right", action = notify("workbench.action.moveSideBarRight") },
  { mode = "n", lhs = "<leader>ev", desc = "Edit vscode-nvim init", rhs = ":e ~/.config/vscode-nvim/init.lua<cr>" },
})

-- Tests (neotest keymaps → VSCode test runner)
apply({
  { mode = "n", lhs = "<leader>tn", desc = "Test nearest", action = notify("testing.runAtCursor") },
  { mode = "n", lhs = "<leader>tf", desc = "Test file", action = notify("testing.runCurrentFile") },
  { mode = "n", lhs = "<leader>td", desc = "Test debug", action = notify("testing.debugAtCursor") },
  { mode = "n", lhs = "<leader>tl", desc = "Test last", action = notify("testing.reRunLastRun") },
  { mode = "n", lhs = "<leader>tw", desc = "Test watch", action = notify("testing.toggleWatch") },
})

-- Terminal
apply({
  { mode = "n", lhs = "<leader>ft", desc = "Terminal", action = notify("workbench.action.terminal.toggleTerminal") },
  { mode = "n", lhs = "<leader>fT", desc = "Terminal", action = notify("workbench.action.terminal.toggleTerminal") },
  { mode = { "n", "t" }, lhs = "<C-/>", desc = "Terminal", action = notify("workbench.action.terminal.toggleTerminal") },
  { mode = { "n", "t" }, lhs = "<C-_>", desc = "Terminal", action = notify("workbench.action.terminal.toggleTerminal") },
})

-- Bookmarks (extension)
apply({
  { mode = "n", lhs = "<leader>m", desc = "Toggle bookmark", action = notify("bookmarks.toggle") },
  { mode = "n", lhs = "<leader>mt", desc = "Toggle bookmark", action = notify("bookmarks.toggle") },
  { mode = "n", lhs = "<leader>ml", desc = "List bookmarks", action = notify("bookmarks.list") },
  { mode = "n", lhs = "<leader>mn", desc = "Next bookmark", action = notify("bookmarks.jumpToNext") },
  { mode = "n", lhs = "<leader>mp", desc = "Prev bookmark", action = notify("bookmarks.jumpToPrevious") },
})

-- Navigation: diagnostics / changes / diffs
apply({
  { mode = "n", lhs = "]e", desc = "Next diagnostic", action = notify("editor.action.marker.next") },
  { mode = "n", lhs = "[e", desc = "Prev diagnostic", action = notify("editor.action.marker.prev") },
  { mode = "n", lhs = "]c", desc = "Next change", action = notify("workbench.action.editor.nextChange") },
  { mode = "n", lhs = "[c", desc = "Prev change", action = notify("workbench.action.editor.previousChange") },
  { mode = "n", lhs = "]d", desc = "Next diff", action = notify("workbench.action.compareEditor.nextChange") },
  { mode = "n", lhs = "[d", desc = "Prev diff", action = notify("workbench.action.compareEditor.previousChange") },
  { mode = "n", lhs = "]t", desc = "Next TODO", action = function()
    vim.fn.VSCodeNotify("workbench.action.findInFiles")
  end },
  { mode = "n", lhs = "[t", desc = "Prev TODO", action = function()
    vim.fn.VSCodeNotify("workbench.action.findInFiles")
  end },
})

-- Undo/redo via VSCode (keeps jumplist/history consistent in hybrid mode)
map("n", "u", action("undo"), { desc = "Undo", silent = true, noremap = true })
map("n", "<C-r>", action("redo"), { desc = "Redo", silent = true, noremap = true })

-- Multi-cursor (vscode-multi-cursor.nvim)
local ok_cursors, cursors = pcall(require, "vscode-multi-cursor")
if ok_cursors then
  map({ "n", "x", "i" }, "<C-n>", function()
    cursors.addSelectionToNextFindMatch()
  end, { desc = "Add cursor at next match", silent = true })
  map({ "n", "x", "i" }, "<S-C-n>", function()
    cursors.addSelectionToPreviousFindMatch()
  end, { desc = "Add cursor at prev match", silent = true })
  map({ "n", "x", "i" }, "<S-C-l>", function()
    cursors.selectHighlights()
  end, { desc = "Select all highlights", silent = true })
end

-- Flash.nvim (same bindings as ~/.config/nvim/plugins/motions/flash.lua)
local ok_flash, flash = pcall(require, "flash")
if ok_flash then
  map({ "n", "x", "o" }, "ss", function() flash.jump() end, { desc = "Flash jump" })
  map({ "n", "o" }, "sS", function() flash.treesitter() end, { desc = "Flash Treesitter" })
  map("o", "r", function() flash.remote() end, { desc = "Remote Flash" })
  map({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
  map("c", "<C-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })
end

return true
