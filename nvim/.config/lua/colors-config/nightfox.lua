require("nightfox").setup({
	options = {
		transparent = true, -- Disable setting the background color
		terminal_colors = true,
	},
})

-- setup must be called before loading
vim.cmd("colorscheme terafox")
