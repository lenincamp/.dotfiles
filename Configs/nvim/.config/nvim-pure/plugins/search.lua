-- Snacks-based search / file / buffer / git keymaps.
-- Mirrors the <leader>s, <leader>f, <leader>b, <leader>g groups from LazyVim.

local ok, Snacks = pcall(require, "snacks")
if not ok then return end

local map = vim.keymap.set

-- ── IntelliJ-style grep layout (toggle: <leader>ug or <a-l> inside picker) ───
-- Default off. Layout "intellij_grep" is registered in snacks.lua picker.layouts.

local intellij_grep = false

local function with_layout(opts)
  if intellij_grep then
    return vim.tbl_extend("force", opts, { layout = "intellij_grep" })
  end
  return opts
end

-- Project root helper — cached per buffer (invalidated on BufEnter)
local root_cache = {}
local root_markers = { ".git", "pom.xml", "package.json", "build.gradle" }

local function root()
  local buf = vim.api.nvim_get_current_buf()
  if not root_cache[buf] then
    root_cache[buf] = vim.fs.root(buf, root_markers) or vim.fn.getcwd()
  end
  return root_cache[buf]
end

vim.api.nvim_create_autocmd("BufEnter", {
  group    = vim.api.nvim_create_augroup("root_cache", { clear = true }),
  callback = function(args) root_cache[args.buf] = nil end,
})

local function grep(opts)
  Snacks.picker.grep(with_layout(vim.tbl_extend("force", {
    cwd   = root(),
    regex = false,
  }, opts or {})))
end

local function workspace_symbols()
  local clients = vim.lsp.get_clients
      and vim.lsp.get_clients({ bufnr = 0 })
      or vim.lsp.get_active_clients({ bufnr = 0 })
  local has_workspace_symbols = false

  for _, client in ipairs(clients) do
    if client.supports_method and client:supports_method("workspace/symbol") then
      has_workspace_symbols = true
      break
    end
    if client.server_capabilities and client.server_capabilities.workspaceSymbolProvider then
      has_workspace_symbols = true
      break
    end
  end

  if not has_workspace_symbols then
    vim.notify("No LSP workspace symbols attached to this buffer", vim.log.levels.WARN)
    return
  end

  Snacks.picker.lsp_workspace_symbols({
    title = " LSP Symbols (workspace)",
    live = true,
  })
end

-- ── Explorer (<leader>e) ─────────────────────────────────────────────────────

map("n", "<leader>E",  function() Snacks.explorer({ cwd = root() }) end, { desc = "File Explorer" })
map("n", "<leader>e",  function() Snacks.explorer() end,                 { desc = "File Explorer (cwd)" })

-- ── Files (<leader>f) ─────────────────────────────────────────────────────────

map("n", "<leader><space>", function() Snacks.picker.files({ cwd = root() }) end, { desc = "Find Files (root)" })
map("n", "<leader>fF",      function() Snacks.picker.files({ cwd = root() }) end, { desc = "Find Files (root)" })
map("n", "<leader>ff",      function() Snacks.picker.files() end,                 { desc = "Find Files (cwd)" })
map("n", "<leader>fg",      function() Snacks.picker.git_files() end,             { desc = "Find Git Files" })
map("n", "<leader>fR",      function() Snacks.picker.recent() end,                { desc = "Recent Files" })
map("n", "<leader>fr",      function() Snacks.picker.recent({ filter = { cwd = true } }) end, { desc = "Recent Files (cwd)" })
map("n", "<leader>fn",      "<cmd>enew<cr>",                                       { desc = "New File" })

-- ── Filetype-specific finders ────────────────────────────────────────────────

-- <leader>fJ  — find any Java file in the project
map("n", "<leader>fJ", function()
  Snacks.picker.files({ cwd = root(), glob = { "*.java" }, title = " Java Files" })
end, { desc = "Find Java Files (root)" })

map("n", "<leader>fj", function()
  Snacks.picker.files({ cwd = root(), glob = { "*.js", "*.ts" }, title = " JavaScript/TypeScript Files" })
end, { desc = "Find JavaScript/TypeScript Files (root)" })


-- <leader>fx  — find JSX/TSX React component files
map("n", "<leader>fx", function()
  Snacks.picker.files({
    cwd   = root(),
    glob  = { "*.jsx", "*.tsx" },
    title = " React Components",
  })
end, { desc = "Find React Files (JSX/TSX) (root)" })

-- Terminal
map("n",         "<leader>ft", function() Snacks.terminal() end,                          { desc = "Terminal (cwd)" })
map("n",         "<leader>fT", function() Snacks.terminal(nil, { cwd = root() }) end,     { desc = "Terminal (root)" })
map({ "n", "t" }, "<C-/>",    function() Snacks.terminal(nil, { cwd = root() }) end,     { desc = "Terminal (root)" })
map({ "n", "t" }, "<C-_>",    function() Snacks.terminal(nil, { cwd = root() }) end,     { desc = "which_key_ignore" })

-- ── Search (<leader>s) ────────────────────────────────────────────────────────

map("n", "<leader>sb", function() Snacks.picker.buffers() end,                              { desc = "Search Buffers" })
map({ "n", "i", "x" }, "<leader>sy", function() Snacks.picker.registers() end,             { desc = "Registers / Clipboard" })
map("n", "<leader>sc", function() Snacks.picker.command_history() end,                     { desc = "Command History" })
map("n", "<leader>sC", function() Snacks.picker.commands() end,                            { desc = "Commands" })
map("n", "<leader>sd", function() Snacks.picker.diagnostics({ filter = { buf = 0 } }) end,{ desc = "Document Diagnostics" })
map("n", "<leader>sD", function() Snacks.picker.diagnostics() end,                         { desc = "Workspace Diagnostics" })
map("n", "<leader>sG", function() grep() end,                                               { desc = "Grep Literal (root)" })
map("n", "<leader>sg", function() Snacks.picker.grep(with_layout({ regex = false })) end,  { desc = "Grep Literal (cwd)" })
map("n", "<leader>s/", function() Snacks.picker.grep(with_layout({ cwd = root() })) end,   { desc = "Grep Regex (root)" })

map("n", "<leader>sj", function()
  grep({
    glob  = { "*.js", "*.ts" },
    title = " JS/TS Text",
  })
end, { desc = "Search JS/TS text (cwd)" })

map("n", "<leader>sx", function()
  grep({
    glob  = { "*.jsx", "*.tsx" },
    title = " JSX/TSX Text",
  })
end, { desc = "Search JSX/TSX text (cwd)" })

map("n", "<leader>sJ", function()
  grep({
    glob  = { "*.java" },
    title = " Java Text",
  })
end, { desc = "Search Java text (cwd)" })

map("n", "<leader>sh", function() Snacks.picker.help() end,                                { desc = "Help" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end,                             { desc = "Keymaps" })
map("n", "<leader>sl", function() Snacks.picker.loclist() end,                             { desc = "Location List" })
map("n", "<leader>sm", function() Snacks.picker.marks() end,                               { desc = "Marks" })
map("n", "<leader>sn", function() Snacks.picker.notifications() end,                       { desc = "Notifications" })
map("n", "<leader>sq", function() Snacks.picker.qflist() end,                              { desc = "Quickfix List" })
map("n", "<leader>sr", function() Snacks.picker.resume() end,                              { desc = "Resume Last Search" })
map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end,                        { desc = "LSP Symbols (doc)" })
map("n", "<leader>sS", workspace_symbols,                                                  { desc = "LSP Symbols (workspace)" })
map("n", "<leader>su", function() Snacks.picker.undo() end,                                { desc = "Undo History" })
map({ "n", "x" }, "<leader>sW", function() Snacks.picker.grep_word(with_layout({ cwd = root() })) end, { desc = "Search Word (root)" })
map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word(with_layout({})) end,               { desc = "Search Word (cwd)" })

-- ── UI toggle: grep layout (<leader>ug) ──────────────────────────────────────

Snacks.toggle({
  name = "Grep: IntelliJ Layout",
  get  = function() return intellij_grep end,
  set  = function(v) intellij_grep = v end,
}):map("<leader>ug")

-- ── Buffers (<leader>b) ───────────────────────────────────────────────────────

map("n", "<leader>bb", "<cmd>e #<cr>",                          { desc = "Switch to Other Buffer" })
map("n", "<leader>`",  "<cmd>e #<cr>",                          { desc = "Switch to Other Buffer" })
map("n", "<leader>bD", "<cmd>bd<cr>",                           { desc = "Delete Buffer and Window" })
map("n", "<leader>bd", function()
  if Snacks.bufdelete then Snacks.bufdelete() else vim.cmd("bdelete") end
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  if Snacks.bufdelete then Snacks.bufdelete.other() else
    local cur = vim.fn.bufnr()
    vim.cmd("bufdo if bufnr() != " .. cur .. " | bdelete | endif")
  end
end, { desc = "Delete Other Buffers" })

-- ── Git: snacks-powered (<leader>g) ──────────────────────────────────────────

-- Lazygit (only if installed)
if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gG", function() Snacks.lazygit({ cwd = root() }) end, { desc = "Lazygit (root)" })
  map("n", "<leader>gg", function() Snacks.lazygit() end,                  { desc = "Lazygit (cwd)" })
end

map("n", "<leader>gL", function() Snacks.picker.git_log() end,                         { desc = "Git Log (cwd)" })
map("n", "<leader>gb", function() Snacks.picker.git_log_line() end,                    { desc = "Git Blame Line" })
map("n", "<leader>gf", function() Snacks.picker.git_log_file() end,                    { desc = "Git File History" })
map("n", "<leader>gl", function() Snacks.picker.git_log({ cwd = root() }) end,         { desc = "Git Log (root)" })
map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end,                    { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
end, { desc = "Git Browse (copy URL)" })
