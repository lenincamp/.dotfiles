-- GitSigns
require("gitsigns").setup({
	signs = {
		add = {
			hl = "DiffAdd",
			text = "│",
			numhl = "GitSignsAddNr",
		},
		change = {
			hl = "DiffChange",
			text = "",
			numhl = "GitSignsChangeNr",
		},
		delete = {
			hl = "DiffDelete",
			text = "_",
			numhl = "GitSignsDeleteNr",
		},
		topdelete = {
			hl = "DiffDelete",
			text = "‾",
			numhl = "GitSignsDeleteNr",
		},
		changedelete = {
			hl = "DiffChange",
			text = "~",
			numhl = "GitSignsChangeNr",
		},
	},
	numhl = true,
	on_attach = function(bufnr)
		-- local gs = package.loaded.gitsigns
		-- require("gitsigns.defaults").setup_keymaps()

		local function map(mode, l, r, opts)
			opts = opts or {}
			-- opts.buffer = bufnr
			vim.api.nvim_buf_set_keymap(bufnr, mode, l, r, opts)
		end

		-- Navigation
		map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
		map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })

		-- Actions
		map("n", "<leader>hs", '<cmd>lua require"gitsigns".stage_hunk()<CR>', { noremap = true, silent = true })
		map("v", "<leader>hs", '<cmd>lua require"gitsigns".stage_hunk()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hr", '<cmd>lua require"gitsigns".reset_hunk()<CR>', { noremap = true, silent = true })
		map("v", "<leader>hr", '<cmd>lua require"gitsigns".reset_hunk()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hS", '<cmd>lua require"gitsigns".stage_buffer()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hu", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hR", '<cmd>lua require"gitsigns".reset_buffer()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hp", '<cmd>lua require"gitsigns".preview_hunk()<CR>', { noremap = true, silent = true })

		map(
			"n",
			"<leader>hb",
			'<cmd>lua require"gitsigns".blame_line({full = true})<CR>',
			{ noremap = true, silent = true }
		)
		map("n", ",tb", '<cmd>lua require"gitsigns".toggle_current_line_blame()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hd", '<cmd>lua require"gitsigns".diffthis()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hD", '<cmd>lua require"gitsigns".diffthis("~")<CR>', { noremap = true, silent = true })

		map("n", ",td", '<cmd>lua require"gitsigns".toggle_deleted()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hn", '<cmd>lua require"gitsigns".toggle_numhl()<CR>', { noremap = true, silent = true })
		map("n", "<leader>hh", '<cmd>lua require"gitsigns".toggle_linehl()<CR>', { noremap = true, silent = true })

		-- Text object
		map("o", "ih", ":<C-U>Gitsigns select_hunk<CR>")
		map("x", "ih", ":<C-U>Gitsigns select_hunk<CR>")
	end,
})
