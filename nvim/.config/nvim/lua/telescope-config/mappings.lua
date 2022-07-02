local map = vim.api.nvim_set_keymap
--" >> Telescope bindings
--

-- Search through your Neovim related todos
map("n", "<leader>st", ":lua require'telescope-config'.search_todos()<CR>", { noremap = true, silent = true })

-- search Brave bookmarks & go
map(
	"n",
	"<space>b",
	[[<Cmd>lua require('telescope').extensions.bookmarks.bookmarks()<CR>]],
	{ noremap = true, silent = true }
)

-- open zoxide list
map(
	"n",
	"<leader>z",
	":lua require'telescope'.extensions.zoxide.list{results_title='Z Directories', prompt_title='Z Prompt'}<CR>",
	{ noremap = true, silent = true }
)

-- telescope-repo
map("n", "<leader>rl", [[<Cmd>lua require'telescope-config'.repo_list()<CR>]], { noremap = true, silent = true })

-- telescope notify history
map(
	"n",
	"<leader>nh",
	[[<Cmd>lua require('telescope').extensions.notify.notify({results_title='Notification History', prompt_title='Search Messages'})<CR>]],
	{ noremap = true, silent = true }
)

-- LSP!
-- show LSP implementations
map(
	"n",
	"<leader>ti",
	[[<Cmd>lua require'telescope.builtin'.lsp_implementations()<CR>]],
	{ noremap = true, silent = true }
)

-- show LSP definitions
map(
	"n",
	"<leader>td",
	[[<Cmd>lua require'telescope.builtin'.lsp_definitions({layout_config = { preview_width = 0.50, width = 0.92 }, path_display = { "shorten" }, results_title='Definitions'})<CR>]],
	{ noremap = true, silent = true }
)

-- show DOCUMENT Symbols
map("n", ",ws", [[<Cmd>lua require'telescope.builtin'.lsp_document_symbols()<CR>]], { noremap = true, silent = true })

-- git telescope goodness
-- git_branches
map(
	"n",
	"<space>gb",
	[[<Cmd>lua require'telescope.builtin'.git_branches({prompt_title = ' ', results_title='Git Branches'})<CR>]],
	{
		noremap = true,
		silent = true,
	}
)

-- git_bcommits - file/buffer scoped commits to vsp diff
map(
	"n",
	"<space>gc",
	[[<Cmd>lua require'telescope.builtin'.git_bcommits({prompt_title = '  ', results_title='Git File Commits'})<CR>]],
	{ noremap = true, silent = true }
)

-- git_commits (log) git log
map("n", "gl", [[<Cmd>lua require'telescope.builtin'.git_commits()<CR>]], { noremap = true, silent = true })

-- git_status - <tab> to toggle staging
map("n", "gs", [[<Cmd>lua require'telescope.builtin'.git_status()<CR>]], { noremap = true, silent = true })

-- registers picker
map("n", "<space>r", [[<Cmd>lua require'telescope.builtin'.registers()<CR>]], { noremap = true, silent = true })

-- find files with names that contain cursor word
map(
	"n",
	",f",
	[[<Cmd>lua require'telescope.builtin'.find_files({find_command={'fd', vim.fn.expand('<cword>')}})<CR>]],
	{ noremap = true, silent = true }
)

-- show Workspace Diagnostics
map("n", ",d", [[<Cmd>lua require'telescope.builtin'.diagnostics()<CR>]], { noremap = true, silent = true })

-- open available commands & run it
map(
	"n",
	",c",
	[[<Cmd>lua require'telescope.builtin'.commands({results_title='Commands Results'})<CR>]],
	{ noremap = true, silent = true }
)
-- Telescope oldfiles
map(
	"n",
	",o",
	[[<Cmd>lua require'telescope.builtin'.oldfiles({results_title='Recent-ish Files'})<CR>]],
	{ noremap = true, silent = true }
)
-- Telescopic version of FZF's :Lines
map(
	"n",
	",l",
	[[<Cmd>lua require('telescope.builtin').live_grep({grep_open_files=true})<CR>]],
	{ noremap = true, silent = true }
)

map("n", ",g", [[<Cmd>lua require'telescope.builtin'.live_grep()<CR>]], { noremap = true, silent = true })

map(
	"n",
	",bf",
	[[<Cmd>lua require'telescope.builtin'.current_buffer_fuzzy_find()<CR>]],
	{ noremap = true, silent = true }
)
map(
	"n",
	",k",
	[[<Cmd>lua require'telescope.builtin'.keymaps({results_title='Key Maps Results'})<CR>]],
	{ noremap = true, silent = true }
)

map(
	"n",
	",b",
	-- [[<Cmd>lua require'telescope.builtin'.buffers({prompt_title = '', results_title='﬘', winblend = 3, layout_strategy = 'vertical', layout_config = { width = 0.40, height = 0.55 }})<CR>]],
	[[<Cmd>lua require'telescope.builtin'.buffers({prompt_title = '', results_title='﬘', winblend = 0, layout_strategy = 'vertical', layout_config = { width = 0.40, height = 0.55 }})<CR>]],
	{ noremap = true, silent = true }
)

map(
	"n",
	",h",
	[[<Cmd>lua require'telescope.builtin'.help_tags({results_title='Help Results'})<CR>]],
	{ noremap = true, silent = true }
)

map(
	"n",
	",m",
	[[<Cmd>lua require'telescope.builtin'.marks({results_title='Marks Results'})<CR>]],
	{ noremap = true, silent = true }
)

-- find files with gitfiles & fallback on find_files
map("n", ",<space>", [[<Cmd>lua require'telescope-config'.project_files()<CR>]], { noremap = true, silent = true })

-- browse, explore and create notes
map("n", ",n", [[<Cmd>lua require'telescope-config'.browse_notes()<CR>]], { noremap = true, silent = true })

-- Explore files starting at $HOME
map("n", ",e", [[<Cmd>lua require'telescope-config'.file_explorer()<CR>]], { noremap = true, silent = true })

-- Browse files from cwd - File Browser
map(
	"n",
	",fb",
	[[<Cmd>lua require'telescope'.extensions.file_browser.file_browser()<CR>]],
	{ noremap = true, silent = true }
)
--

-- grep word under cursor
map("n", "<leader>g", [[<Cmd>lua require'telescope.builtin'.grep_string()<CR>]], { noremap = true, silent = true })
-- grep word under cursor - case-sensitive (exact word) - made for use with Replace All - see <leader>ra
map(
	"n",
	"<leader>G",
	[[<Cmd>lua require'telescope.builtin'.grep_string({word_match='-w'})<CR>]],
	{ noremap = true, silent = true }
)

-- find notes
map("n", "<leader>n", [[<Cmd>lua require'telescope-config'.find_notes()<CR>]], { noremap = true, silent = true })

-- search notes
map("n", "<space>n", [[<Cmd>lua require'telescope-config'.grep_notes()<CR>]], { noremap = true, silent = true })

-- Find files in config dirs
map("n", "<space>e", [[<Cmd>lua require'telescope-config'.find_configs()<CR>]], { noremap = true, silent = true })

-- greg for a string
map("n", "<space>g", [[<Cmd>lua require'telescope-config'.grep_prompt()<CR>]], { noremap = true, silent = true })
-- find or create neovim configs
map("n", "<leader>nc", [[<Cmd>lua require'telescope-config'.nvim_config()<CR>]], { noremap = true, silent = true })

-- Github issues
map("n", "<leader>is", [[<Cmd>lua require'telescope-config'.gh_issues()<CR>]], { noremap = true, silent = true })
-- github Pull Requests - PRs
map("n", "<leader>pr", [[<Cmd>lua require'telescope-config'.gh_prs()<CR>]], { noremap = true, silent = true })

-- neoclip
map("n", ",nc", [[<Cmd>lua require('telescope').extensions.neoclip.default()<CR>]], {
	noremap = true,
	silent = true,
})

-- grep the Neovim source code with word under cursor → cword - just z to Neovim source for other actions
map("n", "<leader>ns", [[<Cmd>lua require'telescope-config'.grep_nvim_src()<CR>]], { noremap = true, silent = true })
-- End Telescope maps

map("n", "<Leader>pp", ":lua require'telescope.builtin'.builtin{}<CR>", { noremap = true, silent = true })

--" pick color scheme
map("n", ",cs", ":lua require'telescope.builtin'.colorscheme{}<CR>", { noremap = true, silent = true })

map("n", ",lr", ":lua require'telescope.builtin'.lsp_references{}<CR>", { noremap = true, silent = true })
map("n", ",ltd", ":lua require'telescope.builtin'.lsp_type_definitions{}<CR>", { noremap = true, silent = true })

map("n", ",t", ":lua require'telescope.builtin'.treesitter{}<CR>", { noremap = true, silent = true })
map("n", ",ch", ":lua require 'telescope.builtin'.command_history()<CR>", { noremap = true, silent = true })

--" show helps
